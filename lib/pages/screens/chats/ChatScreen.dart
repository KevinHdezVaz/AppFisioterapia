import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/login_page.dart';
import 'package:user_auth_crudd10/auth/register_page.dart'; 
import 'package:user_auth_crudd10/services/storage_service.dart';

class ChatScreen extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final String inputMode;

  const ChatScreen({
    Key? key,
    required this.messages,
    required this.inputMode,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late List<Map<String, dynamic>> _messages;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLocked = false;
  String _transcribedText = '';
  double _dragPosition = 0.0;
  final double _lockThreshold = -100.0;
  final _authService = AuthService();
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.messages);
    _speech = stt.SpeechToText();
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _storageService.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error verificando sesión: $e');
      return false;
    }
  }

  Future<void> _handleSendMessage(String message) async {
    bool loggedIn = await isLoggedIn();
    if (loggedIn) {
      _sendMessage(message);
    } else {
      showDialog(
        context: context,
        builder: (context) => LoginModal(
          showRegisterPage: () {
            showDialog(
              context: context,
              builder: (context) => RegisterModal(
                showLoginPage: () {
                  Navigator.pop(context); // Close RegisterModal
                  showDialog(
                    context: context,
                    builder: (context) => LoginModal(
                      showRegisterPage: () {
                        Navigator.pop(context); // Close LoginModal
                        showDialog(
                          context: context,
                          builder: (context) => RegisterModal(
                            showLoginPage: () {}, // Recursive loop prevention
                            inputMode: widget.inputMode,
                          ),
                        );
                      },
                      inputMode: widget.inputMode,
                    ),
                  );
                },
                inputMode: widget.inputMode,
              ),
            );
          },
          inputMode: widget.inputMode,
        ),
      );
    }
  }

  Future<void> _handleStartListening() async {
    bool loggedIn = await isLoggedIn();
    if (loggedIn) {
      _startListening();
    } else {
      showDialog(
        context: context,
        builder: (context) => LoginModal(
          showRegisterPage: () {
            showDialog(
              context: context,
              builder: (context) => RegisterModal(
                showLoginPage: () {
                  Navigator.pop(context); // Close RegisterModal
                  showDialog(
                    context: context,
                    builder: (context) => LoginModal(
                      showRegisterPage: () {
                        Navigator.pop(context); // Close LoginModal
                        showDialog(
                          context: context,
                          builder: (context) => RegisterModal(
                            showLoginPage: () {}, // Recursive loop prevention
                            inputMode: widget.inputMode,
                          ),
                        );
                      },
                      inputMode: widget.inputMode,
                    ),
                  );
                },
                inputMode: widget.inputMode,
              ),
            );
          },
          inputMode: widget.inputMode,
        ),
      );
    }
  }

  void _sendMessage(String message, {bool isSent = true}) {
    if (message.trim().isNotEmpty) {
      setState(() {
        _messages.insert(0, {'text': message, 'isSent': isSent});
      });
      _controller.clear();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
            _isLocked = false;
            _dragPosition = 0.0;
          });
          if (_transcribedText.trim().isNotEmpty) {
            _sendMessage(_transcribedText);
            _transcribedText = '';
          }
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el reconocimiento de voz: $error')),
        );
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
        },
        localeId: 'es_ES',
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _isLocked = false;
      _dragPosition = 0.0;
    });
    if (_transcribedText.trim().isNotEmpty) {
      _sendMessage(_transcribedText);
      _transcribedText = '';
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (details.delta.dx < 0) {
        _dragPosition += details.delta.dx;
        if (_dragPosition < _lockThreshold) {
          _dragPosition = _lockThreshold;
          if (!_isLocked) {
            _isLocked = true;
          }
        }
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isLocked) {
      _stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFC7ECEB),
      body: Stack(
        children: [
          Positioned(
            top: 40,
            right: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
              child: Column(
                children: [
                  const Text(
                    'Estoy contigo... puedes hablar cuando quieras',
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isSent = msg['isSent'] as bool;
                        final text = msg['text'] as String;
                        return TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 700),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeOut,
                          builder: (context, double opacity, child) {
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(0, (1 - opacity) * 20),
                                child: child,
                              ),
                            );
                          },
                          child: Align(
                            alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(maxWidth: size.width * 0.7),
                              decoration: BoxDecoration(
                                color: isSent
                                    ? Colors.amber.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isSent ? const Radius.circular(16) : const Radius.circular(0),
                                  bottomRight: isSent ? const Radius.circular(0) : const Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  widget.inputMode == 'keyboard'
                      ? _buildKeyboardInput()
                      : _buildMicrophoneInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Escribe aquí...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              style: const TextStyle(color: Colors.black87),
              onSubmitted: (value) => _handleSendMessage(value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black54),
            onPressed: () => _handleSendMessage(_controller.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneInput() {
    return SizedBox(
      height: 80,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (_isListening && !_isLocked)
            Positioned(
              left: _lockThreshold + 30,
              child: AnimatedOpacity(
                opacity: _isListening ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      curve: Curves.easeInOut,
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(-10 * value, 0),
                          child: Opacity(
                            opacity: 1.0 - value,
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 5),
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      curve: Curves.easeInOut,
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(-10 * value, 0),
                          child: Opacity(
                            opacity: 1.0 - value,
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_isLocked)
            Center(
              child: GestureDetector(
                onTap: _stopListening,
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 1.0, end: 1.2),
                  curve: Curves.easeInOut,
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stop, size: 30, color: Colors.white),
                  ),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: _isListening && !_isLocked
                ? (MediaQuery.of(context).size.width / 2 - 30) + _dragPosition
                : MediaQuery.of(context).size.width / 2 - 30,
            child: GestureDetector(
              onPanUpdate: _isLocked ? null : _handleDragUpdate,
              onPanEnd: _isLocked ? null : _handleDragEnd,
              onTapDown: _isLocked ? null : (_) => _handleStartListening(),
              child: TweenAnimationBuilder(
                duration: const Duration(seconds: 2),
                tween: Tween<double>(begin: 1.0, end: _isListening ? 1.2 : 1.15),
                curve: Curves.easeInOut,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isLocked ? Icons.lock : (_isListening ? Icons.mic : Icons.mic_none),
                    size: 30,
                    color: _isListening ? Colors.red : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}