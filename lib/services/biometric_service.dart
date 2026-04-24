import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) return false;

      final didAuth = await _auth.authenticate(
        localizedReason: 'Confirm you are safe',
        options: const AuthenticationOptions(
          biometricOnly: false, 
          stickyAuth: true,
        ),
      );

      return didAuth;
    } catch (_) {
      return false;
    }
  }
}