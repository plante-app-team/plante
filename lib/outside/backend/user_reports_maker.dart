import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

abstract class UserReportsMakerObserver {
  void onUserReportMade(String barcode);
}

class UserReportsMaker {
  final Backend _backend;
  final _observers = <UserReportsMakerObserver>[];

  UserReportsMaker(this._backend);

  Future<Result<None, BackendError>> reportProduct(
      String barcode, String reportText) async {
    final result = await _backend.sendReport(barcode, reportText);
    if (result.isOk) {
      _observers.forEach((o) => o.onUserReportMade(barcode));
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
