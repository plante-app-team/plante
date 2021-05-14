import 'package:flutter/material.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_restorable.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

class InitProductPageModel {
  late final dynamic Function() onModelProduct;
  final Product initialProduct;
  final ProductRestorable productRestorable;
  final ProductsManager productsManager;

  Product get product => productRestorable.value;
  set product(Product value) {
    if (value.veganStatus != product.veganStatus) {
      // Vegan status changed
      if (value.veganStatus == VegStatus.positive) {
        value = value.rebuild((v) => v.vegetarianStatus = VegStatus.positive);
      }
    }
    if (value.vegetarianStatus != product.vegetarianStatus) {
      // Vegetarian status changed
      if (value.vegetarianStatus == VegStatus.negative) {
        value = value.rebuild((v) => v.veganStatus = VegStatus.negative);
      }
      if (value.vegetarianStatus == VegStatus.possible &&
          value.veganStatus == VegStatus.positive) {
        value = value.rebuild((v) => v.veganStatus = VegStatus.possible);
      }
      if (value.vegetarianStatus == VegStatus.unknown &&
          [VegStatus.positive, VegStatus.possible]
              .contains(value.veganStatus)) {
        value = value.rebuild((v) => v.veganStatus = VegStatus.unknown);
      }
    }
    productRestorable.value = value;
    onModelProduct.call();
  }

  bool loading = false;

  Map<String, RestorableProperty<Object?>> get restorableProperties => {
        'product': productRestorable,
      };

  InitProductPageModel(this.initialProduct, this.productsManager)
      : productRestorable = ProductRestorable(initialProduct);

  bool askForFrontPhoto() {
    return initialProduct.imageFront == null;
  }

  bool askForName() {
    return initialProduct.name == null || initialProduct.name!.trim().isEmpty;
  }

  bool askForBrand() {
    return initialProduct.brands == null || initialProduct.brands!.isEmpty;
  }

  bool askForCategories() {
    return initialProduct.categories == null ||
        initialProduct.categories!.isEmpty;
  }

  bool askForIngredientsData() {
    return initialProduct.ingredientsText == null ||
        initialProduct.ingredientsText!.trim().isEmpty ||
        initialProduct.imageIngredients == null;
  }

  bool askForIngredientsText() {
    return askForIngredientsData() && product.imageIngredients != null;
  }

  bool askForVeganStatus() {
    return initialProduct.veganStatus == null ||
        initialProduct.veganStatusSource == null ||
        initialProduct.veganStatusSource == VegStatusSource.open_food_facts;
  }

  bool askForVegetarianStatus() {
    return initialProduct.vegetarianStatus == null ||
        initialProduct.vegetarianStatusSource == null ||
        initialProduct.vegetarianStatusSource ==
            VegStatusSource.open_food_facts;
  }

  Future<String?> ocrIngredients(String langCode) async {
    final initialProductWithIngredientsPhoto = initialProduct.rebuildWithImage(
        ProductImageType.INGREDIENTS, product.imageIngredients);
    final ocrResult = await productsManager.updateProductAndExtractIngredients(
        initialProductWithIngredientsPhoto, langCode);

    if (ocrResult.isErr) {
      return null;
    }
    final ocrSuccess = ocrResult.unwrap();
    product = product.rebuildWithImage(
        ProductImageType.INGREDIENTS, ocrSuccess.product.imageIngredients);
    return ocrSuccess.ingredients;
  }

  bool canSaveProduct() {
    return ProductPageWrapper.isProductFilledEnoughForDisplay(product);
  }

  Future<bool> saveProduct(String langCode) async {
    loading = true;
    onModelProduct();
    try {
      final savedProduct = product.rebuild((e) => e
        ..veganStatusSource = VegStatusSource.community
        ..vegetarianStatusSource = VegStatusSource.community);
      final result =
          await productsManager.createUpdateProduct(savedProduct, langCode);
      if (result.isOk) {
        product = savedProduct;
      }
      return result.isOk;
    } finally {
      loading = false;
      onModelProduct();
    }
  }
}
