import 'dart:async';
import 'dart:io';
import 'package:LumorahAI/auth/auth_service.dart';
import 'package:LumorahAI/auth/login_page.dart';
import 'package:LumorahAI/auth/register_page.dart';
import 'package:LumorahAI/model/ChatMessage.dart';
import 'package:LumorahAI/pages/screens/chats/ConversationState.dart';
import 'package:LumorahAI/pages/screens/chats/RecordingScreen.dart';
import 'package:LumorahAI/services/ChatServiceApi.dart';
import 'package:LumorahAI/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:easy_localization/easy_localization.dart';

class VoiceChatScreen extends StatefulWidget {
  final String language;

  const VoiceChatScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  late FlutterTts _flutterTts;
  late ConversationState _conversationState;
  late ChatServiceApi _chatService;
  late PusherChannelsFlutter _pusher;
  late stt.SpeechToText _speech;
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
 
  String _statusMessage = '';
  final Color _primaryColor = const Color.fromARGB(255, 255, 255, 255);
  final Color _backgroundColor = const Color(0xFF88D5C2);
  bool _isLoading = true;
  bool _showMicButton = false;
  bool _isSaved = false; // Track if chat is saved
  int? _currentSessionId; // Store session ID
     Color ivoryColor = Color(0xFFFDF8F2);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });

    _flutterTts = FlutterTts();
    _conversationState = ConversationState();
    _chatService = ChatServiceApi();
    _speech = stt.SpeechToText();

    await _initTts();
    await _initializePusher();
    await _requestPermissions();
    await _checkSupportedLocales();

    setState(() {
      _isLoading = false;
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showMicButton = true;
          });
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToRecordingScreen();
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(widget.language);
    if (Platform.isIOS) {
      await _flutterTts.setSpeechRate(0.3);
    } else {
      await _flutterTts.setSpeechRate(0.5);
    }
  }

  Future<void> _requestPermissions() async {
    var microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus != PermissionStatus.granted) {
      _showError(
          'Permiso de micrófono denegado. Por favor, habilítalo en la configuración.');
    }
  }

  Future<void> _checkSupportedLocales() async {
    List<stt.LocaleName> locales = await _speech.locales();
    for (var locale in locales) {
      debugPrint('Locale soportado: ${locale.localeId} - ${locale.name}');
    }
  }

  Future<void> _initializePusher() async {
    _pusher = PusherChannelsFlutter.getInstance();
    try {
      await _pusher.init(
        apiKey: 'cea9e98e57befa889239',
        cluster: 'us2',
        onEvent: (event) {
          final data = event.data;
          setState(() {
            switch (event.eventName) {
              case 'ai_response':
                final aiResponse = data['text'];
                _conversationState.setCurrentMessage(aiResponse);
                _handleAIResponse({
                  'ai_message': {
                    'text': aiResponse,
                    'emotional_state': data['emotional_state'] ?? 'neutral',
                    'conversation_level': data['conversation_level'] ?? 'basic',
                  },
                  'session_id':
                      data['session_id'], // Capture session ID if provided
                });
                _statusMessage = 'Respuesta recibida';
                break;
              case 'error':
                _showError(data['message']);
                _statusMessage = 'Error: ${data['message']}';
                break;
            }
          });
        },
      );
      await _pusher.subscribe(channelName: 'lumorah');
      await _pusher.connect();
    } catch (e) {
      _showError('Error al conectar con Pusher: ${e.toString()}');
    }
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
              inputMode: 'voice',
            ),
          );
        },
        inputMode: 'voice',
      ),
    );
  }

  Future<void> _saveChat() async {
    if (!await _isUserAuthenticated()) {
      if (!mounted) return;
      _showAuthModal();
      return;
    }

    if (_conversationState.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay mensajes para guardar'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Guardar conversación'.tr(),
            style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: 'Título'.tr(),
            hintText: 'Ejemplo: Conversación 1'.tr(),
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Color(0xFFF6F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF4BB6A8), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'.tr(), style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4BB6A8)),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context, titleController.text.trim());
              }
            },
            child: Text('Guardar'.tr(), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    try {
      final session = await _chatService.saveChatSession(
        title: title,
        messages: _conversationState.messages.reversed
            .map((m) => {
                  'text': m.text,
                  'is_user': m.isUser,
                  'created_at': m.createdAt.toIso8601String(),
                })
            .toList(),
        sessionId: _currentSessionId,
      );

      if (!mounted) return;

      setState(() {
        _isSaved = true;
        _currentSessionId = session.id;
        _statusMessage = 'Chat guardado exitosamente';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat guardado exitosamente'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el chat: $e'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToRecordingScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingScreen(
          language: widget.language,
          chatService: _chatService,
        ),
      ),
    );

    if (result != null &&
        result['transcription'] != null &&
        result['ai_response'] != null) {
      setState(() {
        _conversationState.addUserMessage(
          result['transcription'],
          emotionalState: 'neutral',
        );
        _conversationState.addAiMessage(
          result['ai_response'],
          emotionalState: result['emotional_state'] ?? 'neutral',
          conversationLevel: result['conversation_level'] ?? 'basic',
        );
        _currentSessionId =
            result['session_id']; // Update session ID if provided
        _statusMessage = 'Conversación actualizada';
      });
    }
  }

  void _handleAIResponse(Map<String, dynamic> response) {
    _conversationState.addAiMessage(
      response['ai_message']['text'],
      emotionalState: response['ai_message']['emotional_state'],
      conversationLevel: response['ai_message']['conversation_level'],
    );
    if (response['session_id'] != null) {
      setState(() {
        _currentSessionId = response['session_id'];
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      _statusMessage = 'Error: $message. Toca para reintentar';
    });
  }

  void _startNewSession() {
    _conversationState.clearConversation();
    setState(() {
      _statusMessage = 'Nueva conversación iniciada';
      _isSaved = false; // Reset save state for new session
      _currentSessionId = null; // Reset session ID
    });
    _navigateToRecordingScreen();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final emotionColor = _getEmotionColor(message.emotionalState);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? _primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: emotionColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUser ? Icons.person : Icons.auto_awesome,
                color: isUser ? _primaryColor : Colors.black,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isUser ? 'Tú' : 'Lumorah',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUser ? _primaryColor : Colors.black,
                ),
              ),
              if (message.emotionalState != null) ...[
                const Spacer(),
                //    _buildEmotionIndicator(message.emotionalState!),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEmotionColor(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy':
        return Colors.yellow;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'excited':
        return Colors.orange;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmotionIndicator(String emotion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getEmotionColor(emotion).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        emotion,
        style: TextStyle(
          fontSize: 12,
          color: _getEmotionColor(emotion),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    _pusher.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chat de voz',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isSaved)
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: TextButton.icon(
                icon: Icon(Icons.save, color: Colors.white, size: 22),
                label: Text(
                  'Guardar'.tr(),
                  style: TextStyle(color: Colors.white, fontSize: 14),
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
      body: _isLoading
          ?   Center(
  child: CircularProgressIndicator(
    strokeWidth: 6.0,
    valueColor: AlwaysStoppedAnimation<Color>(ivoryColor),
    backgroundColor: Colors.white.withOpacity(0.3),
  ),
)

          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (_conversationState.isThinking)
                          const LinearProgressIndicator(),
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            itemCount: _conversationState.messages.length,
                            itemBuilder: (context, index) {
                              return _buildMessageBubble(
                                  _conversationState.messages[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Visibility(
                    visible: _showMicButton,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _navigateToRecordingScreen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.all(20),
                            minimumSize: const Size(50, 50),
                          ),
                          child: const Icon(
                            Icons.mic,
                            size: 30,
                            color: Colors.white,
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
}
