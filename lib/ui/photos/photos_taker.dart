import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/size_int.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/ui/crop/image_crop_page.dart';
import 'package:plante/ui/photos/photo_requester.dart';

class PhotosTaker {
  static const _PREF_PHOTO_REQUESTER = 'PhotosTaker_PHOTO_REQUESTER';
  final SharedPreferencesHolder _prefsHolder;

  PhotosTaker(this._prefsHolder);

  Future<Uri?> takeAndCropPhoto(
      BuildContext context, Directory outFolder, PhotoRequester requester,
      {bool cropCircle = false, SizeInt? targetSize, SizeInt? minSize}) async {
    return await _pickAndCropPhoto(
        context, outFolder, ImageSource.camera, requester,
        cropCircle: cropCircle, targetSize: targetSize, minSize: minSize);
  }

  Future<Uri?> selectAndCropPhoto(
      BuildContext context, Directory outFolder, PhotoRequester requester,
      {bool cropCircle = false, SizeInt? targetSize, SizeInt? minSize}) async {
    return await _pickAndCropPhoto(
        context, outFolder, ImageSource.gallery, requester,
        cropCircle: cropCircle, targetSize: targetSize, minSize: minSize);
  }

  Future<Uri?> _pickAndCropPhoto(BuildContext context, Directory outFolder,
      ImageSource source, PhotoRequester requester,
      {required bool cropCircle,
      required SizeInt? targetSize,
      required SizeInt? minSize}) async {
    Log.i('_pickAndCropPhoto start');
    final prefs = await _prefsHolder.get();
    await prefs.setInt(_PREF_PHOTO_REQUESTER, requester.persistentCode);

    final imagePicker = ImagePicker();

    try {
      Log.i('_pickAndCropPhoto imagePicker.getImage');
      final pickedFile = await imagePicker.pickImage(source: source);
      if (pickedFile == null) {
        Log.i('_pickAndCropPhoto pickedFile == null');
        return null;
      }
      Log.i('_pickAndCropPhoto image is taken successfully');

      return cropPhoto(pickedFile.path, context, outFolder,
          cropCircle: cropCircle, targetSize: targetSize, minSize: minSize);
    } finally {
      // External (3rd-party) activities can change what system controls looks like -
      // let's set our nice style back
      setSystemUIOverlayStyle();
    }
  }

  Future<Uri?> cropPhoto(
      String photoPath, BuildContext context, Directory outFolder,
      {bool cropCircle = false, SizeInt? targetSize, SizeInt? minSize}) async {
    final result = await Navigator.push<Uri>(
        context,
        MaterialPageRoute(
            builder: (context) => ImageCropPage(
                imagePath: photoPath,
                outFolder: outFolder,
                withCircleUi: cropCircle,
                targetSize: targetSize,
                minSize: minSize)));
    if (result == null) {
      Log.i('cropPhoto finished without image');
    } else {
      Log.i('cropPhoto finished with image');
    }
    return result;
  }

  /// See https://pub.dev/packages/image_picker#handling-mainactivity-destruction-on-android
  /// Android, man!
  Future<Result<Uri, PlatformException>?> retrieveLostPhoto(
      PhotoRequester requester) async {
    if (!Platform.isAndroid) {
      return null;
    }

    final picker = ImagePicker();
    final response = await picker.retrieveLostData();
    if (response.isEmpty) {
      return null;
    }

    if (response.file == null) {
      return Err(response.exception!);
    }

    final prefs = await _prefsHolder.get();
    final retrievedPhotoSaver = prefs.getInt(_PREF_PHOTO_REQUESTER);
    if (requester.persistentCode != retrievedPhotoSaver) {
      Log.w('Lost photo requested by ${requester.persistentCode}, '
          'but the retrieved photo was saved by $retrievedPhotoSaver');
      return null;
    }

    return Ok(Uri.file(response.file!.path));
  }
}
