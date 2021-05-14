import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class AddPhotoButtonPlante extends StatelessWidget {
  final Key? keyButton;
  final void Function()? onAddTap;
  final void Function()? onCancelTap;
  final Uri? existingPhoto;

  const AddPhotoButtonPlante(
      {Key? key,
      this.keyButton,
      required this.onAddTap,
      required this.onCancelTap,
      required this.existingPhoto})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(children: <Widget>[
      InkWell(
          key: keyButton,
          onTap: existingPhoto == null ? onAddTap : onCancelTap,
          child: Stack(children: [
            SvgPicture.asset('assets/camera_frame.svg'),
            if (existingPhoto == null)
              Positioned.fill(
                  child: Column(children: [
                const SizedBox(height: 20),
                SvgPicture.asset('assets/camera.svg'),
                const SizedBox(height: 3),
                Text(context.strings.global_add,
                    style: TextStyles.normalColored),
              ])),
            if (existingPhoto != null)
              Positioned.fill(
                  child: Stack(children: [
                UriImagePlante(existingPhoto!),
                Align(
                    alignment: Alignment.topRight,
                    child: SvgPicture.asset('assets/camera_cancel.svg'))
              ]))
          ])),
    ]);
  }
}
