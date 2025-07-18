import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Request photos permission (for gallery access)
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  // Check if photos permission is granted
  static Future<bool> isPhotosPermissionGranted() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  // Request all necessary permissions
  static Future<Map<Permission, PermissionStatus>>
  requestAllPermissions() async {
    return await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();
  }

  // Check if all permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final camera = await isCameraPermissionGranted();
    final storage = await isStoragePermissionGranted();
    final photos = await isPhotosPermissionGranted();

    return camera && storage && photos;
  }

  // Open app settings if permissions are denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
