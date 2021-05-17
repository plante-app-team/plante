import 'package:flutter/material.dart';
import 'package:plante/ui/base/text_styles.dart';

class MenuItemPlante extends StatelessWidget {
  final String title;
  final String? description;
  const MenuItemPlante({Key? key, required this.title, this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyles.normalBold),
      if (description != null) Text(description!, style: TextStyles.hint)
    ]);
  }
}
