import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/login_page.dart';
import 'package:user_auth_crudd10/auth/register_page.dart';
import 'package:user_auth_crudd10/model/ChatMessage.dart';
import 'package:user_auth_crudd10/pages/MenuPrincipal.dart';
import 'package:user_auth_crudd10/services/ChatServiceApi.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String inputMode;
  final List<ChatMessage>? initialMessages;
  final int? sessionId;
  final String? initialMessage;

  const ChatScreen({
    Key? key,
    required this.inputMode,
    this.initialMessages,
    this.sessionId,
    this.initialMessage,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';
  bool _isTyping = false;
  int _typingIndex = 0;
  late Timer _typingTimer;
  bool _isSpeechInitialized = false;
  late AnimationController _sunController;
  late Animation<double> _sunAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ChatServiceApi _chatService = ChatServiceApi();

  // Color palette (alineada con Menuprincipal.dart)
  final Color tiffanyColor = Color(0xFF88D5C2);
  final Color ivoryColor = Color(0xFFFDF8F2);
  final Color micButtonColor = Color(0xFF4ECDC4);

  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();

    // Inicializar mensajes si viene de un chat guardado
    _messages = widget.initialMessages?.reversed.toList() ?? [];

    // Animación para el círculo superior
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _sunAnimation = Tween<double>(begin: 90.0, end: 110.0).animate(
      CurvedAnimation(parent: _sunController, curve: Curves.easeInOut),
    );

    _speech = stt.SpeechToText();
    _typingTimer = Timer.periodic(Duration.zero, (_) {});

    // Enviar el mensaje inicial si existe
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _controller.dispose();
    if (_typingTimer.isActive) {
      _typingTimer.cancel();
    }
    _sunController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<bool> _isUserAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  void _showAuthModal() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => LoginModal(
        showRegisterPage: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => RegisterModal(
              showLoginPage: () {
                Navigator.pop(context);
                _showAuthModal();
              },
              inputMode: widget.inputMode,
            ),
          );
        },
        inputMode: widget.inputMode,
      ),
    );
  }

  Future<void> _playThinkingSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/pensandoIA.mp3'));
      // Configurar el sonido en bucle mientras _isTyping es true
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al reproducir el sonido: $e');
      }
    }
  }

  Future<void> _stopThinkingSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al detener el sonido: $e');
      }
    }
  }

  Future<void> _sendMessage(String message) async {
    if (!await _isUserAuthenticated()) {
      if (!mounted) return;
      _showAuthModal();
      return;
    }

    if (message.trim().isEmpty) return;

    final currentUser = await _storageService.getUser();
    final newMessage = ChatMessage(
      id: -1,
      chatSessionId: -1,
      userId: currentUser?.id ?? -1,
      text: message,
      isUser: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, newMessage);
      _isTyping = true;
      _typingIndex = 0;
      _typingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
        if (mounted) setState(() => _typingIndex = (_typingIndex + 1) % 3);
      });
    });
    _controller.clear();

    // Reproducir sonido de "pensando"
    await _playThinkingSound();

    try {
      final response = await _chatService.sendMessage(message);

      if (!mounted) {
        await _stopThinkingSound();
        return;
      }

      final aiMessage = ChatMessage(
        id: -1,
        chatSessionId: -1,
        userId: 0,
        text: response['ai_message']?['text'] ?? "No se recibió respuesta",
        isUser: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, aiMessage);
        _isTyping = false;
        _typingTimer.cancel();
      });
      // Detener sonido después de recibir la respuesta
      await _stopThinkingSound();
    } catch (e) {
      if (!mounted) {
        await _stopThinkingSound();
        return;
      }
      setState(() {
        _isTyping = false;
        _typingTimer.cancel();
      });
      // Detener sonido en caso de error
      await _stopThinkingSound();
      _showErrorSnackBar('Error al enviar mensaje: $e');
    }
  }

  Future<void> _saveChat() async {
    if (!await _isUserAuthenticated()) {
      if (!mounted) return;
      _showAuthModal();
      return;
    }

    if (_messages.isEmpty) {
      _showErrorSnackBar('No hay mensajes para guardar');
      return;
    }

    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Guardar conversación', style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: 'Título',
            hintText: 'Ej: Conversación sobre ansiedad',
            hintStyle: TextStyle(color: Colors.black),
            filled: true,
            fillColor: Color(0xFFF6F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(0xFF4BB6A8),
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4BB6A8)),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context, titleController.text.trim());
              }
            },
            child: Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    try {
      await _chatService.saveChatSession(
        title: title,
        messages: _messages.reversed
            .map((m) => {
                  'text': m.text,
                  'is_user': m.isUser,
                  'created_at': m.createdAt.toIso8601String(),
                })
            .toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversación guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error al guardar: $e');
    }
  }

  Future<void> _startListening() async {
    if (!await _isUserAuthenticated()) {
      if (!mounted) return;
      _showAuthModal();
      return;
    }

    if (_isListening) {
      print('Reconocimiento de voz ya está activo, ignorando nueva solicitud.');
      return;
    }

    bool available = _isSpeechInitialized;
    if (!_isSpeechInitialized) {
      available = await _speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (error) => print('Error: $error'),
      );
      if (available) {
        _isSpeechInitialized = true;
      }
    }

    if (!mounted) return;

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() => _transcribedText = result.recognizedWords);
          }
        },
        localeId: 'es_ES',
      );
    } else {
      _showErrorSnackBar('No se pudo inicializar el reconocimiento de voz.');
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      _speech.cancel();
    }

    if (!mounted) return;

    setState(() {
      _isListening = false;
      if (_transcribedText.isNotEmpty) {
        _sendMessage(_transcribedText);
        _transcribedText = '';
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final time =
        "${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            clipper: ChatBubbleClipper1(
              type: message.isUser
                  ? BubbleType.sendBubble
                  : BubbleType.receiverBubble,
            ),
            alignment: message.isUser ? Alignment.topRight : Alignment.topLeft,
            margin: EdgeInsets.only(top: 5),
            backGroundColor: message.isUser
                ? Color(0xFFFFE0B2).withOpacity(0.9)
                : Colors.white.withOpacity(0.8),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Lora',
                      fontSize: 12,
                    ),
                  ),
                  if (message.imageUrl != null)
                    Image.network(message.imageUrl!),
                  SizedBox(height: 5),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ChatBubble(
        clipper: ChatBubbleClipper1(type: BubbleType.receiverBubble),
        alignment: Alignment.topLeft,
        margin: EdgeInsets.only(top: 5),
        backGroundColor: Colors.white.withOpacity(0.8),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _typingIndex ? Colors.blue : Colors.grey,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Widget para el encabezado con los textos
  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Estoy contigo...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.95),
              fontFamily: 'Lora',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'puedes hablar cuando quieras',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black.withOpacity(0.85),
            fontStyle: FontStyle.italic,
            fontFamily: 'Lora',
          ),
        ),
      ],
    );
  }

  // Widget que construye el círculo animado
  Widget _buildAnimatedCircle() {
    return Positioned(
      top: 50,
      right: 50,
      child: AnimatedBuilder(
        animation: _sunAnimation,
        builder: (context, child) {
          return Container(
            width: _sunAnimation.value,
            height: _sunAnimation.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFFE5B4).withOpacity(0.7),
                  Color(0xFFFFE5B4).withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFFF3E0).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Método para renderizar el input según el modo
  Widget _buildInput() {
    switch (widget.inputMode) {
      case 'keyboard':
        return _buildKeyboardInput();
      case 'voice':
        return _buildVoiceInput();
      default:
        return _buildKeyboardInput(); // Por defecto, usar teclado
    }
  }

  // Método para navegar de vuelta a Menuprincipal con animación
  void _navigateBack(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            Menuprincipal(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0); // Deslizar desde la izquierda
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var slideAnimation = animation.drive(tween);

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack(context); // Usar navegación animada
        return false;
      },
      child: Scaffold(
        backgroundColor: tiffanyColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => _navigateBack(context), // Usar navegación animada
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: TextButton.icon(
                icon: Icon(Icons.save, color: Colors.blue, size: 22),
                label: Text(
                  'Guardar',
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
                onPressed: _saveChat,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Fondo de partículas flotantes
            Positioned.fill(child: _FloatingParticles()),
            // Círculo animado en la parte superior
            _buildAnimatedCircle(),
            // Contenido principal
            Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 20),
              child: Column(
                children: [
                  // Encabezado con textos
                  _buildHeader(),
                  SizedBox(height: 30),
                  // Lista de mensajes
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == 0) {
                          return _buildTypingIndicator();
                        }
                        final messageIndex = _isTyping ? index - 1 : index;
                        return _buildMessageBubble(_messages[messageIndex]);
                      },
                    ),
                  ),
                  // Input (teclado o voz)
                  _buildInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _controller,
        style: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Escribe lo que quieras...',
          hintStyle: TextStyle(color: Colors.grey),
          filled: true,
          fillColor: ivoryColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: micButtonColor,
                ),
                onPressed: () async {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    if (await _isUserAuthenticated()) {
                      _startListening();
                    } else {
                      if (!mounted) return;
                      _showAuthModal();
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.send, color: micButtonColor),
                onPressed: () async {
                  if (await _isUserAuthenticated()) {
                    _sendMessage(_controller.text);
                  } else {
                    if (!mounted) return;
                    _showAuthModal();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceInput() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          if (_isListening) {
            _stopListening();
          } else {
            if (await _isUserAuthenticated()) {
              _startListening();
            } else {
              if (!mounted) return;
              _showAuthModal();
            }
          }
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isListening
                ? Colors.red.withOpacity(0.7)
                : Colors.white.withOpacity(0.7),
            boxShadow: [
              BoxShadow(
                color: _isListening
                    ? Colors.red.withOpacity(0.4)
                    : Colors.white.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            size: 30,
            color: _isListening ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _FloatingParticles extends StatefulWidget {
  @override
  __FloatingParticlesState createState() => __FloatingParticlesState();
}

class __FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 30),
    )..repeat();

    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.2 + 0.1,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: _ParticlesPainter(_particles, _controller.value),
          ),
        );
      },
    );
  }
}

class Particle {
  double x, y, size, speed;
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double time;

  _ParticlesPainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final x = (particle.x + time * particle.speed) % 1.0 * size.width;
      final y = (particle.y + time * particle.speed * 0.5) % 1.0 * size.height;
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
