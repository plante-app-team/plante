import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/components/add_photo_button_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/veg_status_selection_panel.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/photos_taker.dart';

import 'init_product_page_model.dart';

typedef DoneCallback = void Function();
typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class InitProductPage extends StatefulWidget {
  final Product initialProduct;
  final String? title;
  final ProductUpdatedCallback? productUpdatedCallback;
  final VoidCallback? doneCallback;

  const InitProductPage(this.initialProduct,
      {Key? key, this.title, this.productUpdatedCallback, this.doneCallback})
      : super(key: key);

  @override
  _InitProductPageState createState() => _InitProductPageState(
      initialProduct, productUpdatedCallback, doneCallback);
}

class _InitProductPageState extends State<InitProductPage>
    with RestorationMixin {
  final InitProductPageModel model;
  final ProductUpdatedCallback? productUpdatedCallback;
  final VoidCallback? doneCallback;

  bool ocrInProgress = false;

  final TextEditingController nameTextController = TextEditingController();
  final TextEditingController brandTextController = TextEditingController();
  final TextEditingController categoriesTextController =
      TextEditingController();
  final TextEditingController ingredientsTextController =
      TextEditingController();

  _InitProductPageState(
      Product initialProduct, this.productUpdatedCallback, this.doneCallback)
      : model = InitProductPageModel(
            initialProduct, GetIt.I.get<ProductsManager>()) {
    model.onModelProduct = onStateUpdated;
  }

  void onStateUpdated() {
    if (!mounted) {
      return;
    }
    setState(() {
      // Update!
    });
  }

  @override
  String? get restorationId => "init_product_page";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    for (final property in model.restorableProperties.entries) {
      registerForRestoration(property.value, property.key);
    }

    nameTextController.addListener(() {
      model.product =
          model.product.rebuild((e) => e.name = nameTextController.text);
    });
    brandTextController.addListener(() {
      model.product = model.product.rebuild(
          (e) => e.brands = _textToListBuilder(brandTextController.text));
    });
    categoriesTextController.addListener(() {
      model.product = model.product.rebuild((e) =>
          e.categories = _textToListBuilder(categoriesTextController.text));
    });
    ingredientsTextController.addListener(() {
      model.product = model.product
          .rebuild((e) => e.ingredientsText = ingredientsTextController.text);
    });
  }

  ListBuilder<String> _textToListBuilder(String text) => ListBuilder(
      text.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Stack(children: [
      SingleChildScrollView(
          key: Key("content"),
          child: Stack(children: [
            Container(
                padding: EdgeInsets.only(left: 24, right: 24),
                child: Column(children: [
                  SizedBox(height: 45),
                  SizedBox(
                      width: double.infinity,
                      child: Text(
                        context.strings.global_app_name,
                        style: TextStyles.branding,
                        textAlign: TextAlign.center,
                      )),
                  SizedBox(height: 36),
                  SizedBox(
                      width: double.infinity,
                      child: Text(
                        widget.title ?? context.strings.init_product_page_title,
                        style: TextStyles.headline1,
                        textAlign: TextAlign.left,
                      )),
                  SizedBox(height: 24),
                  if (model.askForFrontPhoto())
                    Column(key: Key("front_photo_group"), children: [
                      SizedBox(
                          width: double.infinity,
                          child: Text(
                            context.strings.init_product_page_take_front_photo,
                            style: TextStyles.headline4,
                            textAlign: TextAlign.left,
                          )),
                      SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          child: AddPhotoButtonPlante(
                            keyButton: Key("front_photo"),
                            onAddTap: takeFrontPhoto,
                            onCancelTap: removeFrontPhoto,
                            existingPhoto: model.product.imageFront,
                          )),
                      SizedBox(height: 24),
                    ]),
                  if (model.askForName())
                    Column(key: Key("name_group"), children: [
                      InputFieldPlante(
                        key: Key("name"),
                        label: context.strings.init_product_page_product_name,
                        controller: nameTextController,
                      ),
                      SizedBox(height: 10),
                    ]),
                  if (model.askForBrand())
                    Column(key: Key("brand_group"), children: [
                      InputFieldPlante(
                        key: Key("brand"),
                        label: context.strings.init_product_page_brand_optional,
                        controller: brandTextController,
                      ),
                      SizedBox(height: 10),
                    ]),
                  if (model.askForCategories())
                    Column(key: Key("categories_group"), children: [
                      InputFieldPlante(
                        key: Key("categories"),
                        label: context
                            .strings.init_product_page_categories_optional,
                        hint: context.strings.init_product_page_categories_hint,
                        controller: categoriesTextController,
                      ),
                      SizedBox(height: 24),
                    ]),
                  if (model.askForIngredientsData())
                    Column(key: Key("ingredients_group"), children: [
                      SizedBox(
                          width: double.infinity,
                          child: Text(
                            context.strings
                                .init_product_page_take_ingredients_photo,
                            style: TextStyles.headline4,
                            textAlign: TextAlign.left,
                          )),
                      SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          child: AddPhotoButtonPlante(
                            keyButton: Key("ingredients_photo"),
                            onAddTap: takeIngredientsPhoto,
                            onCancelTap: removeIngredientsPhoto,
                            existingPhoto: model.product.imageIngredients,
                          )),
                      SizedBox(height: 16),
                      ingredientsTextGroup(),
                    ]),
                  if (model.askForVeganStatus())
                    Column(key: Key("vegan_status_group"), children: [
                      VegStatusSelectionPanel(
                        keyPositive: Key("vegan_positive_btn"),
                        keyNegative: Key("vegan_negative_btn"),
                        keyPossible: Key("vegan_possible_btn"),
                        keyUnknown: Key("vegan_unknown_btn"),
                        title: context.strings.init_product_page_is_it_vegan,
                        vegStatus: model.product.veganStatus,
                        onChanged: (value) {
                          setState(() {
                            model.product = model.product
                                .rebuild((e) => e.veganStatus = value);
                          });
                        },
                      ),
                      SizedBox(height: 24),
                    ]),
                  if (model.askForVegetarianStatus())
                    Column(key: Key("vegetarian_status_group"), children: [
                      VegStatusSelectionPanel(
                        keyPositive: Key("vegetarian_positive_btn"),
                        keyNegative: Key("vegetarian_negative_btn"),
                        keyPossible: Key("vegetarian_possible_btn"),
                        keyUnknown: Key("vegetarian_unknown_btn"),
                        title:
                            context.strings.init_product_page_is_it_vegetarian,
                        vegStatus: model.product.vegetarianStatus,
                        onChanged: (value) {
                          setState(() {
                            model.product = model.product
                                .rebuild((e) => e.vegetarianStatus = value);
                          });
                        },
                      ),
                    ]),
                  SizedBox(height: 36),
                  SizedBox(
                      width: double.infinity,
                      child: ButtonOutlinedPlante.withText(
                        context.strings.global_done,
                        key: Key("done_btn"),
                        onPressed: model.canSaveProduct() && !model.loading
                            ? saveProduct
                            : null,
                      )),
                ])),
            Container(
                padding: EdgeInsets.only(top: 38, right: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                      child: Container(
                          padding: EdgeInsets.all(12),
                          child: Text(context.strings.global_cancel,
                              style: TextStyles.headline3)),
                      onTap: cancel),
                )),
          ])),
      AnimatedSwitcher(
          duration: Duration(milliseconds: 250),
          child: model.loading ? LinearProgressIndicator() : SizedBox.shrink())
    ])));
  }

  Widget ingredientsTextGroup() {
    final result;
    if (model.askForIngredientsText()) {
      if (!ocrInProgress) {
        result = Column(
          key: Key("ingredients_text_group"),
          children: [
            Text(context.strings.init_product_page_verify_ingredients_ocr,
                style: TextStyles.normal),
            SizedBox(height: 12),
            InputFieldMultilinePlante(
              key: Key("ingredients_text"),
              controller: ingredientsTextController,
            ),
            SizedBox(height: 12),
          ],
        );
      } else {
        result = Column(key: Key("ingredients_text_group"), children: [
          Row(children: [
            CircularProgressIndicator(),
            SizedBox(width: 8),
            Text(context.strings.init_product_page_ocr_in_progress,
                style: TextStyles.normal)
          ]),
          SizedBox(height: 12),
        ]);
      }
    } else {
      result = SizedBox.shrink();
    }

    return AnimatedSwitcher(
        duration: Duration(milliseconds: 250), child: result);
  }

  void cancel() {
    if (widget.initialProduct == model.product) {
      Navigator.of(context).pop();
      return;
    }
    showWarningDialog(context.strings.init_product_page_cancel_adding_product_q,
        () {
      Navigator.of(context).pop();
    });
  }

  void showWarningDialog(String warning, dynamic Function() positiveClicked) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(warning),
          actions: <Widget>[
            TextButton(
              child: Text(context.strings.global_no),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(context.strings.global_yes),
              onPressed: () {
                Navigator.of(context).pop();
                positiveClicked.call();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> takePhoto(ProductImageType imageType) async {
    final path = await GetIt.I.get<PhotosTaker>().takeAndCropPhoto(context);
    if (path == null) {
      return false;
    }
    model.product = model.product.rebuildWithImage(imageType, path);
    return true;
  }

  void removePhoto(ProductImageType imageType) {
    showWarningDialog(context.strings.init_product_page_delete_photo_q, () {
      model.product = model.product.rebuildWithImage(imageType, null);
    });
  }

  void takeFrontPhoto() async {
    takePhoto(ProductImageType.FRONT);
  }

  void removeFrontPhoto() {
    removePhoto(ProductImageType.FRONT);
  }

  void takeIngredientsPhoto() async {
    final taken = await takePhoto(ProductImageType.INGREDIENTS);
    if (!taken || !mounted) {
      return;
    }
    try {
      ocrInProgress = true;
      onStateUpdated();

      final ingredientsText = await model.ocrIngredients(context.langCode);
      if (ingredientsText != null) {
        ingredientsTextController.text = ingredientsText;
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
        model.product =
            model.product.rebuildWithImage(ProductImageType.INGREDIENTS, null);
      }
    } finally {
      ocrInProgress = false;
      onStateUpdated();
    }
  }

  void removeIngredientsPhoto() {
    removePhoto(ProductImageType.INGREDIENTS);
    ingredientsTextController.text = "";
  }

  void saveProduct() async {
    final ok = await model.saveProduct(context.langCode);
    if (ok) {
      productUpdatedCallback?.call(model.product);
      Navigator.of(context).pop();
      showSnackBar(context.strings.init_product_page_done_msg, context);
      doneCallback?.call();
    } else {
      showSnackBar(context.strings.global_something_went_wrong, context);
    }
  }
}
