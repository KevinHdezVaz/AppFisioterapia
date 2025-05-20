import 'dart:math';
import 'dart:ui';
import 'package:LumorahAI/services/ElevenLabsService.dart';
import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:lottie/lottie.dart';
import 'package:LumorahAI/services/ChatServiceApi.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
 
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
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late ElevenLabsService _elevenLabsService;
  late FlutterTts _flutterTts; // Respaldo
  bool _isRecording = false;
  bool _isSpeaking = false;
  bool _isLocked = false;
  bool _isDragging = false;
  bool _isProcessing = false;
  String _partialTranscription = '';
  String _aiResponse = '';
  String _statusMessage = '';
  String _emotionalState = 'neutral';
  String _conversationLevel = 'basic';
  bool _hasVibrator = false;
  double _soundLevel = 0.0;
  double _smoothedSoundLevel = 0.0;

  double _micOffsetX = 0.0;
  double _micOffsetY = 0.0;
  bool _showLock = false;
  bool _showTrash = false;
  Offset _dragStartPosition = Offset.zero;
  final double _maxDragLeft = -120.0;
  final double _maxDragUp = -150.0;
  final double _lockThreshold = -100.0;
  final double _trashThreshold = -120.0;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseRotation;
  late AnimationController _thinkingAnimationController;
  late Animation<double> _thinkingRotation;
  late AnimationController _iconAnimationController;
  late Animation<double> _iconOpacity;
  late AnimationController _blinkAnimationController;
  late Animation<double> _blinkOpacity;
  late AnimationController _feedbackAnimationController;
  late Animation<double> _feedbackScale;
  late Animation<double> _feedbackOpacity;
  late AnimationController _rhythmAnimationController;
  late Animation<double> _rhythmValue;
  late AnimationController _particlesAnimationController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _elevenLabsService = ElevenLabsService(
      apiKey: "sk_5c7014c450eb767dbc8cd3ca2cdadadaceb4dbc52708cac9",
    );
    _statusMessage = 'hold_mic'.tr();
    _initTts();
    _initVibration();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 130.0, end: 200.0).animate(
      CurvedAnimation(
          parent: _pulseAnimationController, curve: Curves.easeInOut),
    );
    _pulseRotation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.linear),
    );

    _thinkingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _thinkingRotation = Tween<double>(begin: 0.0, end: 360.0).animate(
      CurvedAnimation(
          parent: _thinkingAnimationController, curve: Curves.linear),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _thinkingAnimationController.forward();
        }
      });

    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _iconAnimationController, curve: Curves.easeInOut),
    );

    _blinkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _blinkOpacity = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _blinkAnimationController, curve: Curves.linear),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _blinkAnimationController.forward();
        }
      });

    _feedbackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
          parent: _feedbackAnimationController, curve: Curves.easeInOut),
    );
    _feedbackOpacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _feedbackAnimationController, curve: Curves.easeInOut),
    );

    _rhythmAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rhythmValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _rhythmAnimationController, curve: Curves.easeInOut  ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _rhythmAnimationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _rhythmAnimationController.forward();
        }
      });

    _particlesAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _pulseAnimationController.forward();
  }

  Future<void> _initTts() async {
    // Configurar ElevenLabs
    _elevenLabsService.setOnComplete(() {
      setState(() {
        _isSpeaking = false;
        _isProcessing = false;
        _statusMessage = _isLocked ? 'recording_locked'.tr() : 'hold_mic'.tr();
        _pulseAnimationController.forward();
        _thinkingAnimationController.stop();
        _rhythmAnimationController.stop();
        _soundLevel = 0.0;
        _smoothedSoundLevel = 0.0;
        if (_hasVibrator) {
          Vibration.cancel();
        }
      });
    });

    // Configurar FlutterTts como respaldo
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
    await _flutterTts.setVolume(1.0);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _isProcessing = false;
        _statusMessage = _isLocked ? 'recording_locked'.tr() : 'hold_mic'.tr();
        _pulseAnimationController.forward();
        _thinkingAnimationController.stop();
        _rhythmAnimationController.stop();
        _soundLevel = 0.0;
        _smoothedSoundLevel = 0.0;
        if (_hasVibrator) {
          Vibration.cancel();
        }
      });
    });
  }

  Future<void> _initVibration() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      setState(() {
        _hasVibrator = hasVibrator ?? false;
      });
    } catch (e) {
      print('Error inicializando vibración: $e');
      setState(() {
        _hasVibrator = false;
      });
    }
  }

  Future<void> _startRecording() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        setState(() {
          _statusMessage =
              _isLocked ? 'recording_locked'.tr() : 'recording'.tr();
        });
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'error'.tr() + error.errorMsg;
          _isRecording = false;
          _isLocked = false;
          _isDragging = false;
          _isProcessing = false;
          _soundLevel = 0.0;
          _smoothedSoundLevel = 0.0;
          _resetMicPosition();
          _pulseAnimationController.stop();
          _thinkingAnimationController.stop();
          _blinkAnimationController.stop();
          _feedbackAnimationController.stop();
          if (_hasVibrator) {
            Vibration.cancel();
          }
        });
      },
    );

    if (available) {
      final localeId = {
        'es': 'es_ES',
        'en': 'en_US',
        'fr': 'fr_FR',
        'pt': 'pt_BR',
      }[widget.language] ?? 'es_ES';

      _speech.listen(
        onResult: (result) {
          setState(() {
            _partialTranscription = result.recognizedWords;
            if (result.recognizedWords.isNotEmpty) {
              _pulseAnimationController.forward();
            }
          });
        },
        onSoundLevelChange: (level) {
          if (_isRecording) {
            setState(() {
              _soundLevel = (level + 160) / 160;
              _soundLevel = _soundLevel.clamp(0.0, 1.0);
              _smoothedSoundLevel = lerpDouble(
                _smoothedSoundLevel,
                _soundLevel,
                0.1,
              )!;
            });
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      );

      setState(() {
        _isRecording = true;
        _statusMessage = _isLocked ? 'recording_locked'.tr() : 'recording'.tr();
        _pulseAnimationController.forward();
        _blinkAnimationController.forward();
      });
    } else {
      setState(() {
        _statusMessage = 'speech_init_failed'.tr();
        _isLocked = false;
        _isDragging = false;
        _isProcessing = false;
        _soundLevel = 0.0;
        _smoothedSoundLevel = 0.0;
        _resetMicPosition();
        _pulseAnimationController.stop();
        _thinkingAnimationController.stop();
        _blinkAnimationController.stop();
        _feedbackAnimationController.stop();
      });
    }
  }

  Future<void> _stopRecording({bool discard = false}) async {
    await _speech.stop();
    setState(() {
      _isRecording = false;
      _isLocked = false;
      _isDragging = false;
      _isProcessing = false;
      _soundLevel = 0.0;
      _smoothedSoundLevel = 0.0;
      _resetMicPosition();
      _pulseAnimationController.forward();
      _thinkingAnimationController.stop();
      _blinkAnimationController.stop();
      _feedbackAnimationController.stop();
      _statusMessage = discard ? 'discarded'.tr() : 'processing'.tr();
      if (!discard && _partialTranscription.isNotEmpty) {
        _isProcessing = true;
        if (_hasVibrator) {
          Vibration.vibrate(pattern: [500, 200, 500, 200], repeat: -1);
        }
      }
    });

    if (!discard && _partialTranscription.isNotEmpty) {
      await _processTranscription();
    } else if (!discard) {
      setState(() {
        _statusMessage = 'no_transcription'.tr();
      });
    }
  }

  Future<void> _processTranscription() async {
    _thinkingAnimationController.forward();
    try {
      final response = await widget.chatService.sendMessage(
        message: _partialTranscription,
        language: widget.language,
        sessionId: null,
        isTemporary: true,
      );
      setState(() {
        _aiResponse = response['ai_message']['text'];
        _emotionalState =
            response['ai_message']['emotional_state'] ?? 'neutral';
        _conversationLevel =
            response['ai_message']['conversation_level'] ?? 'basic';
        _statusMessage = 'playing_response'.tr();
        _isSpeaking = true;
        _isProcessing = false;
        _pulseAnimationController.stop();
        _thinkingAnimationController.forward();
        _rhythmAnimationController.forward();
        if (_hasVibrator) {
          Vibration.cancel();
          Vibration.vibrate(pattern: [1000, 100, 1000, 100], repeat: -1);
        }
      });

      // Intentar con ElevenLabs primero
      try {
        await _elevenLabsService.speak(
          _aiResponse,
          'pFZP5JQG7iQjIQuC4Bku', // Voice ID de Laura
          widget.language,
        );
      } catch (e) {
        print('Error con ElevenLabs, usando FlutterTts: $e');
        // Respaldo con FlutterTts
        await _flutterTts.speak(_aiResponse);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'error'.tr() + e.toString();
        _isProcessing = false;
        _soundLevel = 0.0;
        _smoothedSoundLevel = 0.0;
        _thinkingAnimationController.stop();
        _pulseAnimationController.forward();
        _rhythmAnimationController.stop();
        if (_hasVibrator) {
          Vibration.cancel();
        }
      });
    }
  }

  void _closeScreen() {
    Navigator.pop(context, {
      'transcription': _partialTranscription,
      'ai_response': _aiResponse,
      'emotional_state': _emotionalState,
      'conversation_level': _conversationLevel,
    });
    if (_hasVibrator) {
      Vibration.cancel();
    }
  }

  void _resetMicPosition() {
    setState(() {
      _micOffsetX = 0.0;
      _micOffsetY = 0.0;
      _showLock = false;
      _showTrash = false;
      _isDragging = false;
    });
    _iconAnimationController.reverse();
    _blinkAnimationController.stop();
    _feedbackAnimationController.stop();
  }

  void _handleDragStart(LongPressStartDetails details) {
    setState(() {
      _dragStartPosition = details.localPosition;
      _isDragging = true;
      _iconAnimationController.forward();
      _blinkAnimationController.forward();
    });
  }

  void _handleDragUpdate(LongPressMoveUpdateDetails    details) {
    if (_isRecording && !_isLocked) {
      setState(() {
        final deltaX = details.localPosition.dx - _dragStartPosition.dx;
        final deltaY = details.localPosition.dy - _dragStartPosition.dy;

        _micOffsetX = deltaX.clamp(_maxDragLeft, 0.0);
        _micOffsetY = deltaY.clamp(_maxDragUp, 0.0);

        _showLock = _micOffsetX < _lockThreshold;
        _showTrash = _micOffsetY < _trashThreshold;

        if (_showLock) {
          _feedbackAnimationController.repeat(reverse: true);
        } else if (_showTrash) {
          _feedbackAnimationController.repeat(reverse: true);
        } else {
          _feedbackAnimationController.stop();
        }
      });
    }
  }

  void _handleDragEnd(LongPressEndDetails details) {
    if (_isRecording && !_isLocked) {
      _feedbackAnimationController.stop();
      _blinkAnimationController.stop();
      if (_showTrash) {
        _stopRecording(discard: true);
      } else if (_showLock) {
        setState(() {
          _isLocked = true;
          _micOffsetX = 0.0;
          _micOffsetY = 0.0;
          _showLock = false;
          _showTrash = false;
          _isDragging = false;
          _statusMessage = 'recording_locked'.tr();
        });
        _iconAnimationController.reverse();
      } else {
        _stopRecording();
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _elevenLabsService.dispose();
    _pulseAnimationController.dispose();
    _thinkingAnimationController.dispose();
    _iconAnimationController.dispose();
    _blinkAnimationController.dispose();
    _feedbackAnimationController.dispose();
    _rhythmAnimationController.dispose();
    _particlesAnimationController.dispose();
    if (_hasVibrator) {
      Vibration.cancel();
    }
    super.dispose();
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
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: _isProcessing
                          ? Lottie.asset(
                              'assets/animations/animacioncirculo.json',
                              width: 250,
                              height: 250,
                              fit: BoxFit.contain,
                              repeat: true,
                              animate: true,
                              controller: _thinkingAnimationController,
                            )
                          : AnimatedBuilder(
                              animation: Listenable.merge([
                                _pulseScale,
                                _rhythmAnimationController,
                              ]),
                              builder: (context, child) {
                                final soundLevel = _isRecording
                                    ? _smoothedSoundLevel
                                    : _isSpeaking
                                        ? _rhythmValue.value
                                        : 0.0;
                                final adjustedSize = _pulseScale.value *
                                    (1.0 + soundLevel * 0.3);
                                return Container(
                                  width: adjustedSize,
                                  height: adjustedSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFE5B4).withOpacity(0.7),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color(0xFFFFE5B4).withOpacity(0.8),
                                        blurRadius: 50,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation:
                          Listenable.merge([_iconOpacity, _blinkOpacity]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: _isDragging
                              ? _iconOpacity.value * _blinkOpacity.value
                              : 0.0,
                          child: Transform.translate(
                            offset: const Offset(0, -80),
                            child: const Icon(
                              Icons.arrow_upward,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation:
                          Listenable.merge([_iconOpacity, _blinkOpacity]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: _isDragging
                              ? _iconOpacity.value * _blinkOpacity.value
                              : 0.0,
                          child: Transform.translate(
                            offset: const Offset(-80, 0),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _iconOpacity,
                        _blinkOpacity,
                        _feedbackScale,
                        _feedbackOpacity
                      ]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: _isDragging
                              ? _iconOpacity.value *
                                  _blinkOpacity.value *
                                  (_showTrash ? _feedbackOpacity.value : 0.5)
                              : 0.0,
                          child: Transform.scale(
                            scale: _showTrash ? _feedbackScale.value : 1.0,
                            child: Transform.translate(
                              offset: const Offset(0, -120),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _iconOpacity,
                        _blinkOpacity,
                        _feedbackScale,
                        _feedbackOpacity
                      ]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: _isDragging
                              ? _iconOpacity.value *
                                  _blinkOpacity.value *
                                  (_showLock ? _feedbackOpacity.value : 0.5)
                              : 0.0,
                          child: Transform.scale(
                            scale: _showLock ? _feedbackScale.value : 1.0,
                            child: Transform.translate(
                              offset: const Offset(-120, 0),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.blue,
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Transform.translate(
                      offset: Offset(_micOffsetX, _micOffsetY),
                      child: AvatarGlow(
                        animate: !_isSpeaking,
                        glowColor: Colors.redAccent,
                        endRadius: 100.0,
                        duration: const Duration(milliseconds: 1000),
                        repeatPauseDuration: const Duration(milliseconds: 100),
                        startDelay: const Duration(milliseconds: 100),
                        child: GestureDetector(
                          onLongPressStart: (details) {
                            if (!_isLocked && !_isSpeaking) {
                              _handleDragStart(details);
                              _startRecording();
                            }
                          },
                          onLongPressMoveUpdate: (details) {
                            _handleDragUpdate(details);
                          },
                          onLongPressEnd: (details) {
                            _handleDragEnd(details);
                          },
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                _isRecording ? Colors.blueGrey : Colors.blueGrey,
                            child: AnimatedScale(
                              scale: _isRecording ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _isRecording ? Icons.mic : Icons.mic_none,
                                size: 35,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLocked)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: () => _stopRecording(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        'stop_button'.tr(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: _closeScreen,
              ),
            ),
          ],
        ),
      ),
    );
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