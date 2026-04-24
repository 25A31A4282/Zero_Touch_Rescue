import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // Permissions check cheyali
import 'services/emergency_service.dart';
import 'services/voice_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EmergencyService emergency = EmergencyService();
  final VoiceService voice = VoiceService();
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _startSafetyMonitoring(); 
  }

  Future<void> _startSafetyMonitoring() async {
   
    if (await Permission.microphone.isGranted) {
      setState(() => isListening = true);
      
    
      voice.startListening((analysis) {
        String lowerText = analysis.toString().toLowerCase(); 
        if (lowerText.contains("help") ||
            lowerText.contains("save me") ||
            lowerText.contains("emergency")||
            lowerText.contains("kappadandi")) {
          
          // Show alert in UI
          _showEmergencyAlert();
          emergency.triggerEmergency("voice_panic");
        }
      });
    } else {
      print("Microphone permission not granted for voice monitoring.");
    }
  }

  void _showEmergencyAlert() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚨 Emergency Triggered! Sending Alerts..."),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ZeroTouch Rescue"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Visual indicator for voice monitoring
            Icon(
              isListening ? Icons.mic : Icons.mic_off,
              size: 80,
              color: isListening ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              isListening ? "Monitoring for 'Help'..." : "Voice Monitoring Off",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                _showEmergencyAlert();
                emergency.triggerEmergency("manual_test");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("TEST EMERGENCY MANUAL"),
            ),
          ],
        ),
      ),
    );
  }
}