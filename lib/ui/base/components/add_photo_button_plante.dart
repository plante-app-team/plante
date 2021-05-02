import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/text_styles.dart';

class AddPhotoButtonPlante extends StatelessWidget {
  final Key? keyButton;
  final void Function()? onAddTap;
  final void Function()? onCancelTap;
  final Uri? existingPhoto;

  AddPhotoButtonPlante(
      {this.keyButton,
      required this.onAddTap,
      required this.onCancelTap,
      required this.existingPhoto});

  @override
  Widget build(BuildContext context) {
    return Wrap(children: <Widget>[
      InkWell(
          key: keyButton,
          child: Stack(children: [
            SvgPicture.asset("assets/camera_frame.svg"),
            if (existingPhoto == null)
              Positioned.fill(
                  child: Column(children: [
                SizedBox(height: 20),
                SvgPicture.asset("assets/camera.svg"),
                SizedBox(height: 3),
                Text(context.strings.global_add,
                    style: TextStyles.normalColored),
              ])),
            if (existingPhoto != null)
              Positioned.fill(
                  child: Stack(children: [
                existingPhoto!.isScheme("FILE")
                    ? Image.file(File.fromUri(existingPhoto!))
                    : Image.network(existingPhoto!.toString(),
                        loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(child: CircularProgressIndicator());
                      }),
                Align(
                    alignment: Alignment.topRight,
                    child: SvgPicture.asset("assets/camera_cancel.svg"))
              ]))
          ]),
          onTap: existingPhoto == null ? onAddTap : onCancelTap)
    ]);
  }
}
