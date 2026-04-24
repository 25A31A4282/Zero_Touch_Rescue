import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AlertService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  
  Future<void> triggerEmergency(String type) async {
    try {
     
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String currentTime = DateFormat('hh:mm a, dd MMM').format(DateTime.now());

      Map<String, dynamic> alertData = {
        "type": type,
        "time": currentTime,
        "lat": position.latitude,
        "lng": position.longitude,
        "status": "active",
      };

     
      await _db.child("emergency").push().set(alertData);
      print("Alert pushed to Firebase successfully!");
      
    } catch (e) {
      print("Error in AlertService: $e");
    }
  }
}