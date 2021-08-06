import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/base/components/veg_status_displayed.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final UserParams beholder;
  final String? hint;
  final VoidCallback onTap;
  final Widget? extraContentMiddle;
  final Widget? extraContentBottom;

  const ProductCard(
      {Key? key,
      required this.product,
      required this.beholder,
      this.hint,
      required this.onTap,
      this.extraContentMiddle,
      this.extraContentBottom})
      : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  Color? dominantColor;

  _ProductCardState();

  @override
  Widget build(BuildContext context) {
    Uri? uri;
    // ignore: prefer_function_declarations_over_variables
    final imageProviderCallback = (ImageProvider provider) async {
      if (dominantColor != null || isInTests()) {
        // PaletteGenerator.fromImageProvider is not very friendly with
        // tests - it starts a timer and gives no way to stop it, tests
        // hate that.
        return;
      }
      final paletteGenerator =
          await PaletteGenerator.fromImageProvider(provider);
      if (mounted) {
        setState(() {
          dominantColor = paletteGenerator.dominantColor?.color ??
              ColorsPlante.primaryDisabled;
          _dominantColorsCache[uri!] = dominantColor!;
        });
      }
    };
    final img = photo(imageProviderCallback);
    uri = img?.uri;
    Color defaultDominantColor = ColorsPlante.primaryDisabled;
    if (uri != null && _dominantColorsCache.containsKey(uri)) {
      defaultDominantColor = _dominantColorsCache[uri]!;
    }

    return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
            overlayColor: MaterialStateProperty.all(ColorsPlante.splashColor),
            borderRadius: BorderRadius.circular(8),
            onTap: widget.onTap,
            child: Container(
                padding: const EdgeInsets.all(6),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AnimatedContainer(
                      height: 109,
                      duration: DURATION_DEFAULT,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: dominantColor ?? defaultDominantColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: img,
                          )),
                    ),
                    const SizedBox(width: 16.5),
                    Flexible(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const SizedBox(height: 2),
                          Text(widget.product.name ?? '???',
                              style: TextStyles.normalBold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (widget.hint != null)
                            Column(children: [
                              const SizedBox(height: 4),
                              Text(widget.hint!, style: TextStyles.hint),
                            ]),
                          const SizedBox(height: 8),
                          VegStatusDisplayed(
                              product: widget.product, user: widget.beholder),
                          AnimatedSize(
                              duration: DURATION_DEFAULT,
                              vsync: this,
                              child: widget.extraContentMiddle ??
                                  const SizedBox.shrink()),
                        ])),
                  ]),
                  AnimatedSize(
                      duration: DURATION_DEFAULT,
                      vsync: this,
                      child:
                          widget.extraContentBottom ?? const SizedBox.shrink())
                ]))));
  }

  UriImagePlante? photo(
      dynamic Function(ImageProvider image) imageProviderCallback) {
    final Uri uri;
    if (widget.product.imageFrontThumb != null) {
      uri = widget.product.imageFrontThumb!;
    } else if (widget.product.imageFront != null) {
      uri = widget.product.imageFront!;
    } else {
      Log.w("Product in ProductCard doesn't have a front image: "
          '${widget.product}');
      return null;
    }
    return UriImagePlante(uri, imageProviderCallback: imageProviderCallback);
  }
}

final _dominantColorsCache = <Uri, Color>{};
