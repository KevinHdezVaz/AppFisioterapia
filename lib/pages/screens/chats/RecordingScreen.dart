import 'package:flutter/material.dart';
 import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecordingScreen extends StatefulWidget {
  final String language;

  const RecordingScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late stt.SpeechToText _speech;
  bool _isRecording = false;
  String _partialTranscription = '';
  String _statusMessage = 'Toca el micrófono para grabar';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _startRecording() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        setState(() {
          _statusMessage = 'Estado: $status';
        });
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'Error: ${error.errorMsg}';
          _isRecording = false;
        });
      },
    );

    if (available) {
      _speech.listen(
        onResult: (result) {
          setState(() {
            _partialTranscription = result.recognizedWords;
          });
        },
        localeId: widget.language == 'es' ? 'es_ES' : 'en_US',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      );

      setState(() {
        _isRecording = true;
        _statusMessage = 'Grabando...';
      });
    } else {
      setState(() {
        _statusMessage = 'No se pudo inicializar el reconocimiento de voz';
      });
    }
  }

  Future<void> _stopRecording() async {
    await _speech.stop();
    setState(() {
      _isRecording = false;
      _statusMessage = 'Procesando...';
    });

    if (_partialTranscription.isNotEmpty) {
      Navigator.pop(context, {'transcription': _partialTranscription});
    } else {
      setState(() {
        _statusMessage = 'No se detectó ninguna transcripción';
      });
    }
  }

  void _closeScreen() {
    Navigator.pop(context, _partialTranscription.isNotEmpty ? {'transcription': _partialTranscription} : null);
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2F),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: _closeScreen,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SpinKitFadingCircle(
                  color: Colors.white,
                  size: 100.0,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Luna pensando...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                AvatarGlow(
                  animate: _isRecording,
                  glowColor: Colors.red,
                  endRadius: 40.0,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: _isRecording ? Colors.red : Colors.redAccent,
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                if (_partialTranscription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _partialTranscription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
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