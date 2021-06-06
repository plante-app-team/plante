import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/ui/crop/image_crop_page.dart';

class PhotosTaker {
  // TODO: files are big and other apps and activities are opened here - we need
  //       to handle a situation when a picture is taken/cropped but our app has died
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

      final result = await Navigator.push<Uri>(
          context,
          MaterialPageRoute(
              builder: (context) => ImageCropPage(
                  imagePath: pickedFile.path, outFolder: outFolder)));
      if (result == null) {
        Log.i('takeAndCropPhoto crop finished without image');
      } else {
        Log.i('takeAndCropPhoto crop finished with image');
      }
      return result;
    } finally {
      // External (3rd-party) activities can change what system controls looks like -
      // let's set our nice style back
      setSystemUIOverlayStyle();
    }
  }
}
