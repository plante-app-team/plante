import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/ui/base/ui_utils.dart';

/// Returns true if permission is obtained, false otherwise.
Future<bool> maybeRequestPermission(
    BuildContext context,
    PermissionsManager permissionsManager,
    PermissionKind permissionKind,
    String settingsDialogContent,
    String settingsDialogDoWhat,
    {String? settingsDialogCancelWhat,
    String? settingsDialogTitle}) async {
  var permission = await permissionsManager.status(permissionKind);
  if (permission == PermissionState.granted) {
    return true;
  }

  if (permission == PermissionState.denied) {
    permission = await permissionsManager.request(permissionKind);
    if (permission == PermissionState.permanentlyDenied && Platform.isIOS) {
      // On iOS we want to avoid prompting user to go to the settings
      // at all costs - the app won't pass the app review otherwise.
      //
      // On Android the situation is different - permissionsManager.status()
      // NEVER returns 'permanentlyDenied', even if the permission is truly
      // permanently denied by the user. The app has to request the permission
      // again to know it's permanently denied, and the app has no way of
      // knowing whether OS has shown the user the system permission grant-deny
      // dialog or not.
      return false;
    }

    if (permission != PermissionState.permanentlyDenied) {
      return permission == PermissionState.granted ||
          permission == PermissionState.limited;
    }
  }

  await showSystemDialog(context, settingsDialogContent, settingsDialogDoWhat,
      permissionsManager.openAppSettings,
      cancelWhat: settingsDialogCancelWhat, title: settingsDialogTitle);
  permission = await permissionsManager.status(permissionKind);
  return permission == PermissionState.granted ||
      permission == PermissionState.limited;
}
