import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';

void main() {
  late MockBackend backend;
  late UserReportsMaker reportsMaker;

  setUp(() {
    backend = MockBackend();
    reportsMaker = UserReportsMaker(backend);
    when(backend.sendReport(any, any)).thenAnswer((_) async => Ok(None()));
  });

  test('report product', () async {
    final observer = _FakeObserver();
    reportsMaker.addObserver(observer);

    verifyZeroInteractions(backend);
    expect(observer.reportedBarcodes, isEmpty);

    final result = await reportsMaker.reportProduct('123', 'Naughty product!');
    expect(result.isOk, isTrue);

    verify(backend.sendReport('123', 'Naughty product!'));
    verifyNoMoreInteractions(backend);
    expect(observer.reportedBarcodes, equals(['123']));
  });
}

class _FakeObserver implements UserReportsMakerObserver {
  final reportedBarcodes = <String>[];

  @override
  void onUserReportMade(String barcode) {
    reportedBarcodes.add(barcode);
  }
}
