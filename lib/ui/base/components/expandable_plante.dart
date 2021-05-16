import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/l10n/strings.dart';

class ExpandablePlante extends StatelessWidget {
  final Widget collapsed;
  final Widget expanded;
  // ignore: avoid_field_initializers_in_const_classes
  final expandController = ExpandableController();
  ExpandablePlante({Key? key, required this.collapsed, required this.expanded})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      collapsed: Stack(children: [
        collapsed,
        Positioned.fill(
            child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x00ffffff), Color(0xffffffff)],
            ),
          ),
          child: InkWell(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            highlightColor: Colors.transparent,
            onTap: () {
              if (!expandController.expanded) {
                expandController.toggle();
              }
            },
            child: Align(
                alignment: Alignment.bottomCenter,
                child: _ExpandingButton(
                  text: context.strings.expandable_plante_expand,
                  svgAsset: 'assets/expand_down.svg',
                  onPressed: expandController.toggle,
                )),
          ),
        )),
      ]),
      expanded: Stack(children: [
        expanded,
        Positioned.fill(
            child: Align(
                alignment: Alignment.bottomCenter,
                child: _ExpandingButton(
                  text: context.strings.expandable_plante_collapse,
                  svgAsset: 'assets/expand_up.svg',
                  onPressed: expandController.toggle,
                )))
      ]),
      controller: expandController,
    );
  }
}

class _ExpandingButton extends StatelessWidget {
  final String text;
  final String svgAsset;
  final VoidCallback onPressed;
  const _ExpandingButton(
      {Key? key,
      required this.text,
      required this.svgAsset,
      required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 30,
        child: OutlinedButton(
            style: ButtonStyle(
                side: MaterialStateProperty.all<BorderSide>(
                    const BorderSide(style: BorderStyle.none)),
                overlayColor:
                    MaterialStateProperty.all(ColorsPlante.primaryDisabled),
                backgroundColor:
                    MaterialStateProperty.all(const Color(0xFFEBEFEC)),
                padding: MaterialStateProperty.all(
                    const EdgeInsets.only(left: 10, right: 6)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)))),
            onPressed: onPressed,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(text),
              const SizedBox(width: 4),
              SvgPicture.asset(svgAsset)
            ])));
  }
}
