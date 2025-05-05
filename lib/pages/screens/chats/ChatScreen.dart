import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/login_page.dart';
import 'package:user_auth_crudd10/auth/register_page.dart';
import 'package:user_auth_crudd10/model/ChatMessage.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/services/ChatServiceApi.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'dart:math';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String inputMode;
  final List<ChatMessage>? initialMessages; // Solo para chats guardados
  final int? sessionId; // Opcional, solo para chats guardados

  const ChatScreen({
    Key? key,
    required this.inputMode,
    this.initialMessages,
    this.sessionId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';
  bool _isTyping = false;
  int _typingIndex = 0;
  late Timer _typingTimer;
  bool _isSpeechInitialized = false;

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ChatServiceApi _chatService = ChatServiceApi();

  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();

    // Inicializar mensajes si viene de un chat guardado
    _messages = widget.initialMessages?.reversed.toList() ?? [];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 90, end: 110).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _speech = stt.SpeechToText();
    _typingTimer = Timer.periodic(Duration.zero, (_) {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _speech.cancel();
    _controller.dispose();
    if (_typingTimer.isActive) {
      _typingTimer.cancel();
    }
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

    try {
      final response = await _chatService.sendMessage(message);

      if (!mounted) return;

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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _typingTimer.cancel();
      });
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFF4BB6A8),
        // En el AppBar del ChatScreen:
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
          actions: [
            // Mostrar siempre el botón de guardar
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: TextButton.icon(
                icon: Icon(Icons.save, color: Colors.white, size: 22),
                label: Text('Guardar',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
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
            Positioned.fill(child: _FloatingParticles()),
            Positioned(
              top: 50,
              right: 50,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: _pulseAnimation.value,
                    height: _pulseAnimation.value,
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
            ),
            Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Estoy contigo...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.95),
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
                      color: Colors.white.withOpacity(0.85),
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Lora',
                    ),
                  ),
                  SizedBox(height: 30),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount:
                          _isTyping ? _messages.length + 1 : _messages.length,
                      itemBuilder: (context, index) {
                        if (_isTyping && index == 0) {
                          return _buildTypingIndicator();
                        }
                        final messageIndex = _isTyping ? index - 1 : index;
                        return _buildMessageBubble(_messages[messageIndex]);
                      },
                    ),
                  ),
                  if (widget.inputMode == 'keyboard')
                    _buildKeyboardInput()
                  else
                    _buildVoiceInput(),
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Color(0xFF4BB6A8),
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
              icon: Icon(Icons.send, color: Color(0xFF4BB6A8)),
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
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening
                  ? 1.1 + (_pulseAnimation.value - 90) * 0.005
                  : 1.0,
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
            );
          },
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
        return CustomPaint(
          painter: _ParticlesPainter(_particles, _controller.value),
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
