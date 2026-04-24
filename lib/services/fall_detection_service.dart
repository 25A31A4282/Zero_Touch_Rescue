import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'emergency_service.dart';

class FallDetectionService {

  StreamSubscription? _subscription;

  void startListening() {
    _subscription = accelerometerEvents.listen((event) {

      double x = event.x;
      double y = event.y;
      double z = event.z;

      double acceleration =
          (x * x + y * y + z * z);

      
      if (acceleration < 2) {
        print("Possible fall detected");

        Future.delayed(const Duration(seconds: 2), () {
          _checkImpact();
        });
      }
    });
  }

  void _checkImpact() {
    accelerometerEvents.first.then((event) {

      double x = event.x;
      double y = event.y;
      double z = event.z;

      double acceleration =
          (x * x + y * y + z * z);

      // 💥 IMPACT (very high acceleration)
      if (acceleration > 100) {
        print("Impact detected 🚨");

        _triggerEmergency();
      }
    });
  }

  void _triggerEmergency() {
    EmergencyService().triggerEmergency("Fall Detected");
  }

  void stop() {
    _subscription?.cancel();
  }
}