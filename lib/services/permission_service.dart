import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions
class PermissionService {
  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permission (for saving/reading images)
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request photo library permission
  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    return await Permission.storage.isGranted;
  }

  /// Request all required permissions at once
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();
  }

  /// Check and request camera permission with handling
  Future<PermissionResult> ensureCameraPermission() async {
    var status = await Permission.camera.status;
    
    if (status.isGranted) {
      return PermissionResult.granted;
    }
    
    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) {
        return PermissionResult.granted;
      }
    }
    
    if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    }
    
    return PermissionResult.denied;
  }

  /// Open app settings for manual permission granting
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

/// Enum for permission request results
enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

