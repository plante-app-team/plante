import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/moderator_choice_reason.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class ModeratorCommentDialog extends StatelessWidget {
  final UserParams user;
  final Product product;
  final ArgCallback<String> onSourceUrlClick;
  const ModeratorCommentDialog(
      {Key? key,
      required this.user,
      required this.product,
      required this.onSourceUrlClick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DialogPlante(
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              context
                  .strings.display_product_page_moderator_comment_dialog_title,
              style: TextStyles.headline4),
          const SizedBox(height: 12),
          Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView(
                  shrinkWrap: true,
                  children: _vegStatusModeratorChoiceReasonWidgets(context)
                      .toList())),
          if (_vegStatusModeratorSourcesText() != null)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              Text(
                  context.strings
                      .display_product_page_moderator_comment_dialog_source,
                  style: TextStyles.headline4),
              const SizedBox(height: 12),
              SelectableLinkify(
                  style: TextStyles.normal,
                  linkStyle: TextStyles.url,
                  onOpen: (link) => () {
                        onSourceUrlClick.call(link.url);
                      },
                  text: _vegStatusModeratorSourcesText()!)
            ]),
        ]),
        actions: SizedBox(
            width: double.infinity,
            child: ButtonFilledPlante.withText(
              context
                  .strings.display_product_page_moderator_comment_dialog_close,
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            )));
  }

  Iterable<String> _vegStatusModeratorChoiceReasonTexts(BuildContext context) {
    return product.moderatorVeganChoiceReasons.map((e) => e.localize(context));
  }

  Iterable<Widget> _vegStatusModeratorChoiceReasonWidgets(
      BuildContext context) {
    final texts = _vegStatusModeratorChoiceReasonTexts(context);
    if (texts.length == 1) {
      return [Text(texts.first, style: TextStyles.normal)];
    }
    return texts.map((e) => Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('•', style: TextStyles.normal),
            Flexible(child: Text(e, style: TextStyles.normal)),
          ]),
          const SizedBox(height: 4),
        ]));
  }

  String? _vegStatusModeratorSourcesText() {
    return product.moderatorVeganSourcesText;
  }
}
