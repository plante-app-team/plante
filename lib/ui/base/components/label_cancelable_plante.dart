import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plante/ui/base/text_styles.dart';

class LabelCancelablePlante extends StatelessWidget {
  final String text;
  final VoidCallback onCanceledCallback;
  const LabelCancelablePlante(this.text,
      {Key? key, required this.onCanceledCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
          child: Text(text,
              style: TextStyles.normal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
      Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('label_cancelable_cancel'),
          onTap: onCanceledCallback,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SvgPicture.asset('assets/cancel_circle.svg'),
          ),
        ),
      )
    ]);
  }
}
