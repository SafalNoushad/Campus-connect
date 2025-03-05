import 'dart:io';

class NetworkConfig {
  static String getBaseUrl() {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:5001"; // ✅ Android Emulator
    } else if (Platform.isIOS) {
      return "http://localhost:5001"; // ✅ iOS Simulator
    } else {
      return "http://192.168.1.181:5001"; // ✅ Default to a real device (CHANGE this to your local IP)
    }
  }
}
