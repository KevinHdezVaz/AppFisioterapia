import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:LumorahAI/auth/auth_service.dart';
import 'package:LumorahAI/auth/login_page.dart';
import 'package:LumorahAI/auth/register_page.dart';
import 'package:LumorahAI/model/ChatMessage.dart';
import 'package:LumorahAI/pages/MenuPrincipal.dart';
import 'package:LumorahAI/services/ChatServiceApi.dart';
import 'package:LumorahAI/services/storage_service.dart';
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

  // Color palette
  final Color tiffanyColor = Color(0xFF88D5C2);
  final Color ivoryColor = Color(0xFFFDF8F2);
  final Color micButtonColor = Color(0xFF4ECDC4);

  List<ChatMessage> _messages = [];
  bool _isNewSession = false;
  String? _emotionalState;
  String? _conversationLevel;

  @override
  void initState() {
    super.initState();

    _messages = widget.initialMessages?.reversed.toList() ?? [];
    _isNewSession = widget.sessionId == null;

    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _sunAnimation = Tween<double>(begin: 90.0, end: 110.0).animate(
      CurvedAnimation(parent: _sunController, curve: Curves.easeInOut),
    );

    _speech = stt.SpeechToText();
    _typingTimer = Timer.periodic(Duration.zero, (_) {});

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    } else if (_isNewSession && _messages.isEmpty) {
      _startNewSession();
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

  Future<void> _startNewSession() async {
    try {
      final response = await _chatService.startNewSession();
      
      if (!mounted) return;
      
      final welcomeMessage = ChatMessage(
        id: -1,
        chatSessionId: widget.sessionId ?? -1,
        userId: 0,
        text: response['ai_message']['text'],
        isUser: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        emotionalState: response['ai_message']['emotional_state'],
        conversationLevel: response['ai_message']['conversation_level'],
      );

      setState(() {
        _messages.insert(0, welcomeMessage);
        _emotionalState = response['ai_message']['emotional_state'];
        _conversationLevel = response['ai_message']['conversation_level'];
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al iniciar sesión: $e');
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
      chatSessionId: widget.sessionId ?? -1,
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

    await _playThinkingSound();

    try {
      final response = await _chatService.sendMessage(
        message: message,
        sessionId: widget.sessionId,
        isTemporary: false,
      );

      if (!mounted) {
        await _stopThinkingSound();
        return;
      }

      final aiMessage = ChatMessage(
        id: -1,
        chatSessionId: widget.sessionId ?? -1,
        userId: 0,
        text: response['ai_message']['text'],
        isUser: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        emotionalState: response['ai_message']['emotional_state'],
        conversationLevel: response['ai_message']['conversation_level'],
      );

      setState(() {
        _messages.insert(0, aiMessage);
        _isTyping = false;
        _emotionalState = response['ai_message']['emotional_state'];
        _conversationLevel = response['ai_message']['conversation_level'];
        _typingTimer.cancel();
      });
      
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
        title: Text('Guardar conversación', style: TextStyle(color: Colors.black)),
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
          if (!message.isUser && message.emotionalState != null)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '${_getEmotionalStateText(message.emotionalState)} • ${_getConversationLevelText(message.conversationLevel)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getEmotionalStateText(String? state) {
    switch (state) {
      case 'sensitive':
        return '💙 Sensible';
      case 'crisis':
        return '⚠️ Necesita apoyo';
      default:
        return '😊 Neutral';
    }
  }

  String _getConversationLevelText(String? level) {
    switch (level) {
      case 'advanced':
        return 'Nivel: Avanzado';
      default:
        return 'Nivel: Básico';
    }
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

  Widget _buildInput() {
    switch (widget.inputMode) {
      case 'keyboard':
        return _buildKeyboardInput();
      case 'voice':
        return _buildVoiceInput();
      default:
        return _buildKeyboardInput();
    }
  }

  void _navigateBack(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            Menuprincipal(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
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

Widget _buildKeyboardInput() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: TextField(
      controller: _controller,
      style: TextStyle(color: Colors.black87),
      minLines: 1,
      maxLines: 6, // Esto permite que crezca verticalmente
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: tiffanyColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => _navigateBack(context),
          ),
          actions: [
            if (!_isNewSession)
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: TextButton.icon(
                  icon: Icon(Icons.save, color: Colors.black, size: 22),
                  label: Text(
                    'Guardar',
                    style: TextStyle(color: Colors.black, fontSize: 14),
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
            Positioned.fill(child: _FloatingParticles()),
            _buildAnimatedCircle(),
            Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 20),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 30),
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
                  _buildInput(),
                ],
              ),
            ),
          ],
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