import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final highAcc = prefs.getBool('config_high_acc_loc') ?? true;
    final accuracy = highAcc ? LocationAccuracy.best : LocationAccuracy.low;

    return await Geolocator.getCurrentPosition(desiredAccuracy: accuracy);
  }
}
