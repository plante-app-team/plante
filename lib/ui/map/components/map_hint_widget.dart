import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class MapHintWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onCanceledCallback;
  const MapHintWidget(this.text, {Key? key, this.onCanceledCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: ColorsPlante.primary,
      child: Padding(
        padding: const EdgeInsets.only(left: 27),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              InkWell(
                key: const Key('map_hint_cancel'),
                borderRadius: BorderRadius.circular(24),
                onTap: onCanceledCallback,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/cancel_circle_light.svg',
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(text, style: TextStyles.hintWhite)))),
            ]),
      ),
    );
  }
}
