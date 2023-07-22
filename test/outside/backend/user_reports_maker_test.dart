import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/user_report_data.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';

void main() {
  late MockBackend backend;
  late UserReportsMaker reportsMaker;

  setUp(() {
    backend = MockBackend();
    reportsMaker = UserReportsMaker(backend);
    when(backend.sendReport(any,
            barcode: anyNamed('barcode'), newsPieceId: anyNamed('newsPieceId')))
        .thenAnswer((_) async => Ok(None()));
  });

  test('report product', () async {
    final observer = _FakeObserver();
    reportsMaker.addObserver(observer);

    verifyZeroInteractions(backend);
    expect(observer.reportedBarcodes, isEmpty);

    final result = await reportsMaker.reportProduct('123', 'Naughty product!');
    expect(result.isOk, isTrue);

    verify(backend.sendReport('Naughty product!',
        barcode: '123', newsPieceId: null));
    verifyNoMoreInteractions(backend);
    expect(observer.reportedBarcodes, equals(['123']));
  });
}

class _FakeObserver implements UserReportsMakerObserver {
  final reportedBarcodes = <String>[];

  @override
  void onUserReportMade(UserReportData data) {
    reportedBarcodes.add((data as ProductReportData).barcode);
  }
}
