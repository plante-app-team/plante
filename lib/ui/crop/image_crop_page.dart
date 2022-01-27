import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:plante/base/base.dart';
import 'package:plante/base/size_int.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';

/// NOTE: this class is not tested at all, because the flutter_image_compress
/// package supports only mobile platforms.
class ImageCropPage extends PagePlante {
  static const _COMPRESSION_DEFAULT = 95;
  final String imagePath;
  final Directory outFolder;
  final bool withCircleUi;

  /// In pixels.
  /// Note that the final image might be larger than the target size,
  /// for more info:
  /// https://pub.dev/packages/flutter_image_compress#minwidth-and-minheight
  final SizeInt? targetSize;

  /// In pixels, smallest accepted image.
  /// The page will try to disallow cropping size
  /// smaller than the provided value.
  final SizeInt? minSize;

  /// JPEG image property
  final int compressQuality;
  const ImageCropPage(
      {Key? key,
      required this.imagePath,
      required this.outFolder,
      this.withCircleUi = false,
      this.targetSize,
      this.minSize,
      this.compressQuality = _COMPRESSION_DEFAULT})
      : super(key: key);

  @override
  _ImageCropPageState createState() => _ImageCropPageState();
}

class _ImageCropPageState extends PageStatePlante<ImageCropPage> {
  final _cropImageContainerKey = GlobalKey();
  late final _originalImage = UIValue<Uint8List?>(null, ref);
  SizeInt? _originalImageSize;
  CropController? _cropController;
  late final _loading = UIValue<bool>(true, ref);

  bool _modifyingCropArea = false;

  _ImageCropPageState() : super('ImageCropPage');

  @override
  void initState() {
    Log.i('ImageCropPage start');
    super.initState();
    _initAsync();
  }

  void _initAsync() async {
    Log.i('ImageCropPage loading image start, ${widget.imagePath}');
    _cropController = CropController();

    _originalImage.setValue(await FlutterImageCompress.compressWithFile(
      widget.imagePath,
      minWidth: _screenSize.width,
      minHeight: _screenSize.height,
      quality: widget.compressQuality,
    ));

    final imageData = await decodeImageFromList(_originalImage.cachedVal!);
    _originalImageSize = SizeInt(
      width: imageData.width,
      height: imageData.height,
    );

    if (mounted) {
      _loading.setValue(false);
    }

    if (_isImageTooSmall()) {
      Log.i('ImageCropPage closing because of too small image');
      showSnackBar(context.strings.image_crop_page_error_small_image, context);
      Navigator.of(context).pop(null);
      return;
    }

    Log.i('ImageCropPage loading image done');
  }

  bool _isImageTooSmall() {
    final minSize = widget.minSize;
    final imageSize = _originalImageSize;
    if (minSize == null || imageSize == null) {
      return false;
    }
    if (imageSize.width < minSize.width) {
      return true;
    }
    if (imageSize.height < minSize.height) {
      return true;
    }
    return false;
  }

  SizeInt get _screenSize {
    return SizeInt(
        width: window.physicalSize.width.toInt(),
        height: window.physicalSize.height.toInt());
  }

