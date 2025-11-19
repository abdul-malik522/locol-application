import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  AudioRecorderService._();
  static final AudioRecorderService instance = AudioRecorderService._();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _timer;
  int _durationSeconds = 0;
  final _durationController = StreamController<int>.broadcast();

  Stream<int> get durationStream => _durationController.stream;
  bool get isRecording => _isRecording;
  int get currentDuration => _durationSeconds;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    _isRecording = true;
    _durationSeconds = 0;
    _durationController.add(0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationSeconds++;
      _durationController.add(_durationSeconds);
    });
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _timer?.cancel();
    _timer = null;
    _isRecording = false;

    final path = await _recorder.stop();
    _durationSeconds = 0;
    _durationController.add(0);

    return path;
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _timer?.cancel();
    _timer = null;
    _isRecording = false;
    _durationSeconds = 0;
    _durationController.add(0);

    final path = await _recorder.stop();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _durationController.close();
  }
}

