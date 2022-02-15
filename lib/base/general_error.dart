import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/products/products_obtainer.dart';

/// Should be used when a class can return errors, but the only errors
/// it can have are ones from the general list.
enum GeneralError {
  NETWORK,
  OTHER,
}

extension BackendErrorExt on BackendError {
  GeneralError toGeneral() {
    switch (errorKind) {
      case BackendErrorKind.NETWORK_ERROR:
        return GeneralError.NETWORK;
      default:
        return GeneralError.OTHER;
    }
  }
}

extension ProductsObtainerErrorExt on ProductsObtainerError {
  GeneralError toGeneral() {
    switch (this) {
      case ProductsObtainerError.NETWORK:
        return GeneralError.NETWORK;
      case ProductsObtainerError.OTHER:
        return GeneralError.OTHER;
    }
  }
}

extension ShopsManagerErrorExt on ShopsManagerError {
  GeneralError toGeneral() {
    switch (this) {
      case ShopsManagerError.NETWORK_ERROR:
        return GeneralError.NETWORK;
      case ShopsManagerError.OSM_SERVERS_ERROR:
        return GeneralError.OTHER;
      case ShopsManagerError.OTHER:
        return GeneralError.OTHER;
    }
  }
}
