import 'package:permission_handler/permission_handler.dart' as wrapped;

/// See [wrapped.PermissionStatus].
enum PermissionState {
  granted,
  denied,
  restricted,
  limited,
  permanentlyDenied,
}

enum PermissionKind { CAMERA }

/// Wrapper around the permission_handler lib mainly for testing purposes
class PermissionsManager {
  Future<PermissionState> status(PermissionKind permission) async {
    final result = await permission.wrappedVal.status;
    return result.converted;
  }

  Future<PermissionState> request(PermissionKind permission) async {
    final result = await permission.wrappedVal.request();
    return result.converted;
  }

  Future<bool> openAppSettings() async {
    return await wrapped.openAppSettings();
  }
}

extension _WappedPermissionType on PermissionKind {
  wrapped.Permission get wrappedVal {
    switch (this) {
      case PermissionKind.CAMERA:
        return wrapped.Permission.camera;
    }
  }
}

extension _PermissionStatus on wrapped.PermissionStatus {
  PermissionState get converted {
    switch (this) {
      case wrapped.PermissionStatus.granted:
        return PermissionState.granted;
      case wrapped.PermissionStatus.denied:
        return PermissionState.denied;
      case wrapped.PermissionStatus.restricted:
        return PermissionState.restricted;
      case wrapped.PermissionStatus.limited:
        return PermissionState.limited;
      case wrapped.PermissionStatus.permanentlyDenied:
        return PermissionState.permanentlyDenied;
    }
  }
}
