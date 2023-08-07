import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

const PRODUCT_SCAN_CMD = 'product_scan';

extension BackendExt on Backend {
  Future<Result<None, BackendError>> sendProductScan(String barcode) =>
      executeCmd(_ProductScanCmd(barcode));
}

class _ProductScanCmd extends BackendCmd<None> {
  final String barcode;
  _ProductScanCmd(this.barcode);

  @override
  Future<Result<None, BackendError>> execute() async {
    final params = <String, String>{};
    params['barcode'] = barcode;
    final response = await backendGet('$PRODUCT_SCAN_CMD/', params);
    return noneOrErrorFrom(response);
  }
}
