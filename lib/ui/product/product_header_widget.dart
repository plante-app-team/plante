import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/ui/base/components/licence_label.dart';
import 'package:plante/ui/base/text_styles.dart';

// ignore: always_use_package_imports
import '_product_images_helper.dart';

class ProductHeaderWidget extends StatelessWidget {
  final Product product;
  final ProductImageType imageType;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const ProductHeaderWidget(
      {Key? key,
      required this.product,
      required this.imageType,
      required this.onTap,
      this.onLongPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(children: [
        SizedBox(
            height: 161,
            width: double.infinity,
            child: ProductImagesHelper.productImageWidget(product, imageType)),
        Positioned.fill(
            child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x00ffffff), Color(0xC7192123)],
            ),
          ),
        )),
        Positioned.fill(
            child: Align(
                alignment: Alignment.topRight,
                child: LicenceLabel(
                  label: context.strings.display_product_page_off_licence,
                  darkBox: true,
                ))),
        Positioned.fill(
            child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 18),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (imageType == ProductImageType.FRONT)
                        SizedBox(
                            width: double.infinity,
                            child: Text(product.name!,
                                style: TextStyles.headline1White,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1)),
                      if (imageType == ProductImageType.FRONT &&
                          product.brands != null &&
                          product.brands!.isNotEmpty)
                        Row(children: [
                          Text(context.strings.display_product_page_brand,
                              style: TextStyles.normalWhite),
                          Text(product.brands!.join(', '),
                              style: TextStyles.normalWhite)
                        ]),
                    ])))),
        Positioned.fill(
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                )))
      ]),
    );
  }
}
