import 'package:flutter/material.dart';
import '../services/emergency_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildCard(BuildContext context, String title, IconData icon, String type) {
    return GestureDetector(
      onTap: () async {
        await EmergencyService().triggerEmergency(type);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$title Alert Sent 🚨")),
        );
      },
      child: Card(
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.red),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Network System"),
        backgroundColor: Colors.red,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          buildCard(context, "Accident 🚗", Icons.car_crash, "accident"),
          buildCard(context, "Crime 🚨", Icons.local_police, "crime"),
          buildCard(context, "Fire 🔥", Icons.fire_truck, "fire"),
          buildCard(context, "Disaster 🌊", Icons.warning, "disaster"),
        ],
      ),
    );
  }
}