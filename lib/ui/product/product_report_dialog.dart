import 'package:flutter/material.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/l10n/strings.dart';

class ProductReportDialog extends StatefulWidget {
  final String barcode;
  final Backend backend;
  const ProductReportDialog(
      {Key? key, required this.barcode, required this.backend})
      : super(key: key);

  @override
  _ProductReportDialogState createState() => _ProductReportDialogState();
}

class _ProductReportDialogState extends State<ProductReportDialog> {
  bool _loading = false;
  final _reportTextController = TextEditingController();
  bool get _reportSendAllowed => _reportTextController.text.trim().length > 3;

  @override
  void initState() {
    super.initState();
    _reportTextController.addListener(() {
      setState(() {
        // Update UI!
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DialogPlante(
      title: Text(context.strings.product_report_dialog_title),
      content: Column(children: [
        if (_loading) const CircularProgressIndicator(),
        InputFieldMultilinePlante(
            key: const Key('report_text'),
            maxLines: 5,
            controller: _reportTextController),
      ]),
      actions: ButtonFilledPlante.withText(
          context.strings.product_report_dialog_send,
          onPressed: _reportSendAllowed && !_loading ? onSendClick : null),
    );
  }

  void onSendClick() async {
    setState(() {
      _loading = true;
    });
    try {
      final result = await widget.backend
          .sendReport(widget.barcode, _reportTextController.text);
      if (result.isOk) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.strings.product_report_dialog_report_sent)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.strings.global_something_went_wrong)));
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
