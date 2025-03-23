import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricsUtil {
  static final LocalAuthentication _auth = LocalAuthentication();
  
  static Future<bool> authenticate(BuildContext context, String reason) async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        return false;
      }
      
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}