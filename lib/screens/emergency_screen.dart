import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/biometric_service.dart';
import '../services/emergency_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {

  final GeminiService gemini = GeminiService();
  final TextEditingController controller = TextEditingController();

  final BiometricService biometric = BiometricService();
  final EmergencyService emergencyService = EmergencyService();

  String emergencyType = "";
  String alertMessage = "";
  bool isLoading = false;

  // 🚨 AI ANALYSIS
  Future<void> analyzeEmergency() async {
    String input = controller.text.trim();

    if (input.isEmpty) return;

    setState(() {
      isLoading = true;
      emergencyType = "";
      alertMessage = "";
    });

    var result = await gemini.analyzeEmergency(input);

    setState(() {
      emergencyType = result["type"];
      alertMessage = result["alert"];
      isLoading = false;
    });

    handleEmergencyAction(emergencyType);
  }

  // 🚨 ACTION LOGIC
  void handleEmergencyAction(String type) {
    if (type == "accident") {
      print("🚑 Ambulance notified");
    } else if (type == "fire") {
      print("🔥 Fire station notified");
    } else if (type == "crime") {
      print("👮 Police notified");
    } else {
      print("🆘 Nearby helpers notified");
    }
  }

  // 🔐 SAFE BUTTON LOGIC (FIXED)
  Future<void> handleSafe() async {
    bool verified = await biometric.authenticate();

    if (verified) {
      // ✅ SAFE USER
      Navigator.pop(context);
    } else {
      // 🚨 ALERT (FIXED CALL)
      await emergencyService.triggerEmergency(
        "Safe confirmation failed",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Verification failed! Alert sent."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text("Emergency Mode"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.warning_amber_rounded,
              size: 100,
              color: Colors.red,
            ),

            const SizedBox(height: 20),

            const Text(
              "EMERGENCY ACTIVE",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            // 📝 INPUT
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Say or type (help / fire / accident...)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🚨 BUTTON
            ElevatedButton(
              onPressed: isLoading ? null : analyzeEmergency,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SEND EMERGENCY"),
            ),

            const SizedBox(height: 30),

            // 🤖 RESULT
            if (emergencyType.isNotEmpty) ...[
              Text(
                "Type: $emergencyType",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                alertMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 40),

            // 🔐 SAFE BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(200, 50),
              ),
              onPressed: handleSafe,
              child: const Text("I AM SAFE"),
            ),
          ],
        ),
      ),
    );
  }
}