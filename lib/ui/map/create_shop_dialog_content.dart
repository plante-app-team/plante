import 'package:flutter/material.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';

class CreateShopDialogResult {
  final String name;
  CreateShopDialogResult(this.name);
}

class CreateShopDialogContent extends StatefulWidget {
  const CreateShopDialogContent({Key? key}) : super(key: key);
  @override
  _CreateShopDialogContentState createState() =>
      _CreateShopDialogContentState();
}

class _CreateShopDialogContentState extends State<CreateShopDialogContent> {
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
    return Column(children: [
      Text(context.strings.map_page_how_new_shop_is_called,
          style: TextStyles.headline4),
      const SizedBox(height: 24),
      InputFieldPlante(
        label: context.strings.map_page_how_new_shop_is_called_label,
        hint: context.strings.map_page_how_new_shop_is_called_hint,
        controller: _textController,
      ),
      const SizedBox(height: 16),
      ButtonFilledPlante.withText(context.strings.global_add,
          onPressed:
              _textController.text.trim().length >= 3 ? _onAddPressed : null)
    ]);
  }

  void _onAddPressed() {
    Navigator.of(context)
        .pop(CreateShopDialogResult(_textController.text.trim()));
  }
}
