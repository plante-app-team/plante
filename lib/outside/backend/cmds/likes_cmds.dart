import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

const LIKE_PRODUCT_CMD = 'like_product';
const UNLIKE_PRODUCT_CMD = 'unlike_product';

extension BackendExt on Backend {
  Future<Result<None, BackendError>> likeProduct(String barcode) =>
      executeCmd(_BackendLikeCmd(barcode));
  Future<Result<None, BackendError>> unlikeProduct(String barcode) =>
      executeCmd(_BackendUnlikeCmd(barcode));
}

class _BackendLikeCmd extends BackendCmd<None> {
  final String barcode;

  _BackendLikeCmd(this.barcode);

  @override
  Future<Result<None, BackendError>> execute() async {
    final response = await backendGet('/$LIKE_PRODUCT_CMD/', {
      'barcode': barcode,
    });
    return noneOrErrorFrom(response);
  }
}

class _BackendUnlikeCmd extends BackendCmd<None> {
  final String barcode;

  _BackendUnlikeCmd(this.barcode);

  @override
  Future<Result<None, BackendError>> execute() async {
    final response = await backendGet('/$UNLIKE_PRODUCT_CMD/', {
      'barcode': barcode,
    });
    return noneOrErrorFrom(response);
  }
}
