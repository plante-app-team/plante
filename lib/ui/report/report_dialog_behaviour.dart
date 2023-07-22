import 'package:flutter/material.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';

sealed class ReportDialogBehaviour {
  Future<Result<None, GeneralError>> sendReport(String text);
  String getReportDialogTitle(BuildContext context);
}

class ReportDialogProductBehaviour extends ReportDialogBehaviour {
  final String barcode;
  final UserReportsMaker reportsMaker;

  ReportDialogProductBehaviour(this.barcode, this.reportsMaker);

  @override
  String getReportDialogTitle(BuildContext context) =>
      context.strings.product_report_dialog_title;

  @override
  Future<Result<None, GeneralError>> sendReport(String text) async {
    final result = await reportsMaker.reportProduct(barcode, text);
    if (result.isOk) {
      return Ok(None());
    } else {
      return Err(result.unwrapErr().toGeneral());
    }
  }
}

class ReportDialogNewsPieceBehaviour extends ReportDialogBehaviour {
  final String newsPieceId;
  final UserReportsMaker reportsMaker;

  ReportDialogNewsPieceBehaviour(this.newsPieceId, this.reportsMaker);

  @override
  String getReportDialogTitle(BuildContext context) =>
      context.strings.news_piece_report_dialog_title;

  @override
  Future<Result<None, GeneralError>> sendReport(String text) async {
    final result = await reportsMaker.reportNewsPiece(newsPieceId, text);
    if (result.isOk) {
      return Ok(None());
    } else {
      return Err(result.unwrapErr().toGeneral());
    }
  }
}
