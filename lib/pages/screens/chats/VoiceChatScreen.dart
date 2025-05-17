import 'dart:async';
import 'package:LumorahAI/model/ChatMessage.dart';
import 'package:LumorahAI/pages/screens/chats/ConversationState.dart';
import 'package:LumorahAI/pages/screens/chats/RecordingScreen.dart';
import 'package:LumorahAI/services/ChatServiceApi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  String _partialTranscription = '';
  String _statusMessage = 'Toca el micrófono para comenzar';
  bool _isRecording = false;

  final Color _primaryColor = const Color.fromARGB(255, 255, 255, 255);
  final Color _backgroundColor = const Color(0xFF88D5C2);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _flutterTts = FlutterTts();
    _conversationState = ConversationState();
    _chatService = ChatServiceApi();
    _speech = stt.SpeechToText();

    await _initTts();
    await _initializePusher();
    await _requestPermissions();
    await _checkSupportedLocales();
  }

  Future<void> _requestPermissions() async {
    var microphoneStatus = await Permission.microphone.request();

    if (microphoneStatus != PermissionStatus.granted) {
      _showError('Permiso de micrófono denegado. Por favor, habilítalo en la configuración.');
      return;
    }
  }

  Future<void> _checkSupportedLocales() async {
    List<stt.LocaleName> locales = await _speech.locales();
    for (var locale in locales) {
      debugPrint('Locale soportado: ${locale.localeId} - ${locale.name}');
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(widget.language);
    await _flutterTts.setSpeechRate(0.5);
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
                _playResponse(aiResponse);
                _handleAIResponse({
                  'ai_message': {
                    'text': aiResponse,
                    'emotional_state': data['emotional_state'] ?? 'neutral',
                    'conversation_level': data['conversation_level'] ?? 'basic',
                  },
                });
                _statusMessage = 'Respuesta reproducida';
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

  Future<void> _startRecording() async {
    if (!_isRecording) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          setState(() {
            _statusMessage = 'Estado: $status';
          });
          debugPrint('Estado de escucha: $status');
        },
        onError: (error) {
          setState(() {
            _statusMessage = 'Error: ${error.errorMsg}';
            _isRecording = false;
          });
          debugPrint('Error de escucha: ${error.errorMsg}');
        },
      );

      if (available) {
        _speech.listen(
          onResult: (result) {
            setState(() {
              _partialTranscription = result.recognizedWords;
              debugPrint('Transcripción parcial: $_partialTranscription');
            });
          },
          localeId: widget.language == 'es' ? 'es_ES' : 'en_US',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          cancelOnError: false,
          partialResults: true,
        );

        setState(() {
          _isRecording = true;
          _statusMessage = 'Grabando y transcribiendo...';
        });
      } else {
        setState(() {
          _statusMessage = 'No se pudo inicializar el reconocimiento de voz';
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _speech.stop();

      setState(() {
        _isRecording = false;
        _statusMessage = 'Procesando...';
      });

      if (_partialTranscription.isNotEmpty) {
        await _processTranscription();
      } else {
        _showError('No se detectó ninguna transcripción');
      }
    }
  }

  Future<void> _processTranscription() async {
    try {
      setState(() {
        _conversationState.setCurrentMessage(_partialTranscription);
      });

      final response = await _chatService.sendMessage(
        message: _partialTranscription,
        language: widget.language,
        sessionId: null,
        isTemporary: true,
      );
      final aiResponse = response['ai_message']['text'];
      final emotionalState = response['ai_message']['emotional_state'] ?? 'neutral';
      final conversationLevel = response['ai_message']['conversation_level'] ?? 'basic';

      Timer(const Duration(seconds: 5), () {
        if (_statusMessage == 'Esperando respuesta del servidor...') {
          _conversationState.setCurrentMessage(aiResponse);
          _playResponse(aiResponse);
          _handleAIResponse({
            'ai_message': {
              'text': aiResponse,
              'emotional_state': emotionalState,
              'conversation_level': conversationLevel,
            },
          });
          setState(() {
            _statusMessage = 'Respuesta reproducida (usando fallback)';
          });
        }
      });

      setState(() {
        _statusMessage = 'Esperando respuesta del servidor...';
      });
    } catch (e) {
      _showError('Error procesando transcripción: ${e.toString()}');
    }
  }

  Future<void> _playResponse(String text) async {
    await _flutterTts.speak(text);
    setState(() {
      _statusMessage = 'Toca el micrófono para continuar';
    });
  }

    void _navigateToRecordingScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingScreen(
          language: widget.language,
        ),
      ),
    );
  }

  void _handleAIResponse(Map<String, dynamic> response) {
    _conversationState.addUserMessage(
      _partialTranscription,
      emotionalState: response['ai_message']['emotional_state'],
    );
    _conversationState.addAiMessage(
      response['ai_message']['text'],
      emotionalState: response['ai_message']['emotional_state'],
      conversationLevel: response['ai_message']['conversation_level'],
    );
    setState(() {
      _partialTranscription = '';
    });
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
      _partialTranscription = '';
      _statusMessage = 'Nueva conversación iniciada. Toca el micrófono';
    });
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
                color: isUser ? _primaryColor : Colors.deepPurple,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isUser ? 'Tú' : 'Lumorah',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUser ? _primaryColor : Colors.deepPurple,
                ),
              ),
              if (message.emotionalState != null) ...[
                const Spacer(),
                _buildEmotionIndicator(message.emotionalState!),
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
        title: const Text('Desahógate con Lumorah'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewSession,
            tooltip: 'Nueva conversación',
          ),
        ],
      ),
      body: Column(
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
                  if (_partialTranscription.isNotEmpty && _isRecording)
                    _buildMessageBubble(ChatMessage(
                      id: -1,
                      chatSessionId: -1,
                      userId: 0,
                      text: _partialTranscription,
                      isUser: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    )),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _navigateToRecordingScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _startNewSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Nueva Sesión',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}