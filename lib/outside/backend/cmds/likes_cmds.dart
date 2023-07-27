import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

extension BackendLikes on Backend {
  Future<Result<None, BackendError>> likeProduct(String barcode) =>
      executeCmd(BackendLikeCmd(barcode));
  Future<Result<None, BackendError>> unlikeProduct(String barcode) =>
      executeCmd(BackendUnlikeCmd(barcode));
}

class BackendLikeCmd extends BackendCmd<None> {
  final String barcode;

  BackendLikeCmd(this.barcode);

  @override
  Future<Result<None, BackendError>> execute() async {
    final response = await backendGet('/like_product/', {
      'barcode': barcode,
    });
    return noneOrErrorFrom(response);
  }
}

class BackendUnlikeCmd extends BackendCmd<None> {
  final String barcode;

  BackendUnlikeCmd(this.barcode);

  @override
  Future<Result<None, BackendError>> execute() async {
    final response = await backendGet('/unlike_product/', {
      'barcode': barcode,
    });
    return noneOrErrorFrom(response);
  }
}
