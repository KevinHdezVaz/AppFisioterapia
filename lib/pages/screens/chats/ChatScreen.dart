import 'package:LumorahAI/pages/screens/WaveVisualizer.dart';
import 'package:LumorahAI/pages/screens/chats/VoiceChatScreen.dart';
import 'package:LumorahAI/utils/PermissionHandler.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/painting.dart'
    as painting; // Import explícito para TextDirection
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
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart'; // Para Clipboard

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  String _transcribedText = '';
  bool _isTyping = false;
  int _typingIndex = 0;
  late Timer _typingTimer;
  bool _isSpeechInitialized = false;
  late AnimationController _sunController;
  late Animation<double> _sunAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ChatServiceApi _chatService = ChatServiceApi();
bool _isMicPermissionGranted = false;
 
  // Color palette
  final Color tiffanyColor = Color(0xFF88D5C2);
  final Color ivoryColor = Color(0xFFFDF8F2);
  final Color micButtonColor = Color(0xFF4ECDC4);

  List<ChatMessage> _messages = [];
  int? _currentSessionId;
  bool _isSaved = false;
  String? _emotionalState;
  String? _conversationLevel;
  bool _initialMessageSent = false;

  double _soundLevel = 0.0; // Nueva variable para el nivel de sonido
  // Lógica para conteo de tokens y resumen
  final int _tokenLimit = 500;
  int _totalTokens = 0;

  // Mapa de códigos de idioma para reconocimiento de voz
  final Map<String, String> _speechLocales = {
    'es': 'es_ES',
    'en': 'en_US',
    'fr': 'fr_FR',
    'pt': 'pt_BR',
  };

  List<TextSpan> _parseTextToSpans(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in boldRegex.allMatches(text)) {
      // Texto antes del match
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'Lora',
              fontSize: 15,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        );
      }

      // Texto en negrita
      spans.add(
        TextSpan(
          text: match.group(1), // El texto dentro de **
          style: const TextStyle(
            color: Colors.black87,
            fontFamily: 'Lora',
            fontSize: 15,
            height: 1.6,
            letterSpacing: 0.2,
            fontWeight: FontWeight.bold, // Negrita
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Texto restante después del último match
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(
            color: Colors.black87,
            fontFamily: 'Lora',
            fontSize: 15,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    return spans;
  }


 @override
  void initState() {
    super.initState();
    _messages = widget.initialMessages?.reversed.toList() ?? [];
    _currentSessionId = widget.sessionId;
    _isSaved = widget.sessionId != null && widget.initialMessages != null;

    for (var message in _messages) {
      _updateTokenCount(message.text);
    }

    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _sunAnimation = Tween<double>(begin: 30.0, end: 40.0).animate(
      CurvedAnimation(parent: _sunController, curve: Curves.easeInOut),
    );

    _initializeSpeech();
    _typingTimer = Timer.periodic(Duration.zero, (_) {});
  }

 
 

 Future<void> _initializeSpeech() async {
    try {
      _isMicPermissionGranted = await PermissionHandler.checkAndRequestMicrophonePermission(context);
      if (!_isMicPermissionGranted) {
        return;
      }

      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) {
          debugPrint('Speech error: $error');
          _showErrorSnackBar('Error en reconocimiento de voz: ${error.errorMsg}');
        },
      );

      if (_isSpeechAvailable) {
        setState(() {
          _isSpeechInitialized = true;
        });
        debugPrint('Speech initialized successfully');
      } else {
        debugPrint('Speech initialization failed');
        _showErrorSnackBar('No se pudo inicializar el reconocimiento de voz');
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      _showErrorSnackBar('Error al inicializar el reconocimiento de voz');
    }
  }

  
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initialMessageSent) {
    _initialMessageSent = true;
    if (_currentSessionId == null && _messages.isEmpty) {
      _startNewSession().then((_) {
        if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
          _sendMessage(widget.initialMessage!);
        }
      });
    } else if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _sendMessage(widget.initialMessage!);
    }
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

  int _countTokens(String message) {
    return message.split(RegExp(r'\s+')).length;
  }

  void _updateTokenCount(String message) {
    final tokens = _countTokens(message);
    setState(() {
      _totalTokens += tokens;
    });
    if (_totalTokens > _tokenLimit) {
      _summarizeConversation();
    }
  }

  Future<void> _summarizeConversation() async {
    try {
      setState(() {
        _isTyping = true;
        _typingIndex = 0;
        _typingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
          if (mounted) setState(() => _typingIndex = (_typingIndex + 1) % 3);
        });
      });

      final response = await _chatService.summarizeConversation(
        messages: _messages.reversed
            .map((m) => {
                  'text': m.text,
                  'is_user': m.isUser,
                  'created_at': m.createdAt.toIso8601String(),
                })
            .toList(),
        sessionId: _currentSessionId,
        language: context.locale.languageCode,
      );

      if (!mounted) return;

      final summary = response['summary'];

      setState(() {
        _isTyping = false;
        _typingTimer.cancel();
      });

      _showSummaryModal(summary);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _typingTimer.cancel();
      });
      _showErrorSnackBar(
          'errorSummarizingConversation'.tr(args: [e.toString()]));
    }
  }

  void _showSummaryModal(String summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('conversationTooLong'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'conversationSummary'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(summary, textAlign: TextAlign.justify),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4BB6A8)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('summaryCopied'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: Text('copy'.tr(), style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4BB6A8)),
            onPressed: () {
              Navigator.pop(context);
              _startNewChatWithSummary(summary);
            },
            child: Text('newChat'.tr(), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startNewChatWithSummary(String summary) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          inputMode: widget.inputMode,
          initialMessage: summary,
        ),
      ),
    );
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
      bool soundEnabled =
          await _storageService.getString('sound_enabled') == 'true' ||
              await _storageService.getString('sound_enabled') == null;
      if (soundEnabled) {
        await _audioPlayer.setVolume(0.1);

        await _audioPlayer.play(AssetSource('sounds/pensandoIA.mp3'));
        _audioPlayer.setReleaseMode(ReleaseMode.loop);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('errorPlayingSound'.tr(args: [e.toString()]));
      }
    }
  }

  Future<void> _stopThinkingSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('errorStoppingSound'.tr(args: [e.toString()]));
      }
    }
  }

