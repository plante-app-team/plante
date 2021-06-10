import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/base/result.dart';
import 'package:plante/ui/crop/image_crop_page.dart';

class PhotosTaker {
  Future<Uri?> takeAndCropPhoto(
      BuildContext context, Directory outFolder) async {
    Log.i('takeAndCropPhoto start');
    final imagePicker = ImagePicker();

    try {
      Log.i('takeAndCropPhoto imagePicker.getImage');
      final pickedFile = await imagePicker.getImage(source: ImageSource.camera);
      if (pickedFile == null) {
        Log.i('takeAndCropPhoto pickedFile == null');
        return null;
      }
      Log.i('takeAndCropPhoto image is taken successfully');

      return cropPhoto(pickedFile.path, context, outFolder);
    } finally {
      // External (3rd-party) activities can change what system controls looks like -
      // let's set our nice style back
      setSystemUIOverlayStyle();
    }
  }

  Future<Uri?> cropPhoto(
      String photoPath, BuildContext context, Directory outFolder) async {
    final result = await Navigator.push<Uri>(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ImageCropPage(imagePath: photoPath, outFolder: outFolder)));
    if (result == null) {
      Log.i('cropPhoto finished without image');
    } else {
      Log.i('cropPhoto finished with image');
    }
    return result;
  }

  /// See https://pub.dev/packages/image_picker#handling-mainactivity-destruction-on-android
  /// Android, man!
  Future<Result<Uri, PlatformException>?> retrieveLostPhoto() async {
    final picker = ImagePicker();

    final LostData response = await picker.getLostData();
    if (response.isEmpty) {
      return null;
    }
    if (response.file != null) {
      return Ok(Uri.file(response.file!.path));
    } else {
      return Err(response.exception!);
    }
  }
}
