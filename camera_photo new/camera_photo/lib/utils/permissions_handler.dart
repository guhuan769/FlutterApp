
// lib/utils/permissions_handler.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionsHandler {
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }
}