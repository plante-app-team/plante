import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/report/report_dialog_behaviour.dart';

class ReportDialog extends StatefulWidget {
  static const MIN_REPORT_LENGTH = 4;
  final ReportDialogBehaviour behaviour;

  ReportDialog.forProduct(
      {required String barcode, required UserReportsMaker reportsMaker})
      : this._(ReportDialogProductBehaviour(barcode, reportsMaker));
  ReportDialog.forNewsPiece(
      {required String newsPieceId, required UserReportsMaker reportsMaker})
      : this._(ReportDialogNewsPieceBehaviour(newsPieceId, reportsMaker));

  const ReportDialog._(this.behaviour, {Key? key}) : super(key: key);

  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  bool _loading = false;
  final _reportTextController = TextEditingController();
  bool get _reportSendAllowed =>
      _reportTextController.text.trim().length >=
      ReportDialog.MIN_REPORT_LENGTH;

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
      title: Text(widget.behaviour.getReportDialogTitle(context)),
      content: Column(children: [
        if (_loading) const CircularProgressIndicator(),
        InputFieldMultilinePlante(
            key: const Key('report_text'),
            maxLines: 5,
            controller: _reportTextController),
      ]),
      actions: ButtonFilledPlante.withText(context.strings.global_send,
          onPressed: _reportSendAllowed && !_loading ? onSendClick : null),
    );
  }

  void onSendClick() async {
    setState(() {
      _loading = true;
    });
    try {
      final result =
          await widget.behaviour.sendReport(_reportTextController.text);
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
