import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:LumorahAI/services/ElevenLabsService.dart';
import 'package:LumorahAI/utils/PermissionService.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:lottie/lottie.dart';
import 'package:LumorahAI/services/ChatServiceApi.dart';
import 'package:easy_localization/easy_localization.dart';

class RecordingScreen extends StatefulWidget {
  final String language;
  final ChatServiceApi chatService;

  const RecordingScreen({
    Key? key,
    required this.language,
    required this.chatService,
  }) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late ElevenLabsService _elevenLabsService;
  late FlutterTts _flutterTts;
  bool _isRecording = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  String _partialTranscription = '';
  String _aiResponse = '';
  String _statusMessage = '';
  String _emotionalState = 'neutral';
  String _conversationLevel = 'basic';
  bool _hasVibrator = false;
  double _soundLevel = 0.0;
  double _smoothedSoundLevel = 0.0;
  Timer? _silenceTimer;
  final int _silenceTimeout = 5000;
  bool _showListeningIndicator = false;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseScale;
  late AnimationController _thinkingAnimationController;
  late AnimationController _rhythmAnimationController;
  late Animation<double> _rhythmValue;

  StreamSubscription<AudioInterruptionEvent>? _audioSessionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _elevenLabsService = ElevenLabsService(
      apiKey: "sk_5c7014c450eb767dbc8cd3ca2cdadadaceb4dbc52708cac9",
    );
    _statusMessage = 'listening'.tr();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 130.0, end: 200.0).animate(
      CurvedAnimation(
          parent: _pulseAnimationController, curve: Curves.easeInOut),
    );

    _thinkingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _rhythmAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rhythmValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _rhythmAnimationController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _rhythmAnimationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _rhythmAnimationController.forward();
        }
      });

    _initTts();
    _initVibration();
    _configureAudioSession().then((_) {
      _checkPermissionsBeforeRecording();
    });
  }

  Future<void> _configureAudioSession() async {
    if (Platform.isIOS) {
      try {
        final session = await AudioSession.instance;
        await session.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
                  AVAudioSessionCategoryOptions.allowBluetooth |
                  AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        ));
        await session.setActive(true);

        _audioSessionSubscription =
            session.interruptionEventStream.listen((event) {
          if (event.begin) {
            _stopRecording();
          } else {
            _startRecording();
          }
        });
      } catch (e) {
        debugPrint('Error configuring audio session: $e');
      }
    }
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

  Future<void> _checkPermissionsBeforeRecording() async {
    final permissionService = PermissionService();
    final micStatus =
        await permissionService.checkOrRequest(Permission.microphone);

    if (!micStatus.isGranted) {
      if (micStatus.isPermanentlyDenied && mounted) {
        _showErrorSnackBar(
            'Por favor habilita los permisos de micrófono en Configuración');
        await openAppSettings();
        return;
      }
    }

    if (mounted && micStatus.isGranted) {
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) _startRecording();
      });
    }
  }

  Future<void> _initTts() async {
    _elevenLabsService.setOnComplete(() => _handleAudioCompletion());

    final languageMap = {
      'es': 'es-ES',
      'en': 'en-US',
      'fr': 'fr-FR',
      'pt': 'pt-BR',
    };

    final ttsLanguage = languageMap[widget.language] ?? 'es-ES';
    await _flutterTts.setLanguage(ttsLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.1);
    _flutterTts.setCompletionHandler(() => _handleAudioCompletion());
  }

  void _handleAudioCompletion() {
    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
      _isProcessing = false;
      _statusMessage = 'listening'.tr();
      _showListeningIndicator = true;
      _pulseAnimationController.forward();
      _thinkingAnimationController.stop();
      _rhythmAnimationController.stop();

      if (_hasVibrator) Vibration.cancel();

      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _startRecording();
      });
    });
  }

  Future<void> _initVibration() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      setState(() => _hasVibrator = hasVibrator ?? false);
    } catch (e) {
      setState(() => _hasVibrator = false);
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isSpeaking) return;

    if (Platform.isIOS) {
      try {
        final session = await AudioSession.instance;
        final micStatus = await Permission.microphone.status;
        if (!micStatus.isGranted) {
          final status = await Permission.microphone.request();
          if (!status.isGranted) {
            if (mounted) {
              _showErrorSnackBar('Se requieren permisos de micrófono');
              if (status.isPermanentlyDenied) {
                await openAppSettings();
              }
            }
            return;
          }
        }

        if (!await session.setActive(true)) {
          if (mounted) {
            _showErrorSnackBar(
                'El micrófono está siendo usado por otra aplicación');
          }
          return;
        }
      } catch (e) {
        debugPrint('Error checking iOS microphone: $e');
        return;
      }
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
          setState(() {
            _statusMessage = 'listening'.tr();
            _showListeningIndicator = true;
          });
        }
      },
      onError: (error) => _handleRecordingError(error.errorMsg),
    );

    if (available) {
      final localeId = {
            'es': 'es_ES',
            'en': 'en_US',
            'fr': 'fr_FR',
            'pt': 'pt_BR'
          }[widget.language] ??
          'es_ES';

      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty && mounted) {
            setState(() {
              _partialTranscription = result.recognizedWords;
              _showListeningIndicator = true;
            });
            _resetSilenceTimer();
            _pulseAnimationController.forward();
          }
        },
        onSoundLevelChange: (level) {
          if (_isRecording && mounted) {
            final newLevel = ((level + 160) / 160).clamp(0.0, 1.0);
            setState(() {
              _soundLevel = newLevel;
              _smoothedSoundLevel =
                  lerpDouble(_smoothedSoundLevel, _soundLevel, 0.1)!;
              if (newLevel > 0.1) {
                _showListeningIndicator = true;
                _resetSilenceTimer();
              }
            });
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        partialResults: true,
      );

      if (mounted) {
        setState(() {
          _isRecording = true;
          _statusMessage = 'listening'.tr();
          _showListeningIndicator = true;
          _pulseAnimationController.forward();
        });
      }
      _startSilenceTimer();
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _startSilenceTimer();
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel(); // Cancelar cualquier timer existente
    _silenceTimer = Timer(Duration(milliseconds: _silenceTimeout), () {
      if (_isRecording && mounted) {
        setState(() => _showListeningIndicator = false);
        _stopRecording();
      }
    });
  }

  void _handleRecordingError(String errorMsg) {
    if (!mounted) return;
    setState(() {
      _statusMessage = 'error'.tr() + errorMsg;
      _isRecording = false;
      _isProcessing = false;
      _soundLevel = 0.0;
      _smoothedSoundLevel = 0.0;
      _pulseAnimationController.stop();
      _thinkingAnimationController.stop();
      if (_hasVibrator) Vibration.cancel();
    });
    if (!errorMsg.toLowerCase().contains('permission')) {
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) _startRecording();
      });
    }
  }

  Future<void> _stopRecording() async {
    _silenceTimer?.cancel();
    await _speech.stop();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusMessage = 'Procesando...';
      _showListeningIndicator = true;
      _pulseAnimationController.stop();
      _thinkingAnimationController.forward();
    });

    if (_partialTranscription.isNotEmpty) {
      await _processTranscription();
    } else {
      setState(() {
        _statusMessage = 'no_speech_detected'.tr();
        _isProcessing = false;
        _startRecording();
      });
    }
  }

  Future<void> _processTranscription() async {
    try {
      final response = await widget.chatService.sendVoiceMessage(
        message: _partialTranscription,
        language: widget.language,
        sessionId: null,
      );

      if (mounted) {
        setState(() {
          _aiResponse = response['ai_message']['text'];
          _emotionalState =
              response['ai_message']['emotional_state'] ?? 'neutral';
          _conversationLevel =
              response['ai_message']['conversation_level'] ?? 'basic';
          _statusMessage = 'Hablando IA...';
          _isSpeaking = true;
          _isProcessing = false;
          _showListeningIndicator = true;
          _thinkingAnimationController.forward();
          _rhythmAnimationController.forward();

          if (_hasVibrator) {
            Vibration.cancel();
            Vibration.vibrate(pattern: [1000, 100, 1000, 100], repeat: -1);
          }
        });
      }

      try {
        await _elevenLabsService.speak(
          _aiResponse,
          'pFZP5JQG7iQjIQuC4Bku',
          widget.language,
        );
      } catch (e) {
        await _flutterTts.speak(_aiResponse);
      }
    } catch (e) {
      _handleRecordingError(e.toString());
      _startRecording();
    }
  }

  void _closeScreen() {
    _silenceTimer?.cancel();
    _speech.stop();
    _flutterTts.stop();
    _elevenLabsService
        .stop(); // Asegúrate de que ElevenLabsService tenga un método stop
    _pulseAnimationController.stop();
    _thinkingAnimationController.stop();
    _rhythmAnimationController.stop();
    if (_hasVibrator) Vibration.cancel();

    Navigator.pop(context, {
      'transcription': _partialTranscription,
      'ai_response': _aiResponse,
      'emotional_state': _emotionalState,
      'conversation_level': _conversationLevel,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopRecording();
      if (Platform.isIOS) {
        AudioSession.instance.then((session) => session.setActive(false));
      }
    } else if (state == AppLifecycleState.resumed) {
      if (Platform.isIOS) {
        AudioSession.instance.then((session) => session.setActive(true));
      }
      _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color tiffanyColor = Color(0xFF88D5C2);

    return Scaffold(
      backgroundColor: tiffanyColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: ParticulasFlotantes()),
            Column(
              children: [
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: _showListeningIndicator ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isProcessing
                          ? Lottie.asset(
                              'assets/animations/animacioncirculo.json',
                              width: 250,
                              height: 250,
                              controller: _thinkingAnimationController,
                            )
                          : AnimatedBuilder(
                              animation: _pulseScale,
                              builder: (context, child) {
                                return Container(
                                  width: _pulseScale.value,
                                  height: _pulseScale.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFE5B4).withOpacity(0.7),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            _isRecording ? Colors.red : Colors.blueGrey,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _isRecording ? Icons.mic : Icons.mic_none,
                              size: 35,
                              color: Colors.white,
                            ),
                            if (_isRecording)
                              Positioned(
                                bottom: 5,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.5),
                                        blurRadius: 5,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blueGrey,
                        child: IconButton(
                          icon:
                              Icon(Icons.close, color: Colors.white, size: 35),
                          onPressed: _closeScreen,
                        ),
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

  @override
  void dispose() {
    _silenceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Cancelar el stream de interrupciones de audio
    _audioSessionSubscription?.cancel();

    if (Platform.isIOS) {
      AudioSession.instance.then((session) {
        session.setActive(false);
      });
    }

    _speech.stop();
    _flutterTts.stop();
    _elevenLabsService.dispose();
    _pulseAnimationController.dispose();
    _thinkingAnimationController.dispose();
    _rhythmAnimationController.dispose();

    if (_hasVibrator) Vibration.cancel();

    super.dispose();
  }
}

class ParticulasFlotantes extends StatefulWidget {
  @override
  _ParticulasFlotantesState createState() => _ParticulasFlotantesState();
}

class _ParticulasFlotantesState extends State<ParticulasFlotantes>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    for (int i = 0; i < 10; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2 + 1,
        speed: _random.nextDouble() * 0.15 + 0.05,
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
