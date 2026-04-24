import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  void startFallDetection(Function onFall) {
    accelerometerEvents.listen((event) {
      double force = event.x.abs() + event.y.abs() + event.z.abs();

      // simple fall detection logic
      if (force > 18) {
        onFall();
      }
    });
  }
}