import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_report_data.dart';

mixin UserReportsMakerObserver {
  void onUserReportMade(UserReportData data);
}

class UserReportsMaker {
  final Backend _backend;
  final _observers = <UserReportsMakerObserver>[];

  UserReportsMaker(this._backend);

  Future<Result<None, BackendError>> reportProduct(
      String barcode, String reportText) async {
    final result = await _backend.sendReport(reportText, barcode: barcode);
    if (result.isOk) {
      _observers.forEach(
          (o) => o.onUserReportMade(ProductReportData(reportText, barcode)));
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
