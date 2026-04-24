import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/emergency_service.dart';
import 'package:battery_plus/battery_plus.dart'; 
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late stt.SpeechToText speech;
  bool isListening = false;
  bool alreadyTriggered = false;
  String text = "Press mic and speak...";
  final Battery _battery = Battery(); 

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

 
  void startListening() async {
    
    int level = await _battery.batteryLevel;
    if (level < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Battery too low for voice recognition! 🔋"))
      );
      return;
    }

    bool available = await speech.initialize(
      onError: (val) => debugPrint("Error: $val"),
      onStatus: (val) => debugPrint("Status: $val"),
    );

    if (available) {
      setState(() {
        isListening = true;
        alreadyTriggered = false;
      });

      speech.listen(
        listenMode: stt.ListenMode.confirmation, 
        partialResults: true,
        onResult: (result) {
          String spoken = result.recognizedWords;
          setState(() {
            text = spoken;
          });
          detectEmergency(spoken);
        },
      );
    }
  }
   
  void stopListening() {
    speech.stop();
    setState(() => isListening = false);
  }

  void detectEmergency(String input) {
    String spoken = input.toLowerCase();

    List<String> keywords = [
      "help", "save me", "emergency", "danger", 
      "please help", "help me", "rakshinchandi", 
      "kapadandi", "bachao", "amma"
    ];

    for (String word in keywords) {
      if (!alreadyTriggered && spoken.contains(word)) {
        alreadyTriggered = true;

        EmergencyService().triggerEmergency("VOICE: $word");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚨 Alert Sent! Detected: $word"),
            backgroundColor: Colors.red,
          ),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Detection 🎤"),
        backgroundColor: Colors.redAccent, 
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isListening ? Icons.record_voice_over : Icons.voice_over_off,
              size: 100,
              color: isListening ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 30),
            
            // 📝 TEXT DISPLAY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 50),

            // 🎤 MIC BUTTON
            GestureDetector(
              onTap: () {
                if (isListening) {
                  stopListening();
                } else {
                  startListening();
                }
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: isListening ? Colors.red : Colors.blue,
                child: Icon(
                  isListening ? Icons.stop : Icons.mic,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isListening ? "Listening... (Speak keywords like 'Help')" : "Tap to start voice monitoring",
              style: TextStyle(fontSize: 16, color: isListening ? Colors.red : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}