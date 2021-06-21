import 'package:flutter/material.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/ui_utils.dart';

/// Returns true if permission is obtained, false otherwise.
Future<bool> maybeRequestPermission(
    BuildContext context,
    PermissionsManager permissionsManager,
    PermissionKind permissionKind,
    String settingsDialogTitle) async {
  var permission = await permissionsManager.status(permissionKind);
  if (permission == PermissionState.granted) {
    return true;
  }

  if (permission == PermissionState.denied) {
    permission = await permissionsManager.request(permissionKind);
    if (permission != PermissionState.permanentlyDenied) {
      return permission == PermissionState.granted ||
          permission == PermissionState.limited;
    }
  }

  await showDoOrCancelDialog(
      context,
      settingsDialogTitle,
      context.strings.global_open_app_settings,
      permissionsManager.openAppSettings);
  permission = await permissionsManager.status(permissionKind);
  return permission == PermissionState.granted ||
      permission == PermissionState.limited;
}
