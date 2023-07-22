import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_report_data.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';

class FakeUserReportsMaker implements UserReportsMaker {
  final _observers = <UserReportsMakerObserver>[];
  final _reports = <UserReportData>[];

  // ignore: non_constant_identifier_names
  List<UserReportData> getReports_testing() => _reports.toList();

  @override
  void addObserver(UserReportsMakerObserver observer) {
    _observers.add(observer);
  }

  @override
  void removeObserver(UserReportsMakerObserver observer) {
    _observers.remove(observer);
  }

  @override
  Future<Result<None, BackendError>> reportNewsPiece(
      String newsPieceId, String reportText) async {
    final report = NewsPieceReportData(reportText, newsPieceId);
    _reports.add(report);
    _observers.forEach((o) => o.onUserReportMade(report));
    return Ok(None());
  }

  @override
  Future<Result<None, BackendError>> reportProduct(
      String barcode, String reportText) async {
    final report = ProductReportData(reportText, barcode);
    _reports.add(report);
    _observers.forEach((o) => o.onUserReportMade(report));
    return Ok(None());
  }
}
