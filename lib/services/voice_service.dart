import 'package:speech_to_text/speech_to_text.dart';
import 'gemini_service.dart';
import 'package:flutter/foundation.dart'; 
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  final GeminiService _gemini = GeminiService();

  // Getter to check status
  bool get isListening => _isListening;

  Future<void> startListening(Function(Map<String, dynamic> alertData) onDangerDetected) async {
    try {
      bool available = await _speech.initialize(
        onError: (val) {
          _isListening = false;
          debugPrint('Mic Error: $val');
        },
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') _isListening = false;
          debugPrint('Mic Status: $val');
        },
      );

      if (available) {
        _isListening = true;
        _speech.listen(
          onResult: (result) async {
            
            if (result.finalResult) {
              String text = result.recognizedWords.toLowerCase();
              debugPrint("Voice Recognized: $text");
              
              if (text.contains("help") || 
                  text.contains("save me") || 
                  text.contains("emergency") || 
                  text.contains("amma") || 
                  text.contains("kapadandi") ||
                  text.contains("bachao")) {
                
                debugPrint("🚨 Keyword Detected! Sending to Gemini AI...");
                
                // Gemini analysis logic
                final analysis = await _gemini.analyzeEmergency(text);
                
                if (analysis["isDanger"] == true) {
                  onDangerDetected(analysis);
                }
              }
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          listenMode: ListenMode.confirmation, 
        );
      }
    } catch (e) {
      _isListening = false;
      debugPrint("Voice Service Error: $e");
    }
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }
}