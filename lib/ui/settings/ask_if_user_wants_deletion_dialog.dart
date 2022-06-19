import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class AskIfUserWantsDeletion extends StatefulWidget {
  final UserParams user;
  const AskIfUserWantsDeletion({Key? key, required this.user})
      : super(key: key);

  @override
  _AskIfUserWantsDeletionState createState() => _AskIfUserWantsDeletionState();
}

class _AskIfUserWantsDeletionState extends State<AskIfUserWantsDeletion> {
  final _textController = TextEditingController();
  bool get _deletionAllowed => _textController.text.trim() == widget.user.name;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        // Update UI!
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DialogPlante(
      title: Text(context.strings.settings_account_deletion_dialog_title),
      content: Column(children: [
        Text(
            '${context.strings.settings_account_deletion_dialog_confirmation_request}"${widget.user.name ?? ''}"',
            style: TextStyles.normal),
        Text(context.strings.settings_account_deletion_dialog_warning,
            style: TextStyles.normalBold),
        InputFieldMultilinePlante(
            key: const Key('user_name_text'), controller: _textController),
      ]),
      actions: ButtonFilledPlante.withText(context.strings.global_done,
          onPressed: _deletionAllowed ? onDoneClick : null),
    );
  }

  void onDoneClick() async {
    Navigator.of(context).pop(true);
  }
}
