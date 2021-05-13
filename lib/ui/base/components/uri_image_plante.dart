import 'dart:io';

import 'package:flutter/material.dart';

class UriImagePlante extends StatelessWidget {
  final Uri uri;
  final dynamic Function(ImageProvider image)? imageProviderCallback;

  const UriImagePlante(this.uri, {Key? key, this.imageProviderCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final result;
    if (uri.isScheme("FILE")) {
      result = Image.file(File.fromUri(uri));
    } else {
      result = Image.network(uri.toString(), fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(child: CircularProgressIndicator());
      });
    }
    imageProviderCallback?.call(result.image);
    return result;
  }
}
