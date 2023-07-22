import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/outside/backend/user_report_data.dart';
import 'package:plante/ui/report/report_dialog.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_user_reports_maker.dart';

void main() {
  late FakeUserReportsMaker reportsMaker;

  setUp(() {
    reportsMaker = FakeUserReportsMaker();
  });

  group('report made', () {
    const reportText = 'my report';
    final params = <Pair<ResCallback<Widget>, UserReportData>>[
      Pair(
          () => ReportDialog.forProduct(
              barcode: '123', reportsMaker: reportsMaker),
          ProductReportData(reportText, '123')),
      Pair(
          () => ReportDialog.forNewsPiece(
              newsPieceId: '111', reportsMaker: reportsMaker),
          NewsPieceReportData(reportText, '111')),
    ];

    params.forEach((param) {
      final createDialog = param.first;
      final expectedReport = param.second;

      testWidgets('report made with $expectedReport',
          (WidgetTester tester) async {
        final context = await tester.superPump(createDialog.call());

        await tester.superEnterText(
            find.byKey(const Key('report_text')), reportText);
        expect(reportsMaker.getReports_testing(), isEmpty);

        await tester.superTap(find.text(context.strings.global_send));
        expect(reportsMaker.getReports_testing(), equals([expectedReport]));
      });
    });
  });

  group('report text too short', () {
    final params = <ResCallback<Widget>>[
      () => ReportDialog.forProduct(barcode: '123', reportsMaker: reportsMaker),
      () => ReportDialog.forNewsPiece(
          newsPieceId: '111', reportsMaker: reportsMaker),
    ];

    params.forEach((param) {
      final createDialog = param;

      testWidgets('report text too short for $createDialog',
          (WidgetTester tester) async {
        final context = await tester.superPump(createDialog.call());

        final report = StringBuffer();
        while (report.length < ReportDialog.MIN_REPORT_LENGTH) {
          await tester.superEnterText(
              find.byKey(const Key('report_text')), report.toString());
          await tester.superTap(find.text(context.strings.global_send));

          if (report.length < ReportDialog.MIN_REPORT_LENGTH) {
            expect(reportsMaker.getReports_testing(), isEmpty);
          } else {
            expect(reportsMaker.getReports_testing(), isNot(isEmpty));
          }
          report.write('r');
        }
      });
    });
  });

  testWidgets('product report too short', (WidgetTester tester) async {
    final context = await tester.superPump(
        ReportDialog.forProduct(barcode: '123', reportsMaker: reportsMaker));

    final report = StringBuffer();
    while (report.length < ReportDialog.MIN_REPORT_LENGTH) {
      await tester.superEnterText(
          find.byKey(const Key('report_text')), report.toString());
      await tester.superTap(find.text(context.strings.global_send));

      if (report.length < ReportDialog.MIN_REPORT_LENGTH) {
        expect(reportsMaker.getReports_testing(), isEmpty);
      } else {
        expect(reportsMaker.getReports_testing(),
            equals([ProductReportData(report.toString(), '123')]));
      }
      report.write('r');
    }
  });
}
