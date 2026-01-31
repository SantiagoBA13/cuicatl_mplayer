import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> requestMedia() async {
    if (!Platform.isAndroid) return true;

    final info = await DeviceInfoPlugin().androidInfo;
    final sdk = info.version.sdkInt;

    if (sdk >= 33) {
      final results = await [
        Permission.audio,         // READ_MEDIA_AUDIO
        Permission.notification,  // POST_NOTIFICATIONS
      ].request();

      return results[Permission.audio]?.isGranted ?? false;
    } else {
      final res = await Permission.storage.request(); // READ_EXTERNAL_STORAGE
      return res.isGranted;
    }
  }
}
