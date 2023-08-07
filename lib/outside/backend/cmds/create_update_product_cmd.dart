import 'package:plante/base/result.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

const CREATE_UPDATE_PRODUCT_CMD = 'create_update_product';

extension BackendExt on Backend {
  Future<Result<None, BackendError>> createUpdateProduct(String barcode,
          {VegStatus? veganStatus, List<LangCode>? changedLangs}) =>
      executeCmd(_CreateUpdateProductCmd(barcode, veganStatus, changedLangs));
}

class _CreateUpdateProductCmd extends BackendCmd<None> {
  final String barcode;
  final VegStatus? veganStatus;
  final List<LangCode>? changedLangs;

  _CreateUpdateProductCmd(this.barcode, this.veganStatus, this.changedLangs);

  @override
  Future<Result<None, BackendError>> execute() async {
    final params = <String, dynamic>{};
    params['barcode'] = barcode;
    params['edited'] = 'true';
    if (veganStatus != null) {
      params['veganStatus'] = veganStatus!.name;
    }
    if (changedLangs != null && changedLangs!.isNotEmpty) {
      params['langs'] = changedLangs!.map((e) => e.name).toList();
    }
    final response = await backendGet('$CREATE_UPDATE_PRODUCT_CMD/', params);
    return noneOrErrorFrom(response);
  }
}
