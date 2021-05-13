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
    final imageProviderCallback = (provider) async {
      if (isInTests()) {
        // PaletteGenerator.fromImageProvider is not very friendly with
        // tests - it starts a timer and gives no way to stop it, tests
        // hate that.
        return;
      }
      final paletteGenerator =
          await PaletteGenerator.fromImageProvider(provider);
      if (dominantColor == null) {
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          setState(() {
            dominantColor = paletteGenerator.dominantColor?.color ??
                ColorsPlante.primaryDisabled;
          });
        });
      }
    };
    final img = photo(imageProviderCallback);

    return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
            overlayColor: MaterialStateProperty.all(ColorsPlante.splashColor),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 121,
              padding: EdgeInsets.all(6),
              child: Row(children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  padding: EdgeInsets.all(10),
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
                SizedBox(width: 16.5),
                Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      SizedBox(height: 10),
                      Text(product.name!,
                          style: TextStyles.headline2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 18),
                      VegStatusDisplayed(product: product, user: beholder)
                    ])),
              ]),
            ),
            onTap: onTap));
  }

  UriImagePlante? photo(
      dynamic Function(ImageProvider image) imageProviderCallback) {
    final uri;
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
