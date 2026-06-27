import 'dart:io';

class PlatformUtils {
  static String? getDataPath() {
    if (Platform.isLinux) {
      return ".local/share/boorusphere";
    }
    return null;
  }
}
