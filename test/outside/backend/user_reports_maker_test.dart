import 'package:plante/outside/backend/cmds/report_cmd.dart';
import 'package:plante/outside/backend/user_report_data.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late FakeAnalytics analytics;
  late UserReportsMaker reportsMaker;

  setUp(() {
    backend = FakeBackend();
    analytics = FakeAnalytics();
    reportsMaker = UserReportsMaker(backend, analytics);

    backend.setResponse_testing(REPORT_CMD, '{}');
  });

  test('report product', () async {
    final observer = _FakeObserver();
    reportsMaker.addObserver(observer);

    expect(backend.getRequestsMatching_testing(REPORT_CMD), isEmpty);
    expect(observer.reportedBarcodes, isEmpty);

    final result = await reportsMaker.reportProduct('123', 'Naughty product!');
    expect(result.isOk, isTrue);

    final request = backend.getRequestsMatching_testing(REPORT_CMD).first;
    expect(request.url.queryParameters['barcode'], equals('123'));
    expect(request.url.queryParameters['text'], equals('Naughty product!'));
    expect(request.url.queryParameters['newsPieceId'], isNull);
    expect(observer.reportedBarcodes, equals(['123']));
    expect(observer.reportedNewsPieces, isEmpty);

    expect(
        analytics.firstSentEvent('report_sent').second,
        equals({
          'barcode': '123',
          'report': 'Naughty product!',
        }));
  });

  test('report news piece', () async {
    final observer = _FakeObserver();
    reportsMaker.addObserver(observer);

    expect(backend.getRequestsMatching_testing(REPORT_CMD), isEmpty);
    expect(observer.reportedBarcodes, isEmpty);

    final result =
        await reportsMaker.reportNewsPiece('123', 'Naughty product!');
    expect(result.isOk, isTrue);

    final request = backend.getRequestsMatching_testing(REPORT_CMD).first;
    expect(request.url.queryParameters['barcode'], isNull);
    expect(request.url.queryParameters['text'], equals('Naughty product!'));
    expect(request.url.queryParameters['newsPieceId'], equals('123'));
    expect(observer.reportedBarcodes, isEmpty);
    expect(observer.reportedNewsPieces, equals(['123']));

    expect(
        analytics.firstSentEvent('report_sent').second,
        equals({
          'newsPieceId': '123',
          'report': 'Naughty product!',
        }));
  });
}

class _FakeObserver implements UserReportsMakerObserver {
  final reportedBarcodes = <String>[];
  final reportedNewsPieces = <String>[];

  @override
  void onUserReportMade(UserReportData data) {
    if (data is ProductReportData) {
      reportedBarcodes.add(data.barcode);
    } else if (data is NewsPieceReportData) {
      reportedNewsPieces.add(data.newsPieceId);
    } else {
      throw StateError('Unexpected data type: $data');
    }
  }
}
