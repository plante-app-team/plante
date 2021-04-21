import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/log.dart';

/// OFF wrapper mainly needed for DI in tests
class OffApi {
  Future<off.ProductResult> getProduct(
      off.ProductQueryConfiguration configuration) async {
    return await off.OpenFoodAPIClient.getProduct(configuration);
  }

  Future<off.Status> saveProduct(off.User user, off.Product product) async {
    final result = await off.OpenFoodAPIClient.saveProduct(user, product);
    if (result.error != null) {
      Log.w("OffApi.saveProduct error: ${result.toJson()}");
    }
    return result;
  }

  Future<off.Status> addProductImage(off.User user, off.SendImage image) async {
    final result = await off.OpenFoodAPIClient.addProductImage(user, image);
    if (result.error != null) {
      Log.w("OffApi.addProductImage error: ${result.toJson()}");
    }
    return result;
  }

  Future<off.OcrIngredientsResult> extractIngredients(
      off.User user, String barcode, off.OpenFoodFactsLanguage language) async {
    final result = await off.OpenFoodAPIClient
        .extractIngredients(user, barcode, language);
    if (result.status != 0) {
      Log.w("OffApi.extractIngredients error: ${result.toJson()}");
    }
    return result;
  }
}
