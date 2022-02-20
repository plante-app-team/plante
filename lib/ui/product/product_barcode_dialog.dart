import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';

class ProductBarcodeDialog extends StatefulWidget {
  final Product product;
  const ProductBarcodeDialog({Key? key, required this.product})
      : super(key: key);

  @override
  _ProductBarcodeDialogState createState() => _ProductBarcodeDialogState();
}

class _ProductBarcodeDialogState extends State<ProductBarcodeDialog> {
  @override
  Widget build(BuildContext context) {
    return DialogPlante(
      title: Text(widget.product.name ?? ''),
      content: Column(children: [
        SelectableText(widget.product.barcode, style: TextStyles.normalBold)
      ]),
      actions: ButtonFilledPlante.withText(context.strings.global_copy,
          onPressed: _onCopyPressed),
    );
  }

  void _onCopyPressed() async {
    await Clipboard.setData(ClipboardData(text: widget.product.barcode));
    showSnackBar(context.strings.global_copied_to_clipboard, context);
  }
}
