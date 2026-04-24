import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart'; // Ensure latest version
import 'package:shared_preferences/shared_preferences.dart';
import 'nearby_helpers_service.dart';
import 'gemini_service.dart';
import 'encryption_service.dart';

class EmergencyService {
  final DatabaseReference db = FirebaseDatabase.instance.ref("emergencies");
  final GeminiService gemini = GeminiService();
  final EncryptionService encryption = EncryptionService();

  Future<void> triggerEmergency(String userMessage) async {
    String userId = "user_1";

    // 1. AI Analysis
    final aiResult = await gemini.analyzeEmergency(userMessage);
    String type = aiResult["type"] ?? "general";

    // 2. Location Handling
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double lat = position.latitude;
    double lng = position.longitude;

    // 3. 🔐 Encryption (Fixed: string conversion before encryption)
    String encryptedMessage = encryption.encryptData(userMessage);
    String encryptedUserId = encryption.encryptData(userId);
    String encryptedLat = encryption.encryptData(lat.toString());
    String encryptedLng = encryption.encryptData(lng.toString());

    // 4. 📶 Connectivity Check (Fixed for latest connectivity_plus)
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (!isOffline) {
      DatabaseReference newRef = db.push();
      await newRef.set({
        "type": type,
        "message": encryptedMessage,
        "rawInput": encryptedMessage,
        "lat": encryptedLat,
        "lng": encryptedLng,
        "userId": encryptedUserId,
        "status": "pending",
        "acceptedBy": null,
        "time": DateTime.now().toIso8601String(),
      });
    }

    // 5. Nearby Helpers Alert
    NearbyHelpersService helperService = NearbyHelpersService();
    List<Map> helpers = await helperService.getNearbyHelpers(lat, lng);
    for (var h in helpers) {
      print("🚨 Alert sent to ${h["name"]}");
    }

    // 6. Offline Fallback
    if (isOffline) {
      await _sendOfflineSMSAlert(type, lat, lng);
      await _storeOfflineEmergency(type, lat, lng);
      return;
    }

    // 7. Service Routing
    switch (type) {
      case "accident":
        await _notifyAmbulance(lat, lng);
        await _notifyDonors(lat, lng);
        break;
      case "crime":
        await _notifyPolice(lat, lng);
        break;
      case "fire":
        await _notifyFireStation(lat, lng);
        break;
      default:
        await _notifyNearbyHelpers(lat, lng);
        break;
    }
  }

  // SMS Alert
  Future<void> _sendOfflineSMSAlert(String type, double lat, double lng) async {
    String message = "🚨 EMERGENCY ALERT\nType: $type\nLocation: https://www.google.com/maps?q=$lat,$lng";
    List<String> contacts = ["100", "108", "101"];
    for (String number in contacts) {
      await sendSMS(number, message);
    }
  }

  // Fast2SMS Logic
  Future<void> sendSMS(String number, String message) async {
    try {
      await http.post(
        Uri.parse("https://www.fast2sms.com/dev/bulkV2"),
        headers: {
          "authorization": "YOUR_API_KEY_HERE", // ⚠️ Nee key ikkada pettu Pavani
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "message": message,
          "numbers": number,
          "route": "q",
        },
      );
    } catch (e) {
      print("SMS Error: $e");
    }
  }

  // Services
  Future<void> _notifyAmbulance(double lat, double lng) async => print("🚑 Ambulance notified");
  Future<void> _notifyDonors(double lat, double lng) async => print("❤️ Donors notified");
  Future<void> _notifyPolice(double lat, double lng) async => print("👮 Police notified");
  Future<void> _notifyFireStation(double lat, double lng) async => print("🔥 Fire station notified");
  Future<void> _notifyNearbyHelpers(double lat, double lng) async => print("🆘 Nearby helpers notified");

  // Local Storage (Offline)
  Future<void> _storeOfflineEmergency(String type, double lat, double lng) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList("offline_emergencies") ?? [];
    queue.add(jsonEncode({
      "type": type, "lat": lat, "lng": lng, "time": DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList("offline_emergencies", queue);
  }
}