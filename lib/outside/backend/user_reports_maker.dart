import 'package:plante/base/result.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/cmds/report_cmd.dart';
import 'package:plante/outside/backend/user_report_data.dart';

mixin UserReportsMakerObserver {
  void onUserReportMade(UserReportData data);
}

class UserReportsMaker {
  final Backend _backend;
  final _observers = <UserReportsMakerObserver>[];
  final Analytics _analytics;

  UserReportsMaker(this._backend, this._analytics);

  Future<Result<None, BackendError>> reportProduct(
      String barcode, String reportText) async {
    final result = await _backend.sendReport(reportText, barcode: barcode);
    if (result.isOk) {
      _observers.forEach(
          (o) => o.onUserReportMade(ProductReportData(reportText, barcode)));
      _analytics
          .sendEvent('report_sent', {'barcode': barcode, 'report': reportText});
    }
    return result;
  }

  Future<Result<None, BackendError>> reportNewsPiece(
      String newsPieceId, String reportText) async {
    final result =
        await _backend.sendReport(reportText, newsPieceId: newsPieceId);
    if (result.isOk) {
      _observers.forEach((o) =>
          o.onUserReportMade(NewsPieceReportData(reportText, newsPieceId)));
      _analytics.sendEvent(
          'report_sent', {'newsPieceId': newsPieceId, 'report': reportText});
    }
    return result;
  }

  void addObserver(UserReportsMakerObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(UserReportsMakerObserver observer) {
    _observers.remove(observer);
  }
}
