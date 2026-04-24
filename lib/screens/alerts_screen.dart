import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final DatabaseReference db = FirebaseDatabase.instance.ref("alerts");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Emergency Alerts 🚨"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder(
        stream: db.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                "No Alerts Yet 🟢",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          Map data = snapshot.data!.snapshot.value as Map;

          List alerts = data.entries.toList();

          alerts = alerts.reversed.toList(); 

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              var alert = alerts[index].value;

              String type = alert["type"] ?? "Unknown";
              String time = alert["time"] ?? "";
              String lat = alert["lat"].toString();
              String lng = alert["lng"].toString();

              Color cardColor = Colors.orange;

              if (type.contains("VOICE")) cardColor = Colors.red;
              if (type.contains("FALL")) cardColor = Colors.deepOrange;
              if (type.contains("MANUAL")) cardColor = Colors.blue;

              return Card(
                margin: const EdgeInsets.all(10),
                color: cardColor.withOpacity(0.2),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "Time: $time\nLat: $lat | Lng: $lng",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}