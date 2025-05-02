import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:user_auth_crudd10/model/ChatMessage.dart';
import 'package:user_auth_crudd10/services/ChatServiceApi.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/ParticleUtils.dart';
import 'package:user_auth_crudd10/utils/TypingIndicator.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class ChatScreen extends StatefulWidget {
  final int? sessionId;
  const ChatScreen({Key? key, this.sessionId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final ChatServiceApi _chatService = ChatServiceApi();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;
  bool _isKeyboardVisible = false;
  bool _isLoading = false;
  bool _isSending = false;
  List<ChatMessage> _messages = [];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.sessionId != null) {
      _fetchMessages();
    }
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messagesJson =
          await _chatService.getSessionMessages(widget.sessionId!);
      setState(() {
        _messages =
            messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      });
      _scrollToBottom();
    } catch (e) {
      _showError('Error al cargar los mensajes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Error al seleccionar la imagen: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImage == null)
      return;

    final message = _messageController.text.isNotEmpty
        ? _messageController.text
        : 'Imagen enviada';
    setState(() {
      _messages.add(ChatMessage(
        id: 0,
        chatSessionId: widget.sessionId ?? 0,
        userId: 0,
        text: message,
        isUser: true,
        imageUrl: _selectedImage?.path,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _messageController.clear();
      _selectedImage = null;
      _isSending = true;
    });

    try {
      final response =
          await _chatService.sendMessage(message, sessionId: widget.sessionId);
      setState(() {
        _messages.add(ChatMessage(
          id: response['ai_message']['id'] as int,
          chatSessionId: response['ai_message']['chat_session_id'] as int,
          userId: response['ai_message']['user_id'] as int,
          text: response['ai_message']['text'] as String,
          isUser: false,
          imageUrl: 'https://via.placeholder.com/150',
          createdAt:
              DateTime.parse(response['ai_message']['created_at'] as String),
          updatedAt:
              DateTime.parse(response['ai_message']['updated_at'] as String),
        ));
      });
      _scrollToBottom();
    } catch (e) {
      _showError('Error al enviar el mensaje: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _speech.stop();
      setState(() => _isRecording = false);
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isRecording = true);
        _speech.listen(onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
        });
      } else {
        _showError('No se puede acceder al micrófono');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    double screenHeight = size.height;
    double screenWidth = size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Particles(
                      awayRadius: 150,
                      particles: ParticleUtils.createParticles(
                        numberOfParticles: 70,
                        color: LumorahColors.primary,
                        maxSize: 4.0,
                        maxVelocity: 20.0,
                      ),
                      height: size.height,
                      width: size.width,
                      onTapAnimation: true,
                      awayAnimationDuration: const Duration(milliseconds: 600),
                      awayAnimationCurve: Curves.easeIn,
                      enableHover: true,
                      hoverRadius: 50,
                      connectDots: false,
                    ),
                  ),
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length +
                        (_isSending ? 1 : 0), // +1 si está enviando
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        // Mostrar el indicador de "escribiendo" como último mensaje
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            LumorahColors.primary),
                      ),
                    ),
                  if (_isSending)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: LumorahColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                LumorahColors.primary),
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) // Animación para la IA (lado izquierdo)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Lottie.asset(
                  'assets/images/circuloIA.json',
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? LumorahColors.primary
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(message.isUser ? 16 : 4),
                      topRight: Radius.circular(message.isUser ? 4 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (message.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: message.imageUrl!.startsWith('http')
                          ? Image.network(
                              message.imageUrl!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error,
                                    color: Colors.red);
                              },
                            )
                          : Image.file(
                              File(message.imageUrl!),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error,
                                    color: Colors.red);
                              },
                            ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) // Animación para el usuario (lado derecho)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Lottie.asset(
                  'assets/images/user.json',
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Lottie.asset(
                'assets/images/circuloIA.json',
                repeat: true,
                animate: true,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child:
                const TypingIndicator(), // Usamos nuestro widget personalizado
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.image,
                  color: LumorahColors.primary,
                ),
                onPressed: _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintStyle: const TextStyle(
                        color:
                            Colors.black), // Negro con un poco de transparencia

                    hintText: 'Escribe un mensaje...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onTap: () => setState(() => _isKeyboardVisible = true),
                ),
              ),
              const SizedBox(width: 4),
              // Botón de enviar
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: LumorahColors.primary,
                ),
                onPressed: _sendMessage,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onLongPress: _toggleRecording,
                onLongPressUp: _toggleRecording,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : LumorahColors.primary,
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