Future<void> _startNewSession() async {
  setState(() {
    _isLoading = true;
  });
  try {
    final currentUser = await _storageService.getUser();
    final userName = currentUser?.nombre ?? 'Amig@';
    final response = await _chatService.startNewSession(
      language: context.locale.languageCode,
      userName: userName,
    );

    if (!mounted) return;

    setState(() {
      _currentSessionId = response['session_id'];
      _emotionalState = response['ai_message']['emotional_state'] ?? 'neutral';
      _conversationLevel = response['ai_message']['conversation_level'] ?? 'basic';
      _isLoading = false;
    });
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('errorStartingSession'.tr(args: [e.toString()]));
    }
  }
}

Future<void> _sendMessage(String message, {bool isTemporary = false}) async {
  if (!await _isUserAuthenticated()) {
    if (!mounted) return;
    _showAuthModal();
    return;
  }

  if (message.trim().isEmpty) return;

  final currentUser = await _storageService.getUser();
  final newMessage = ChatMessage(
    id: -1,
    chatSessionId: _currentSessionId ?? -1,
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
    _updateTokenCount(newMessage.text);
  });
  _controller.clear();

  await _playThinkingSound();

  try {
    print('Sending message with session_id: $_currentSessionId');
    final response = isTemporary
        ? await _chatService.sendTemporaryMessage(
            message,
            language: context.locale.languageCode,
            userName: currentUser?.nombre ?? 'Amig@',
          )
        : await _chatService.sendMessage(
            message: message,
            sessionId: _currentSessionId,
            isTemporary: false,
            language: context.locale.languageCode,
            userName: currentUser?.nombre ?? 'Amig@',
          );

    if (!mounted) {
      await _stopThinkingSound();
      return;
    }

    print('Received response: $response');
    final aiMessage = ChatMessage(
      id: -1,
      chatSessionId: response['session_id'] ?? _currentSessionId ?? -1,
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
      _typingTimer.cancel();
      if (!isTemporary && response['session_id'] != null) {
        _currentSessionId = response['session_id'];
      }
      _updateTokenCount(aiMessage.text);
    });

    if (aiMessage.emotionalState == 'crisis') {
      _showCrisisAlert();
    }

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
    _showErrorSnackBar('errorSendingMessage'.tr(args: [e.toString()]));
  }
}
 
 

  void _showCrisisAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Estamos aquí para ti'.tr()),
        content: Text(
          'Lo que sientes es importante. Te recomendamos contactar a un profesional o una línea de apoyo cercana. ¿Quieres continuar hablando?'
              .tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continuar'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateBack(context);
            },
            child: Text('Salir'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChat() async {
    if (!await _isUserAuthenticated()) {
      if (!mounted) return;
      _showAuthModal();
      return;
    }

    if (_messages.isEmpty) {
      _showErrorSnackBar('noMessagesToSave'.tr());
      return;
    }

    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('saveConversation'.tr(),
            style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: 'title'.tr(),
            hintText: 'exampleTitle'.tr(),
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
            child: Text('cancel'.tr(), style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4BB6A8)),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context, titleController.text.trim());
              }
            },
            child: Text('save'.tr(), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return;

    try {
      final session = await _chatService.saveChatSession(
        title: title,
        messages: _messages.reversed
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('chatSavedSuccessfully'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('errorSavingChat'.tr(args: [e.toString()]));
    }
  }

  // Elimina esta línea:
// String _transcribedText = '';

Future<void> _startListening() async {
    if (_isListening || !_isSpeechInitialized || !_isMicPermissionGranted) {
      if (!_isMicPermissionGranted) {
        _isMicPermissionGranted = await PermissionHandler.checkAndRequestMicrophonePermission(context);
      }
      if (!_isSpeechInitialized || !_isMicPermissionGranted) {
        return;
      }
    }

    try {
      setState(() {
        _isListening = true;
        _controller.clear();
      });

      final localeId = _speechLocales[context.locale.languageCode] ?? 'es_ES';
      debugPrint('Starting speech recognition with locale: $localeId');

      _speech.listen(
        onResult: (result) {
          debugPrint('Recognized words: ${result.recognizedWords}, Confidence: ${result.confidence}');
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
          });
        },
        localeId: localeId,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: (level) {
          debugPrint('Sound level: $level');
          setState(() {
            _soundLevel = level;
          });
        },
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      setState(() => _isListening = false);
      _showErrorSnackBar('Error al iniciar: $e');
    }
  }
  Future<void> _stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
      _showErrorSnackBar('Error al detener: $e');
    }
  }

  Widget _buildVoiceVisualizer() {
    if (!_isListening) return const SizedBox.shrink();
    return WaveVisualizer(
      soundLevel: _soundLevel,
      primaryColor: Colors.grey,
      secondaryColor: Colors.black, // e.g., Color(0xFF88D5C2)
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.tr()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

Widget _buildMessageBubble(ChatMessage message) {
  final time = "${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}";

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ChatBubble(
          clipper: ChatBubbleClipper1(
            type: message.isUser ? BubbleType.sendBubble : BubbleType.receiverBubble,
          ),
          alignment: message.isUser ? Alignment.topRight : Alignment.topLeft,
          margin: EdgeInsets.only(top: 5),
          backGroundColor: message.isUser
              ? Color(0xFFFFE0B2).withOpacity(0.9)
              : message.emotionalState == 'sensitive'
                  ? Color(0xFFF6F6F6).withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
              minWidth: 0, // Permitir que el contenedor se ajuste al contenido
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Más espacio interno
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
            RichText(
            text: TextSpan(
              children: _parseTextToSpans(message.text),
            ),
            textAlign: message.isUser ? TextAlign.end : TextAlign.start,
            softWrap: true,
            overflow: TextOverflow.visible,
           ),
                if (message.imageUrl != null) Image.network(message.imageUrl!),
                SizedBox(height: 5),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  semanticsLabel: 'Enviado a las $time',
                ),
              ],
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
        return 'sensitiveState'.tr();
      case 'crisis':
        return 'crisisState'.tr();
      default:
        return 'neutralState'.tr();
    }
  }

  String _getConversationLevelText(String? level) {
    switch (level) {
      case 'advanced':
        return 'advancedLevel'.tr();
      default:
        return 'basicLevel'.tr();
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
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'withYou'.tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.95),
                  fontFamily: 'Lora',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'speakWhenever'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black.withOpacity(0.85),
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Lora',
                ),
              ),
            ],
          ),
          _buildAnimatedCircle(), // Sun moved to the right
        ],
      ),
    );
  }

  Widget _buildAnimatedCircle() {
    return AnimatedBuilder(
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
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildKeyboardInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (_isListening) _buildVoiceVisualizer(),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calcular la altura basada en el contenido
              final textPainter = TextPainter(
                text: TextSpan(
                  text: _controller.text.isEmpty ? ' ' : _controller.text,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Lora'),
                ),
                maxLines: null,
                textDirection: painting.TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth - 80);

              final lineCount = textPainter.computeLineMetrics().length;
              final baseHeight = 60.0;
              final lineHeight = 20.0;
              final calculatedHeight =
                  baseHeight + (lineCount - 1) * lineHeight;
              final textFieldHeight = calculatedHeight.clamp(baseHeight, 200.0);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: textFieldHeight,
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'writeHint'.tr(),
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.stop_circle : Icons.mic_none,
                            color: _isListening ? Colors.red : micButtonColor,
                            size: _isListening ? 30 : 24,
                          ),
                          tooltip: _isListening
                              ? 'Detener grabación'
                              : 'Iniciar grabación',
                          onPressed: () async {
                            if (_isListening) {
                              await _stopListening();
                            } else {
                              await _startListening();
                            }
                          },
                        ),
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.send, color: micButtonColor),
                            onPressed: () {
                              _sendMessage(_controller.text);
                              _controller.clear();
                              // Ocultar el teclado
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                          ),
                        if (_controller.text.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.record_voice_over,
                                color: micButtonColor,
                                size: 22,
                              ),
                              tooltip: 'Chat de voz avanzado',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VoiceChatScreen(
                                      language: context.locale.languageCode,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  onChanged: (text) {
                    setState(() {}); // Reconstruir para actualizar la altura
                  },
                  scrollController: ScrollController(),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildVoiceInput() {
    return Column(
      children: [
        Center(
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
        ),
        if (_controller.text
            .isNotEmpty) // Usa _controller.text en lugar de _transcribedText
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              _controller.text,
              style: TextStyle(color: Colors.black87, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
      ],
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
        body: Stack(
          children: [
            _FloatingParticles(),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
               valueColor: AlwaysStoppedAnimation<Color>(ivoryColor), // Color is here
        strokeWidth: 6.0,
        backgroundColor: Colors.white.withOpacity(0.3),
                ),
              )
            else
              Column(
                children: [
                  AppBar(
                    backgroundColor:Color(0xFF88D5C2),
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => _navigateBack(context),
                    ),
                    actions: [
                      if (!_isSaved)
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: TextButton.icon(
                            icon:
                                Icon(Icons.save, color: Colors.black, size: 22),
                            label: Text(
                              'save'.tr(),
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14),
                            ),
                            onPressed: _saveChat,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _buildHeader(),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                reverse: true,
                                itemCount:
                                    _messages.length + (_isTyping ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_isTyping && index == 0) {
                                    return _buildTypingIndicator();
                                  }
                                  final messageIndex =
                                      _isTyping ? index - 1 : index;
                                  return _buildMessageBubble(
                                      _messages[messageIndex]);
                                },
                              ),
                            ),
                            _buildInput(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
      duration:
          const Duration(seconds: 10), // Reducido para movimiento más rápido
    )..repeat();

    // Generar partículas con velocidades más visibles
    for (int i = 0; i < 20; i++) {
      // Aumentar número de partículas
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 2, // Tamaños más grandes
        speed: _random.nextDouble() * 0.3 + 0.1, // Velocidades más altas
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
          size: Size.infinite,
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
      ..color = Colors.white
          .withOpacity(0.2) // Aumentar opacidad para mejor visibilidad
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
