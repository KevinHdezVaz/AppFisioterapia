import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:LumorahAI/services/ChatServiceApi.dart';
import 'package:LumorahAI/model/ChatMessage.dart';

class VoiceChatScreen extends StatefulWidget {
  final int? sessionId;
  final String language;
  
  const VoiceChatScreen({
    Key? key,
    this.sessionId,
    required this.language,
  }) : super(key: key);

  @override
  _VoiceChatScreenState createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> 
    with SingleTickerProviderStateMixin {
  late RecorderController _recorderController;
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  bool _isThinking = false;
  String _currentMessage = '';
  List<ChatMessage> _messages = [];
  String? _currentAudioPath;
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  final ChatServiceApi _chatService = ChatServiceApi();
  final Color _primaryColor = Color(0xFF4ECDC4);
  final Color _backgroundColor = Color(0xFFFDF8F2);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initTTS();
  }

  void _initializeControllers() {
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;

    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage(widget.language);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _speech.cancel();
    _tts.stop();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!await _speech.initialize()) {
      _showError('Error al inicializar el reconocimiento de voz');
      return;
    }

    try {
      // Iniciar grabación de audio
      final audioPath = await _getAudioPath();
      await _recorderController.record(path: audioPath);
      
      setState(() {
        _isListening = true;
        _currentMessage = '';
        _currentAudioPath = audioPath;
      });

      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() => _currentMessage = result.recognizedWords);
          }
        },
        localeId: widget.language,
        listenFor: Duration(minutes: 5),
        onSoundLevelChange: (level) {
          _animationController.animateTo(level / 100);
        },
      );
    } catch (e) {
      _showError('Error al iniciar grabación: ${e.toString()}');
    }
  }

  Future<String> _getAudioPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
  }

  Future<void> _stopListening() async {
    try {
      await _recorderController.stop();
      await _speech.stop();
      
      setState(() {
        _isListening = false;
        _isThinking = true;
      });

      if (_currentMessage.isNotEmpty) {
        await _processVoiceMessage();
      }
    } catch (e) {
      _showError('Error al detener grabación: ${e.toString()}');
    }
  }

  Future<void> _processVoiceMessage() async {
    try {
      // 1. Subir audio al servidor (opcional)
      String? audioUrl;
      if (_currentAudioPath != null) {
        audioUrl = await _chatService.uploadAudioFile(_currentAudioPath!);
      }

      // 2. Enviar mensaje de voz
      final response = await _chatService.sendVoiceMessage(
  message: _currentMessage,  // Añade 'message:'
  sessionId: widget.sessionId,
  language: widget.language,
  audioUrl: audioUrl,
);
      // 3. Procesar respuesta
      _handleAIResponse(response);
      
      // 4. Reproducir respuesta
      await _tts.speak(response['ai_message']['text']);
    } catch (e) {
      _showError('Error al procesar mensaje: ${e.toString()}');
    } finally {
      setState(() => _isThinking = false);
    }
  }

  void _handleAIResponse(Map<String, dynamic> response) {
    final aiMessage = ChatMessage(
      id: -1,
      chatSessionId: response['session_id'] ?? widget.sessionId ?? -1,
      userId: 0,
      text: response['ai_message']['text'],
      isUser: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      emotionalState: response['ai_message']['emotional_state'],
      conversationLevel: response['ai_message']['conversation_level'],
    );

    setState(() {
      _messages.insert(0, ChatMessage(
        id: -1,
        chatSessionId: widget.sessionId ?? -1,
        userId: 0,
        text: _currentMessage,
        isUser: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _messages.insert(0, aiMessage);
      _currentMessage = '';
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() => _isThinking = false);
  }

  Widget _buildVoiceAnimation() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _isThinking
          ? _buildThinkingAnimation()
          : _buildVoiceWaveAnimation(),
    );
  }

  Widget _buildVoiceWaveAnimation() {
    return AudioWaveforms(
      key: ValueKey('voice-wave'),
      size: Size(MediaQuery.of(context).size.width * 0.8, 100),
      recorderController: _recorderController,
      waveStyle: WaveStyle(
        waveColor: _primaryColor,
        showMiddleLine: false,
        extendWaveform: true,
      ),
    );
  }

  Widget _buildThinkingAnimation() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud,
                size: 100,
                color: _primaryColor,
              ),
              SizedBox(height: 20),
              Text(
                'Pensando...',
                style: TextStyle(
                  fontSize: 20,
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isUser 
            ? _primaryColor.withOpacity(0.2)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Chat de Voz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Área de animación
                  Container(
                    height: 200,
                    child: Center(
                      child: _buildVoiceAnimation(),
                    ),
                  ),
                  
                  // Mensaje actual
                  if (_currentMessage.isNotEmpty && _isListening)
                    _buildMessageBubble(ChatMessage(
                      id: -1,
                      chatSessionId: -1,
                      userId: 0,
                      text: _currentMessage,
                      isUser: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    )),
                  
                  // Historial de mensajes
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botón de micrófono
          Padding(
            padding: EdgeInsets.only(bottom: 30),
            child: AvatarGlow(
              animate: _isListening,
              glowColor: _primaryColor,
              endRadius: 70.0,
              duration: Duration(milliseconds: 2000),
              repeat: true,
              child: FloatingActionButton(
                onPressed: () async {
                  if (_isListening) {
                    await _stopListening();
                  } else {
                    await _startListening();
                  }
                },
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  size: 36,
                ),
                backgroundColor: _isListening ? Colors.red : _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}