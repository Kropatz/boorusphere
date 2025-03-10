import 'dart:io';

class FeatureFlags {
  static bool enableDownload = !Platform.isLinux;
}