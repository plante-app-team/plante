import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/l10n/strings.dart';

class PhotosTaker {
  // TODO: files are big and other apps and activities are opened here - we need
  //       to handle a situation when a picture is taken/cropped but our app has died
  Future<Uri?> takeAndCropPhoto(BuildContext context) async {
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

      final croppedFile = await ImageCropper.cropImage(
          sourcePath: pickedFile.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
          androidUiSettings: AndroidUiSettings(
              toolbarTitle: context.strings.image_cropper_title,
              toolbarColor: Colors.green,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: true),
          iosUiSettings: const IOSUiSettings(
            minimumAspectRatio: 1,
          ));
      final path = croppedFile?.path;
      if (path == null) {
        Log.i('takeAndCropPhoto cropped image == null');
        return null;
      }
      Log.i('takeAndCropPhoto success: $path');
      return Uri.file(path);
    } finally {
      // External (3rd-party) activities can change what system controls looks like -
      // let's set our nice style back
      setSystemUIOverlayStyle();
    }
  }
}
