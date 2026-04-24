import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Ee import add chesanu
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/background_service_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Firebase initialize ayye munde .env file load chesthe better
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded! ✅");
  } catch (e) {
    print("Error loading .env file: $e");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await _setupNotificationChannel();

  await _requestPermissions();

  try {
    await BackgroundServiceManager.initializeService();
    print("Service Ready! ✅");
  } catch (e) {
    print("Error: $e");
  }

  runApp(const MyApp());
}

Future<void> _setupNotificationChannel() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const channel = AndroidNotificationChannel(
    'emergency_channel', 
    'Emergency Alerts',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> _requestPermissions() async {
  await [
    Permission.microphone,
    Permission.location,
    Permission.notification,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZeroTouch Rescue', // Optional: Title add chesthe professional ga untundi
      home: const LoginScreen(), 
    );
  }
}