import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText speech = SpeechToText();

  Future<bool> initialize({Function(String)? onStatus}) async {
    return await speech.initialize(
      onStatus: onStatus,
    );
  }

  Future<void> startListening(
    Function(String) onResult,
  ) async {
    await speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenMode: ListenMode.dictation,
    );
  }

  Future<void> stopListening() async {
    await speech.stop();
  }
}
