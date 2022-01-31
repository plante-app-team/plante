import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';

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
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(alignment: Alignment.center, children: [
              SvgPicture.asset('assets/add_photo.svg'),
              SvgPicture.asset('assets/add_photo_background.svg'),
              if (existingPhoto != null)
                Positioned.fill(
                    child: Stack(children: [
                  Positioned.fill(child: UriImagePlante(existingPhoto!)),
                  Padding(
                      padding: const EdgeInsets.all(2),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: SvgPicture.asset('assets/cancel_circle.svg'),
                      ))
                ]))
            ])),
      ),
    ]);
  }
}
