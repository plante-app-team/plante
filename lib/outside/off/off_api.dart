import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;

/// OFF wrapper mainly needed for DI in tests
class OffApi {
  Future<off.ProductResult> getProduct(
      off.ProductQueryConfiguration configuration) {
    return off.OpenFoodAPIClient.getProduct(configuration);
  }

  Future<off.Status> saveProduct(off.User user, off.Product product) {
    return off.OpenFoodAPIClient.saveProduct(user, product);
  }

  Future<off.Status> addProductImage(off.User user, off.SendImage image) {
    return off.OpenFoodAPIClient.addProductImage(user, image);
  }

  Future<off.OcrIngredientsResult> extractIngredients(
      off.User user, String barcode, off.OpenFoodFactsLanguage language) {
    return off.OpenFoodAPIClient.extractIngredients(user, barcode, language);
  }
}