  @override
  void didUpdateWidget(ImageCropPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cropController = null;
    _loading.setValue(true);
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
            leftAction: const FabPlante.backBtnPopOnClick(),
            rightAction: Row(children: [
              _RotateButton(
                  color: TextStyles.headline4.color!, onTap: _rotate90),
              Padding(
                  padding: const EdgeInsets.only(
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
          Expanded(child: _cropWidget())
        ]),
        if (!isInTests())
          consumer((ref) => _loading.watch(ref)
              ? Positioned.fill(
                  child: Container(
                  color: const Color(0x70FFFFFF),
                  child: const Center(child: CircularProgressIndicator()),
                ))
              : const SizedBox()),
      ]),
    )));
  }

  Widget _cropWidget() {
    return consumer((ref) {
      final Widget result;
      final originalImage = _originalImage.watch(ref);
      if (originalImage != null) {
        result = Crop(
          // So that the widget will be recreated on image rotation
          key: UniqueKey(),
          image: originalImage,
          controller: _cropController,
          baseColor: Colors.white,
          initialSize: 0.5,
          onCropped: _onCropped,
          onMoved: _onCropAreaMoved,
          withCircleUi: widget.withCircleUi,
        );
      } else {
        result = const SizedBox.shrink();
      }
      return Container(key: _cropImageContainerKey, child: result);
    });
  }

  void _onCropAreaMoved(Rect rect) {
    // Let's see if the crop area smaller than the minimum image size, and
    // then enlarge it if it is indeed smaller.

    if (_modifyingCropArea) {
      // Recursive call, let's return - stack overflow will happen otherwise
      return;
    }
    final widgetSize =
        _cropImageContainerKey.currentContext?.findRenderObject() as RenderBox?;
    final imageSizePixels = _originalImageSize;
    final minSizePixels = widget.minSize;
    if (widgetSize == null ||
        imageSizePixels == null ||
        minSizePixels == null) {
      return;
    }

    final imagePixelsWidth = imageSizePixels.width.toDouble();
    final imagePixelsHeight = imageSizePixels.height.toDouble();
    final widgetWidth = widgetSize.size.width;
    final widgetHeight = widgetSize.size.height;
    final widgetAspectRatio = widgetWidth / widgetHeight;
    final imageAspectRatio = imagePixelsWidth / imagePixelsHeight;

    // Let's see whether the image fits the screen horizontally or vertically,
    // then let's figure out how much smaller/bigger than the
    // image is the widget.
    final double factor;
    if (widgetAspectRatio < imageAspectRatio) {
      factor = imagePixelsWidth / widgetWidth;
    } else {
      factor = imagePixelsHeight / widgetHeight;
    }

    // Now let's calculate the crop area size in pixels
    final cropAreaPixelsWidth = rect.width * factor;
    final cropAreaPixelsHeight = rect.height * factor;

    // If the crop area size in pixels is smaller than the min image size,
    // then let's calculate the factor needed to be applied to the crop
    // area to enlarge it.
    double? neededFactorWidth;
    double? neededFactorHeight;
    if (cropAreaPixelsWidth < minSizePixels.width) {
      neededFactorWidth = minSizePixels.width / cropAreaPixelsWidth;
    }
    if (cropAreaPixelsHeight < minSizePixels.height) {
      neededFactorHeight = minSizePixels.height / cropAreaPixelsHeight;
    }
    if (neededFactorWidth == null && neededFactorHeight == null) {
      return;
    }
    neededFactorWidth ??= 1;
    neededFactorHeight ??= 1;

    // Now let's enlarge the crop area!
    final newRect = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width * neededFactorWidth + 1,
        rect.height * neededFactorHeight + 1);
    try {
      _modifyingCropArea = true;
      _cropController?.rect = newRect;
    } finally {
      _modifyingCropArea = false;
    }
  }

  void _onDoneClick() async {
    Log.i('ImageCropPage crop start');
    _cropController!.crop();
    _loading.setValue(true);
  }

  void _onCropped(Uint8List image) async {
    Log.i('ImageCropPage crop finished, saving start');
    image = await _compressIfNeeded(image);

    final now = DateTime.now().millisecondsSinceEpoch;
    var file = File('${widget.outFolder.path}/$now');
    if (!(await file.exists())) {
      Log.i('ImageCropPage creating out file: $file');
      file = await file.create();
    }
    Log.i('ImageCropPage writing out file start, $file');
    await file.writeAsBytes(image);
    Log.i('ImageCropPage writing out file finished, $file');
    _loading.setValue(false);
    Navigator.of(context).pop(file.uri);
  }

  Future<Uint8List> _compressIfNeeded(Uint8List image) async {
    if (widget.targetSize != null ||
        widget.compressQuality != ImageCropPage._COMPRESSION_DEFAULT) {
      final targetSize = widget.targetSize ?? _screenSize;
      Log.i(
          'ImageCropPage compressing and downsizing, target: $targetSize, ${widget.compressQuality}');
      image = await FlutterImageCompress.compressWithList(
        image,
        minWidth: targetSize.width,
        minHeight: targetSize.height,
        quality: widget.compressQuality,
      );
    }
    return image;
  }

  void _rotate90() async {
    final originalImage = _originalImage.cachedVal;
    if (originalImage == null) {
      Log.w("ImageCropPage rotation couldn't start");
      return;
    }
    Uint8List? rotated;
    _loading.setValue(true);
    try {
      Log.i('ImageCropPage rotation start');
      rotated = await compute(_rotate90Impl, originalImage);
    } finally {
      if (rotated == null) {
        Log.w('ImageCropPage rotation failure');
        rotated = originalImage;
      } else {
        Log.i('ImageCropPage rotation success');
      }
    }
    final imageData = await decodeImageFromList(rotated);
    _originalImage.setValue(rotated);
    _originalImageSize = SizeInt(
      width: imageData.width,
      height: imageData.height,
    );
    _loading.setValue(false);
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
