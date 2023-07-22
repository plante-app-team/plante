import 'package:flutter/foundation.dart';

sealed class UserReportData {
  final String reportText;
  UserReportData(this.reportText);
}

@immutable
class ProductReportData extends UserReportData {
  final String barcode;
  ProductReportData(String reportText, this.barcode) : super(reportText);

  @override
  int get hashCode => Object.hash(reportText, barcode);

  @override
  bool operator ==(Object other) =>
      other is ProductReportData &&
      reportText == other.reportText &&
      barcode == other.barcode;

  @override
  String toString() => 'ProductReportData($barcode: $reportText)';
}

@immutable
class NewsPieceReportData extends UserReportData {
  final String newsPieceId;
  NewsPieceReportData(String reportText, this.newsPieceId) : super(reportText);

  @override
  int get hashCode => Object.hash(reportText, newsPieceId);

  @override
  bool operator ==(Object other) =>
      other is NewsPieceReportData &&
      reportText == other.reportText &&
      newsPieceId == other.newsPieceId;

  @override
  String toString() => 'NewsPieceReportData($newsPieceId: $reportText)';
}
