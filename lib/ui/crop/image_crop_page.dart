import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';

class ImageCropPage extends PagePlante {
  final String imagePath;
  final Directory outFolder;
  const ImageCropPage(
      {Key? key, required this.imagePath, required this.outFolder})
      : super(key: key);

  @override
  _ImageCropPageState createState() => _ImageCropPageState();
}

class _ImageCropPageState extends PageStatePlante<ImageCropPage> {
  Uint8List? _originalImage;
  CropController? _cropController;
  bool _loading = true;

  _ImageCropPageState() : super('ImageCropPage');

  @override
  void initState() {
    Log.i('ImageCropPage start');
    super.initState();
    _initAsync();
  }

  void _initAsync() async {
    Log.i('ImageCropPage loading image start, ${widget.imagePath}');
    _originalImage = await FlutterImageCompress.compressWithFile(
      widget.imagePath,
      minWidth: window.physicalSize.width.toInt(),
      minHeight: window.physicalSize.height.toInt(),
      quality: 95,
    );
    _cropController = CropController();
    Log.i('ImageCropPage loading image done');
    setState(() {
      if (mounted) {
        _loading = false;
      }
    });
  }

  @override
  void didUpdateWidget(ImageCropPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _originalImage = null;
    _cropController = null;
    setState(() {
      _loading = true;
    });
    _initAsync();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
      color: Colors.white,
      child: Stack(children: [
        Column(children: [
          HeaderPlante(
            title: Text(context.strings.image_crop_page_title,
                style: TextStyles.headline3),
            leftAction: FabPlante.backBtnPopOnClick(),
            rightAction: Row(children: [
              _RotateButton(
                  color: TextStyles.headline4.color!, onTap: _rotate90),
              Padding(
                  padding: const EdgeInsets.only(
                    // left: HeaderPlante.DEFAULT_ACTIONS_SIDE_PADDINGS / 2,
                    right: HeaderPlante.DEFAULT_ACTIONS_SIDE_PADDINGS / 2,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _onDoneClick,
                    child: Padding(
                        padding: const EdgeInsets.only(
                          left: HeaderPlante.DEFAULT_ACTIONS_SIDE_PADDINGS / 2,
                          right: HeaderPlante.DEFAULT_ACTIONS_SIDE_PADDINGS / 2,
                          top: HeaderPlante.DEFAULT_ACTIONS_SIDE_PADDINGS,
                          bottom: HeaderPlante.DEFAULT_ACTIONS_SIDE_PADDINGS,
                        ),
                        child: Text(context.strings.global_done,
                            style: TextStyles.headline4)),
                  )),
            ]),
            rightActionPadding: 0,
          ),
          Expanded(
              child: AnimatedSwitcher(
            duration: DURATION_DEFAULT,
            child: _cropWidget(),
          ))
        ]),
        if (_loading)
          Positioned.fill(
              child: Container(
            color: const Color(0x70FFFFFF),
            child: const Center(child: CircularProgressIndicator()),
          ))
      ]),
    )));
  }

  Widget _cropWidget() {
    if (_originalImage != null) {
      return Crop(
        // So that the widget will be recreated on image rotation
        key: UniqueKey(),
        image: _originalImage!,
        controller: _cropController,
        baseColor: Colors.white,
        initialSize: 0.5,
        onCropped: _onCropped,
      );
    }
    return const SizedBox.shrink();
  }

  void _onDoneClick() async {
    Log.i('ImageCropPage crop start');
    _cropController!.crop();
    setState(() {
      _loading = true;
    });
  }

  void _onCropped(Uint8List image) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    Log.i('ImageCropPage crop finished, saving start');
    var file = File('${widget.outFolder.path}/$now');
    if (!(await file.exists())) {
      Log.i('ImageCropPage creating out file: $file');
      file = await file.create();
    }
    Log.i('ImageCropPage writing out file start, $file');
    await file.writeAsBytes(image);
    Log.i('ImageCropPage writing out file finished, $file');
    setState(() {
      _loading = false;
    });
    Navigator.of(context).pop(file.uri);
  }

  void _rotate90() async {
    if (_originalImage == null) {
      Log.w("ImageCropPage rotation couldn't start");
      return;
    }
    Uint8List? rotated;
    final originalImage = _originalImage!;
    try {
      setState(() {
        _loading = true;
        _originalImage = null;
      });
      Log.i('ImageCropPage rotation start');
      rotated = await compute(_rotate90Impl, originalImage);
    } finally {
      setState(() {
        if (rotated != null) {
          Log.i('ImageCropPage rotation success');
          _originalImage = rotated;
        } else {
          Log.w('ImageCropPage rotation failure');
          _originalImage = originalImage;
        }
        _loading = false;
      });
    }
  }
}

Uint8List? _rotate90Impl(Uint8List image) {
  final originalImage = img.decodeImage(image);
  if (originalImage == null) {
    return null;
  }
  final fixedImage = img.copyRotate(originalImage, -90);
  return Uint8List.fromList(img.encodeJpg(fixedImage));
}

class _RotateButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  const _RotateButton({Key? key, required this.onTap, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.rotate_90_degrees_ccw,
                  color: color,
                  size: 24,
                ))));
  }
}
