import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/dialog_plante.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/components/add_photo_button_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/veg_status_selection_panel.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/photos_taker.dart';

// ignore: always_use_package_imports
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
  String? get restorationId => 'init_product_page';

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
      text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Stack(children: [
                  SingleChildScrollView(
                      key: const Key('content'),
                      child: Column(children: [
                        HeaderPlante(
                            rightActionPadding: 8,
                            rightAction: IconButton(
                                onPressed: cancel,
                                icon: SvgPicture.asset('assets/cancel.svg'))),
                        Container(
                            padding: const EdgeInsets.only(left: 24, right: 24),
                            child: Column(children: [
                              SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    widget.title ??
                                        context.strings.init_product_page_title,
                                    style: TextStyles.headline1,
                                    textAlign: TextAlign.left,
                                  )),
                              const SizedBox(height: 24),
                              if (model.askForFrontPhoto())
                                Column(
                                    key: const Key('front_photo_group'),
                                    children: [
                                      SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            context.strings
                                                .init_product_page_take_front_photo,
                                            style: TextStyles.headline4,
                                            textAlign: TextAlign.left,
                                          )),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                          width: double.infinity,
                                          child: AddPhotoButtonPlante(
                                            keyButton: const Key('front_photo'),
                                            onAddTap: takeFrontPhoto,
                                            onCancelTap: removeFrontPhoto,
                                            existingPhoto:
                                                model.product.imageFront,
                                          )),
                                      const SizedBox(height: 24),
                                    ]),
                              if (model.askForName())
                                Column(key: const Key('name_group'), children: [
                                  InputFieldPlante(
                                    key: const Key('name'),
                                    label: context
                                        .strings.init_product_page_product_name,
                                    controller: nameTextController,
                                  ),
                                  const SizedBox(height: 24),
                                ]),
                              if (model.askForBrand())
                                Column(
                                    key: const Key('brand_group'),
                                    children: [
                                      InputFieldPlante(
                                        key: const Key('brand'),
                                        label: context.strings
                                            .init_product_page_brand_optional,
                                        controller: brandTextController,
                                      ),
                                      const SizedBox(height: 24),
                                    ]),
                              if (model.askForCategories())
                                Column(
                                    key: const Key('categories_group'),
                                    children: [
                                      InputFieldPlante(
                                        key: const Key('categories'),
                                        label: context.strings
                                            .init_product_page_categories_optional,
                                        hint: context.strings
                                            .init_product_page_categories_hint,
                                        controller: categoriesTextController,
                                      ),
                                      const SizedBox(height: 24),
                                    ]),
                              if (model.askForIngredientsData())
                                Column(
                                    key: const Key('ingredients_group'),
                                    children: [
                                      SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            context.strings
                                                .init_product_page_take_ingredients_photo,
                                            style: TextStyles.headline4,
                                            textAlign: TextAlign.left,
                                          )),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                          width: double.infinity,
                                          child: AddPhotoButtonPlante(
                                            keyButton:
                                                const Key('ingredients_photo'),
                                            onAddTap: takeIngredientsPhoto,
                                            onCancelTap: removeIngredientsPhoto,
                                            existingPhoto:
                                                model.product.imageIngredients,
                                          )),
                                      const SizedBox(height: 16),
                                      ingredientsTextGroup(),
                                    ]),
                              if (model.askForVeganStatus())
                                Column(
                                    key: const Key('vegan_status_group'),
                                    children: [
                                      VegStatusSelectionPanel(
                                        keyPositive:
                                            const Key('vegan_positive_btn'),
                                        keyNegative:
                                            const Key('vegan_negative_btn'),
                                        keyUnknown:
                                            const Key('vegan_unknown_btn'),
                                        title: context.strings
                                            .init_product_page_is_it_vegan,
                                        vegStatus: model.product.veganStatus,
                                        onChanged: (value) {
                                          setState(() {
                                            model.product = model.product
                                                .rebuild((e) =>
                                                    e.veganStatus = value);
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                    ]),
                              if (model.askForVegetarianStatus())
                                Column(
                                    key: const Key('vegetarian_status_group'),
                                    children: [
                                      VegStatusSelectionPanel(
                                        keyPositive: const Key(
                                            'vegetarian_positive_btn'),
                                        keyNegative: const Key(
                                            'vegetarian_negative_btn'),
                                        keyUnknown:
                                            const Key('vegetarian_unknown_btn'),
                                        title: context.strings
                                            .init_product_page_is_it_vegetarian,
                                        vegStatus:
                                            model.product.vegetarianStatus,
                                        onChanged: (value) {
                                          setState(() {
                                            model.product = model.product
                                                .rebuild((e) =>
                                                    e.vegetarianStatus = value);
                                          });
                                        },
                                      ),
                                    ]),
                              const SizedBox(height: 36),
                              SizedBox(
                                  width: double.infinity,
                                  child: ButtonFilledPlante.withText(
                                    context.strings.global_done,
                                    key: const Key('done_btn'),
                                    onPressed:
                                        model.canSaveProduct() && !model.loading
                                            ? saveProduct
                                            : null,
                                  )),
                              const SizedBox(height: 40)
                            ])),
                      ])),
                  AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: model.loading
                          ? const LinearProgressIndicator()
                          : const SizedBox.shrink())
                ]))));
  }

  Widget ingredientsTextGroup() {
    final Widget result;
    if (model.askForIngredientsText()) {
      if (!ocrInProgress) {
        result = Column(
          key: const Key('ingredients_text_group'),
          children: [
            Text(context.strings.init_product_page_verify_ingredients_ocr,
                style: TextStyles.hint),
            const SizedBox(height: 12),
            InputFieldMultilinePlante(
              key: const Key('ingredients_text'),
              controller: ingredientsTextController,
            ),
            const SizedBox(height: 17),
          ],
        );
      } else {
        result = Column(key: const Key('ingredients_text_group'), children: [
          Row(children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 8),
            Text(context.strings.init_product_page_ocr_in_progress,
                style: TextStyles.normal)
          ]),
          const SizedBox(height: 17),
        ]);
      }
    } else {
      result = const SizedBox.shrink();
    }

    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250), child: result);
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
        return DialogPlante(
            content: Text(warning, style: TextStyles.headline1),
            actions: Row(children: [
              Expanded(
                  child: ButtonOutlinedPlante.withText(
                context.strings.global_yes,
                onPressed: () {
                  Navigator.of(context).pop();
                  positiveClicked.call();
                },
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: ButtonFilledPlante.withText(
                context.strings.global_no,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )),
            ]));
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
    await takePhoto(ProductImageType.FRONT);
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
    ingredientsTextController.text = '';
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
