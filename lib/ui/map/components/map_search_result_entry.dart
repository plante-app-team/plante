import 'package:flutter/material.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';

class MapSearchResultEntry extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double distanceMeters;
  const MapSearchResultEntry(
      {Key? key,
      required this.title,
      this.subtitle,
      required this.distanceMeters})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String distanceStr;
    if (distanceMeters < 1000) {
      distanceStr =
          '${distanceMeters.round()} ${context.strings.global_meters}';
    } else {
      final distanceKms = distanceMeters / 1000;
      distanceStr =
          '${distanceKms.toStringAsFixed(1)} ${context.strings.global_kilometers}';
    }
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(distanceStr, style: TextStyles.searchResultDistance),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyles.headline4),
          if (subtitle != null)
            Column(children: [
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyles.hint),
            ]),
        ]))
      ],
    );
  }
}
