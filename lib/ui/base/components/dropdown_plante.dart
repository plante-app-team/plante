import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class DropdownPlante<T> extends StatefulWidget {
  final T? value;
  final List<T> values;
  final ArgResCallback<T, Widget> dropdownItemBuilder;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;

  const DropdownPlante(
      {Key? key,
      required this.value,
      required this.onChanged,
      required this.values,
      required this.dropdownItemBuilder,
      this.isExpanded = false})
      : super(key: key);

  @override
  _DropdownPlanteState createState() => _DropdownPlanteState<T>();
}

class _DropdownPlanteState<T> extends State<DropdownPlante<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
        clipBehavior: Clip.antiAlias,
        height: 46,
        decoration: ShapeDecoration(
          shape: OutlineInputBorder(
            gapPadding: 2,
            borderSide: BorderSide(
                color: widget.onChanged != null
                    ? ColorsPlante.primary
                    : ColorsPlante.primaryDisabled),
            borderRadius: const BorderRadius.all(Radius.circular(30)),
          ),
        ),
        child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 14),
            child: Stack(children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: SvgPicture.asset('assets/expand_down.svg',
                      width: 24, height: 24)),
              SizedBox(
                  width: double.infinity,
                  child: DropdownButton<T>(
                    value: widget.value,
                    underline: const SizedBox.shrink(),
                    icon: const SizedBox.shrink(),
                    style: TextStyles.normal,
                    isExpanded: widget.isExpanded,
                    onChanged: widget.onChanged == null
                        ? null
                        : (T? newValue) {
                            widget.onChanged?.call(newValue);
                          },
                    items: widget.values
                        .map((value) => DropdownMenuItem<T>(
                              value: value,
                              child: widget.dropdownItemBuilder.call(value),
                            ))
                        .toList(),
                  )),
            ])));
  }
}
