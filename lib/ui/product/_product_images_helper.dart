import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:plante/model/product.dart';

class ProductImagesHelper {
  static Image? productImageWidget(
      Product product, ProductImageType imageType) {
    final takenPhoto = _takenProductImageWidget(product, imageType);
    if (takenPhoto != null) {
      return takenPhoto;
    }
    final existingRemoteImage = _remoteProductImage(product, imageType);
    if (existingRemoteImage != null) {
      return existingRemoteImage;
    }
    return null;
  }

  static Image? _takenProductImageWidget(
      Product product, ProductImageType imageType) {
    final photoTaken = product.isImageFile(imageType);
    if (photoTaken) {
      final file = File.fromUri(product.imageUri(imageType)!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return null;
  }

  static Image? _remoteProductImage(
      Product product, ProductImageType imageType) {
    if (product.isImageRemote(imageType)) {
      return Image.network(product.imageUri(imageType)!.toString(),
          fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return const Center(child: CircularProgressIndicator());
      });
    }
    return null;
  }
}
