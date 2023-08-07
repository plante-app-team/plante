import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

const REPORT_CMD = 'make_report';

extension BackendExt on Backend {
  Future<Result<None, BackendError>> sendReport(String reportText,
          {String? barcode, String? newsPieceId}) =>
      executeCmd(_ReportCmd(reportText, barcode, newsPieceId));
}

class _ReportCmd extends BackendCmd<None> {
  final String reportText;
  final String? barcode;
  final String? newsPieceId;

  _ReportCmd(this.reportText, this.barcode, this.newsPieceId);

  @override
  Future<Result<None, BackendError>> execute() async {
    if (barcode == null && newsPieceId == null) {
      throw ArgumentError('Nothing to report');
    }
    final params = <String, String>{};
    if (barcode != null) {
      params['barcode'] = barcode!;
    }
    if (newsPieceId != null) {
      params['newsPieceId'] = newsPieceId!;
    }
    params['text'] = reportText;
    final response = await backendGet('$REPORT_CMD/', params);
    return noneOrErrorFrom(response);
  }
}
