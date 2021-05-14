import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/base/components/veg_status_displayed.dart';
import 'package:plante/ui/base/text_styles.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final UserParams beholder;
  final VoidCallback onTap;

  const ProductCard(
      {Key? key,
      required this.product,
      required this.beholder,
      required this.onTap})
      : super(key: key);

  @override
  _ProductCardState createState() =>
      _ProductCardState(product, beholder, onTap);
}

class _ProductCardState extends State<ProductCard> {
  final Product product;
  final UserParams beholder;
  final VoidCallback onTap;
  Color? dominantColor;

  _ProductCardState(this.product, this.beholder, this.onTap);

  @override
  Widget build(BuildContext context) {
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
      setState(() {
        dominantColor = paletteGenerator.dominantColor?.color ??
            ColorsPlante.primaryDisabled;
      });
    };
    final img = photo(imageProviderCallback);

    return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
            overlayColor: MaterialStateProperty.all(ColorsPlante.splashColor),
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              height: 121,
              padding: const EdgeInsets.all(6),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: dominantColor ?? ColorsPlante.primaryDisabled,
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
                      const SizedBox(height: 10),
                      Text(product.name!,
                          style: TextStyles.headline2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 18),
                      VegStatusDisplayed(product: product, user: beholder)
                    ])),
              ]),
            )));
  }

  UriImagePlante? photo(
      dynamic Function(ImageProvider image) imageProviderCallback) {
    final Uri uri;
    if (product.imageFrontThumb != null) {
      uri = product.imageFrontThumb!;
    } else if (product.imageFront != null) {
      uri = product.imageFront!;
    } else {
      Log.w("Product in ProductCard doesn't have a front image: $product");
      return null;
    }
    return UriImagePlante(uri, imageProviderCallback: imageProviderCallback);
  }
}
