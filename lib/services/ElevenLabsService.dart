import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class ElevenLabsService {
  final String apiKey;
  final String baseUrl = 'https://api.elevenlabs.io/v1/text-to-speech';
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;

  ElevenLabsService({required this.apiKey}) {
    _configureAudioForPlatform();
  }

  Future<void> _configureAudioForPlatform() async {
    if (Platform.isIOS) {
      await _audioPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: [
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
          ],
        ),
      ));
    }
  }

  Future<void> speak(String text, String voiceId, String language) async {
    try {
      final languageMap = {
        'es': 'es-ES',
        'en': 'en-US',
        'fr': 'fr-FR',
        'pt': 'pt-BR',
      };
      final ttsLanguage = languageMap[language] ?? 'es-ES';

      final response = await http.post(
        Uri.parse('$baseUrl/$voiceId'),
        headers: {
          'accept': 'audio/mpeg',
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'User-Agent': 'LumorahAI/1.0.0',
        },
        body: json.encode({
          'text': text,
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
          'language': ttsLanguage,
          'output_format': 'mp3_44100_128',
        }),
      );

      if (response.statusCode == 200) {
        _isSpeaking = true;
        final bytes = response.bodyBytes;

        if (Platform.isIOS) {
          // Para iOS: Guardar temporalmente y reproducir desde archivo
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/elevenlabs_temp.mp3');
          await file.writeAsBytes(bytes);
          await _audioPlayer.play(DeviceFileSource(file.path));
          await file.delete(); // Limpiar después de reproducir
        } else {
          // Android: Reproducir directamente desde bytes
          await _audioPlayer.play(BytesSource(bytes));
        }
      } else {
        throw Exception('Failed to generate audio: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      _isSpeaking = false;
      print('ElevenLabs Error: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  bool get isSpeaking => _isSpeaking;

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  void setOnComplete(void Function() onComplete) {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isSpeaking = false;
      onComplete();
    });
  }
}