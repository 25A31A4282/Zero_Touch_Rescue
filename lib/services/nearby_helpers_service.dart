import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class NearbyHelpersService {

  final DatabaseReference db =
      FirebaseDatabase.instance.ref("helpers");

  Future<List<Map>> getNearbyHelpers(
      double myLat, double myLng) async {

    final snapshot = await db.get();

    List<Map> nearbyHelpers = [];

    if (!snapshot.exists) return nearbyHelpers;

    Map data = snapshot.value as Map;

    data.forEach((key, value) {

      try {
        double lat = (value["lat"] ?? 0).toDouble();
        double lng = (value["lng"] ?? 0).toDouble();

        double distance =
            _calculateDistance(myLat, myLng, lat, lng);

        if (distance <= 5) {
          nearbyHelpers.add({
            "name": value["name"] ?? "Unknown",
            "phone": value["phone"] ?? "",
            "distance": distance
          });
        }

      } catch (e) {
        print("⚠️ Invalid helper data skipped");
      }
    });

    return nearbyHelpers;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {

    const R = 6371;

    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
        cos(_deg2rad(lat2)) *
        sin(dLon / 2) *
        sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }
}