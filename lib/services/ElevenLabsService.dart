import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class ElevenLabsService {
  final String apiKey;
  final String baseUrl = 'https://api.elevenlabs.io/v1/text-to-speech';
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  StreamSubscription? _completionSubscription;

  ElevenLabsService({required this.apiKey}) {
    _configureAudioPlayer();
  }

  Future<void> _configureAudioPlayer() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);

      // Configuración para ambas plataformas
      await _audioPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: [
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
          ],
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.speech,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
    } catch (e) {
      print('Error configuring audio player: $e');
    }
  }

  Future<void> speak(String text, String voiceId, String language) async {
    try {
      if (_isSpeaking) {
        await stop(); // Asegura que stop() complete antes de continuar
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/$voiceId'),
            headers: _buildHeaders(),
            body: _buildBody(text, language),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
            '❌ ElevenLabs Error (${response.statusCode}): ${response.body}');
      }

      await _handleAudioResponse(response.bodyBytes);
    } catch (e) {
      _isSpeaking = false;
      rethrow; // Propaga el error para manejarlo en RecordingScreen
    }
  }

  Map<String, String> _buildHeaders() => {
        'accept': 'audio/mpeg',
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
      };

  String _buildBody(String text, String language) => json.encode({
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75,
        },
      });

  Future<void> _handleAudioResponse(Uint8List bytes) async {
    _isSpeaking = true;

    if (Platform.isIOS) {
      await _playOnIOS(bytes);
    } else {
      await _audioPlayer.play(BytesSource(bytes));
    }
  }

  Future<void> _playOnIOS(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/el_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');

    try {
      // Verificar si el archivo existe y eliminarlo
      if (await file.exists()) {
        await file.delete();
      }
      await file.writeAsBytes(bytes);
      await _audioPlayer.play(DeviceFileSource(file.path));

      // Limpieza post-reproducción
      _audioPlayer.onPlayerComplete.listen((_) async {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting temp file: $e');
        }
      });
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  void setOnComplete(void Function() onComplete) {
    _completionSubscription?.cancel();
    _completionSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _isSpeaking = false;
      onComplete();
    });
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      _completionSubscription?.cancel();
      _completionSubscription = null;
    } catch (e) {
      print('Error stopping audio player: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await stop(); // Detener cualquier reproducción antes de liberar
      await _audioPlayer.dispose();
      _completionSubscription?.cancel();
      _completionSubscription = null;
    } catch (e) {
      print('Error disposing audio player: $e');
    }
  }

  bool get isSpeaking => _isSpeaking;
}
