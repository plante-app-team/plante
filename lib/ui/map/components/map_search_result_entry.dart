import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/text_styles.dart';

class MapSearchResultEntry extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final double distanceMeters;
  final ArgResCallback<double, String> distanceMetersToStr;
  const MapSearchResultEntry({
    Key? key,
    required this.title,
    this.subtitle,
    required this.distanceMeters,
    required this.distanceMetersToStr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(distanceMetersToStr(distanceMeters),
            style: TextStyles.searchResultDistance),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyles.headline4),
          if (subtitle != null)
            Column(children: [const SizedBox(height: 4), subtitle!]),
        ]))
      ],
    );
  }
}
