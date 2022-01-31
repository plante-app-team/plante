import 'dart:io';

import 'package:flutter/material.dart';

class UriImagePlante extends StatelessWidget {
  final Uri uri;
  final Map<String, String>? httpHeaders;
  final dynamic Function(ImageProvider image)? imageProviderCallback;

  const UriImagePlante(this.uri,
      {Key? key, this.imageProviderCallback, this.httpHeaders})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Image result;
    if (uri.isScheme('FILE')) {
      result = Image.file(File.fromUri(uri), fit: BoxFit.cover);
    } else {
      result = Image.network(uri.toString(),
          headers: httpHeaders,
          fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return const Center(child: CircularProgressIndicator());
      });
    }
    imageProviderCallback?.call(result.image);
    return result;
  }
}
