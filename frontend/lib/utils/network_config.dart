import 'dart:io';

class NetworkConfig {
  static String getBaseUrl() {
    // Use environment variable if provided (e.g., during build)
    final baseUrl = String.fromEnvironment(
      'BASE_URL',
      defaultValue: '', // Empty string as default
    );

    // Return BASE_URL if defined and not empty, otherwise use platform-specific defaults
    if (baseUrl.isNotEmpty) {
      return baseUrl;
    } else if (Platform.isAndroid &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      // Android Emulator (not real device or test)
      return "http://10.0.2.2:5001";
    } else if (Platform.isIOS &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      // iOS Simulator (not real device or test)
      return "http://localhost:5001";
    } else {
      // Real devices or other platforms
      return "http://172.20.10.8:5001"; // Replace with your Mac's IP
    }
  }
}
