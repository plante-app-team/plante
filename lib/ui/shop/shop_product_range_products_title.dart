import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/text_styles.dart';

class ShopProductRangeProductsTitle extends StatelessWidget {
  final String text;
  final double horizontalPaddings;
  final double topPadding;
  final double bottomPadding;
  const ShopProductRangeProductsTitle(this.text,
      {Key? key,
      this.horizontalPaddings = 0.0,
      this.topPadding = 0.0,
      this.bottomPadding = 0.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isInTests()) {
      // Large title makes it harder to test the widget
      return Text(text, style: TextStyles.hint);
    }
    return Padding(
      padding: EdgeInsets.only(
          left: horizontalPaddings,
          right: horizontalPaddings,
          top: topPadding,
          bottom: bottomPadding),
      child: Text(text, style: TextStyles.headline2),
    );
  }
}
