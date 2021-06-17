import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';

class CreateShopDialogResult {
  final String name;
  CreateShopDialogResult(this.name);
}

class CreateShopDialog extends StatefulWidget {
  const CreateShopDialog({Key? key}) : super(key: key);
  @override
  _CreateShopDialogState createState() => _CreateShopDialogState();
}

class _CreateShopDialogState extends State<CreateShopDialog> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        // Update!
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DialogPlante(
        contentPadding: const EdgeInsets.all(0),
        content: Column(children: [
          Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, right: 8),
              child: Row(textDirection: TextDirection.rtl, children: [
                InkWell(
                  key: const Key('map_hint_cancel'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: _cancel,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset('assets/cancel_circle.svg'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(context.strings.map_page_how_new_shop_is_called,
                        style: TextStyles.headline4)),
              ])),
          Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 10, top: 9, bottom: 16),
              child: Column(children: [
                InputFieldPlante(
                  key: const Key('new_shop_name_input'),
                  label: context.strings.map_page_how_new_shop_is_called_label,
                  hint: context.strings.map_page_how_new_shop_is_called_hint,
                  controller: _textController,
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ButtonFilledPlante.withText(
                        context.strings.global_add,
                        onPressed: _textController.text.trim().length >= 3
                            ? _onAddPressed
                            : null))
              ]))
        ]));
  }

  void _onAddPressed() {
    Navigator.of(context)
        .pop(CreateShopDialogResult(_textController.text.trim()));
  }

  void _cancel() {
    Navigator.of(context).pop();
  }
}
