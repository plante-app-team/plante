import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/checkbox_plante.dart';

class SettingsGeneralButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  const SettingsGeneralButton(
      {Key? key, required this.onTap, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SettingsButtonBase(
        onTap: onTap,
        child: Row(children: [Text(text, style: _settingsButton)]));
  }
}

class SettingsCheckButton extends StatelessWidget {
  final ArgCallback<bool> onChanged;
  final String text;
  final bool value;
  const SettingsCheckButton(
      {Key? key,
      required this.onChanged,
      required this.text,
      required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SettingsButtonBase(
        onTap: () {
          onChanged.call(!value);
        },
        child: Row(textDirection: TextDirection.rtl, children: [
          SizedBox(
              height: 16,
              child: CheckboxPlante(
                  value: value,
                  onChanged: (value) {
                    onChanged.call(value ?? false);
                  })),
          Expanded(child: Text(text, style: _settingsCheckButton)),
        ]));
  }
}

class _SettingsButtonBase extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _SettingsButtonBase(
      {Key? key, required this.onTap, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 54,
          minWidth: double.infinity,
        ),
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.only(
                    left: 24, right: 24, top: 16, bottom: 16),
                child: child)));
  }
}

const TextStyle _settingsButton = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: ColorsPlante.mainTextBlack);

const TextStyle _settingsCheckButton = TextStyle(
    fontFamily: 'OpenSans', fontSize: 16, color: ColorsPlante.mainTextBlack);
