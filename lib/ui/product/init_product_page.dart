import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
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
import 'package:plante/ui/map/map_page.dart';
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

  final ProductImageType? photoBeingTakenForTests;

  InitProductPage(this.initialProduct,
      {Key? key,
      this.title,
      this.productUpdatedCallback,
      this.doneCallback,
      this.photoBeingTakenForTests})
      : super(key: key) {
    if (photoBeingTakenForTests != null && !isInTests()) {
      throw Exception();
    }
  }

  @override
  _InitProductPageState createState() => _InitProductPageState(
      initialProduct, productUpdatedCallback, doneCallback);

  Future<Directory> cacheDir() async {
    final tempDir = await getTemporaryDirectory();
    return Directory('${tempDir.path}/init_product_cache');
  }
}

class _InitProductPageState extends State<InitProductPage>
    with RestorationMixin {
  late final InitProductPageModel model;
  final ProductUpdatedCallback? productUpdatedCallback;
  final VoidCallback? doneCallback;

  final TextEditingController nameTextController = TextEditingController();
  final TextEditingController brandTextController = TextEditingController();
  final TextEditingController categoriesTextController =
      TextEditingController();
  final TextEditingController ingredientsTextController =
      TextEditingController();

  _InitProductPageState(
      Product initialProduct, this.productUpdatedCallback, this.doneCallback) {
    model = InitProductPageModel(
        initialProduct,
        onStateUpdated,
        forceUseModelData,
        [],
        GetIt.I.get<ProductsManager>(),
        GetIt.I.get<ShopsManager>(),
        GetIt.I.get<PhotosTaker>());
  }

  void onStateUpdated() {
    if (!mounted) {
      return;
    }
    setState(() {
      // Update!
    });
  }

  void forceUseModelData() {
    if (!mounted) {
      return;
    }
    setState(takeModelProductText);
  }

  void takeModelProductText() {
    nameTextController.text = model.product.name ?? '';
    brandTextController.text = model.product.brands?.join(', ') ?? '';
    categoriesTextController.text = model.product.categories?.join(', ') ?? '';
    ingredientsTextController.text = model.product.ingredientsText ?? '';
  }

  @override
  void initState() {
    super.initState();
    _ensureCacheDirExistence();
  }

  void _ensureCacheDirExistence() async {
    final cache = await widget.cacheDir();
    if (!isInTests()) {
      if (!(await cache.exists())) {
        await cache.create(recursive: true);
      }
    } else {
      if (!cache.existsSync()) {
        cache.createSync(recursive: true);
      }
    }
  }

  @override
  String? get restorationId => 'init_product_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    for (final property in model.restorableProperties.entries) {
      registerForRestoration(property.value, property.key);
    }

    takeModelProductText();

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

    () async {
      if (widget.photoBeingTakenForTests != null) {
        model.setPhotoBeingTakenForTests(widget.photoBeingTakenForTests!);
      }
      model.initPhotoTaker(context, await widget.cacheDir());
    }.call();
  }

  @override
  void dispose() {
    for (final property in model.restorableProperties.values) {
      property.dispose();
    }
    super.dispose();
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
                                onPressed: _cancel,
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
                                            onAddTap: _takeFrontPhoto,
                                            onCancelTap: _removeFrontPhoto,
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
                              if (model.askForShops())
                                Column(
                                    key: const Key('shops_group'),
                                    children: [
                                      SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            context.strings
                                                .init_product_page_where_sold_optional,
                                            style: TextStyles.headline4,
                                            textAlign: TextAlign.left,
                                          )),
                                      const SizedBox(height: 16),
                                      Row(
                                          textDirection: TextDirection.rtl,
                                          children: [
                                            ButtonOutlinedPlante.withText(
                                                context.strings
                                                    .init_product_page_open_map,
                                                key: const Key('shops_btn'),
                                                onPressed: _markShopsOnMap),
                                            Expanded(
                                                child: Text(
                                                    model.shops
                                                        .map((shop) =>
                                                            '«${shop.name}»')
                                                        .join(', '),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis))
                                          ]),
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
                                            onAddTap: _takeIngredientsPhoto,
                                            onCancelTap:
                                                _removeIngredientsPhoto,
                                            existingPhoto:
                                                model.product.imageIngredients,
                                          )),
                                      const SizedBox(height: 16),
                                      _ingredientsTextGroup(),
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
                                            ? _saveProduct
                                            : null,
                                  )),
                              const SizedBox(height: 40)
                            ])),
                      ])),
                  AnimatedSwitcher(
                      duration: DURATION_DEFAULT,
                      child: model.loading
                          ? const LinearProgressIndicator()
                          : const SizedBox.shrink())
                ]))));
  }

  Widget _ingredientsTextGroup() {
    final Widget result;
    if (model.askForIngredientsText()) {
      if (!model.ocrInProgress) {
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

    return AnimatedSwitcher(duration: DURATION_DEFAULT, child: result);
  }

  void _cancel() {
    if (widget.initialProduct == model.product) {
      Log.i('InitProductPage: _cancel instant exit');
      Navigator.of(context).pop();
      return;
    }
    Log.i('InitProductPage: _cancel with confirmation');
    showYesNoDialog(
        context, context.strings.init_product_page_cancel_adding_product_q, () {
      Log.i('InitProductPage: _cancel exit confirmed');
      Navigator.of(context).pop();
    });
  }

  void _takePhoto(ProductImageType imageType) async {
    model.takePhoto(imageType, context);
  }

  void _removePhoto(ProductImageType imageType) {
    showYesNoDialog(context, context.strings.init_product_page_delete_photo_q,
        () {
      Log.i('InitProductPage: _removePhoto confirmation');
      model.product = model.product.rebuildWithImage(imageType, null);
    });
  }

  void _takeFrontPhoto() {
    _takePhoto(ProductImageType.FRONT);
  }

  void _removeFrontPhoto() {
    _removePhoto(ProductImageType.FRONT);
  }

  void _takeIngredientsPhoto() async {
    _takePhoto(ProductImageType.INGREDIENTS);
  }

  void _removeIngredientsPhoto() {
    _removePhoto(ProductImageType.INGREDIENTS);
    ingredientsTextController.text = '';
  }

  void _saveProduct() async {
    Log.i('InitProductPage: _saveProduct start: ${model.product}');
    final ok = await model.saveProduct(context.langCode);
    if (ok) {
      Log.i('InitProductPage: _saveProduct success');
      productUpdatedCallback?.call(model.product);
      Navigator.of(context).pop();
      showSnackBar(context.strings.global_done_thanks, context);
      if (!isInTests()) {
        await (await widget.cacheDir()).delete();
      } else {
        (await widget.cacheDir()).deleteSync();
      }
      doneCallback?.call();
    } else {
      showSnackBar(context.strings.global_something_went_wrong, context);
    }
  }

  void _markShopsOnMap() async {
    Log.i('InitProductPage: _markShopsOnMap start');
    final shops = await Navigator.push<List<Shop>>(
        context,
        MaterialPageRoute(
            builder: (context) => MapPage(
                requestedMode: MapPageRequestedMode.SELECT_SHOPS,
                initialSelectedShops: model.shops)));
    if (shops == null) {
      Log.i('InitProductPage: _markShopsOnMap no shops marked');
      return;
    }
    Log.i('InitProductPage: _markShopsOnMap success: $shops');
    model.shops = shops;
  }
}
