import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VegStatusWarning extends StatelessWidget {
  final Color color;
  final TextStyle style;
  final String text;
  final bool? showWarningImage;
  const VegStatusWarning(
      {Key? key,
      required this.color,
      required this.text,
      this.showWarningImage,
      required this.style})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 8, right: 12, bottom: 8),
        child: showText(),
      ),
    );
  }

  Widget showText() {
    return showWarningImage != null && showWarningImage!
        ? RichText(
            key: const Key('veg_status_warning'),
            text: TextSpan(children: [
            WidgetSpan(
                child: SvgPicture.asset('assets/veg_status_warning_icon.svg')),
            const WidgetSpan(
                child: SizedBox(
              width: 5,
            )),
            TextSpan(text: text, style: style),
          ]))
        : Text(
            text,
            style: style,
          );
  }
}
