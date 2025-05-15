import 'dart:io';

import 'package:LumorahAI/services/ChatServiceApi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

 
class VoiceChatScreen extends StatefulWidget {
  final int? sessionId;
  final String language;

  const VoiceChatScreen({
    Key? key,
    this.sessionId,
    required this.language,
  }) : super(key: key);

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}


class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final TextEditingController _textController = TextEditingController();

  bool _isListening = false;
  bool _isRecording = false;
  String? _audioPath;
  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _textController.text = val.recognizedWords;
        });
      });
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _startRecording() async {
   final path = '/sdcard/Download/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
await _recorder.startRecorder(
  toFile: path,
  codec: Codec.aacMP4,
);

    setState(() {
      _isRecording = true;
      _audioPath = path;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);

    if (_audioPath != null) {
      final file = File(_audioPath!);
      final transcript = await ChatServiceApi().transcribeAudio(file);
      _textController.text = transcript;
    }
  }

 Future<void> _sendMessage() async {
  final text = _textController.text;
  if (text.isEmpty) return;

  setState(() {
    _messages.add({'role': 'user', 'content': text});
    _textController.clear();
  });

  final response = await ChatServiceApi().sendMessage(
    message: text,
    language: 'es', // o 'en', según lo que uses
  );

  final assistantMessage = response['message'] ?? 'Sin respuesta';

  setState(() {
    _messages.add({'role': 'assistant', 'content': assistantMessage});
  });

  await _flutterTts.speak(assistantMessage);
}


  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg['content'] ?? ''),
                  subtitle: Text(msg['role'] ?? ''),
                );
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
              IconButton(
                icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(hintText: 'Escribe o habla...'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
