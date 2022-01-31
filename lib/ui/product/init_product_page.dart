import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/components/add_photo_button_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dropdown_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/label_cancelable_plante.dart';
import 'package:plante/ui/base/components/linear_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/veg_status_selection_panel.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_permissions_utils.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/photos/photos_taker.dart';

// ignore: always_use_package_imports
import 'init_product_page_model.dart';

typedef DoneCallback = void Function();
typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class InitProductPage extends PagePlante {
  final Product initialProduct;
  final List<Shop> initialShops;
  final ProductUpdatedCallback? productUpdatedCallback;
  final VoidCallback? doneCallback;

  final ProductImageType? photoBeingTakenForTests;
  late final String? cacheFolderForTest;

  InitProductPage(this.initialProduct,
      {Key? key,
      this.initialShops = const [],
      this.productUpdatedCallback,
      this.doneCallback,
      this.photoBeingTakenForTests})
      : super(key: key) {
    if (photoBeingTakenForTests != null && !isInTests()) {
      throw Exception();
    }
    if (isInTests()) {
      final now = DateTime.now().millisecondsSinceEpoch;
      cacheFolderForTest = '/tmp/$now';
    } else {
      cacheFolderForTest = null;
    }
  }

  @override
  _InitProductPageState createState() => _InitProductPageState();

  Future<Directory> cacheDir() async {
    if (cacheFolderForTest != null) {
      if (!isInTests()) {
        throw Exception();
      }
      return Directory(cacheFolderForTest!);
    }
    final tempDir = await getAppTempDir();
    return Directory('${tempDir.path}/init_product_cache');
  }
}

class _InitProductPageState extends PageStatePlante<InitProductPage>
    with RestorationMixin {
  late final PermissionsManager _permissionsManager;
  late final InitProductPageModel _model;

  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _brandTextController = TextEditingController();
  final TextEditingController _ingredientsTextController =
      TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  _InitProductPageState() : super('InitProductPage');

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
    _nameTextController.text = _model.productSlice.name ?? '';
    _brandTextController.text = _model.productSlice.brands?.join(', ') ?? '';
    _ingredientsTextController.text = _model.productSlice.ingredientsText ?? '';
  }

  @override
  void initState() {
    super.initState();
    _permissionsManager = GetIt.I.get<PermissionsManager>();
    _model = InitProductPageModel(
        widget.initialProduct,
        onStateUpdated,
        forceUseModelData,
        widget.initialShops,
        GetIt.I.get<ProductsManager>(),
        GetIt.I.get<ShopsManager>(),
        GetIt.I.get<PhotosTaker>(),
        analytics,
        GetIt.I.get<InputProductsLangStorage>(),
        GetIt.I.get<UserLangsManager>());
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
    for (final property in _model.restorableProperties.entries) {
      registerForRestoration(property.value, property.key);
    }

    takeModelProductText();

    _nameTextController.addListener(() {
      _model.productSlice =
          _model.productSlice.rebuild((e) => e.name = _nameTextController.text);
    });
    _brandTextController.addListener(() {
      _model.productSlice = _model.productSlice.rebuild(
          (e) => e.brands = _textToListBuilder(_brandTextController.text));
    });
    _ingredientsTextController.addListener(() {
      _model.productSlice = _model.productSlice
          .rebuild((e) => e.ingredientsText = _ingredientsTextController.text);
    });

    () async {
      if (widget.photoBeingTakenForTests != null) {
        _model.setPhotoBeingTakenForTests(widget.photoBeingTakenForTests!);
      }
      _model.initPhotoTaker(context, await widget.cacheDir());
    }.call();
  }

  @override
  void dispose() {
    for (final property in _model.restorableProperties.values) {
      property.dispose();
    }
    super.dispose();
  }

  ListBuilder<String> _textToListBuilder(String text) => ListBuilder(
      text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));

  @override
  Widget buildPage(BuildContext context) {
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: double.infinity,
          child: Text(
            context.strings.init_product_page_title,
            style: TextStyles.headline1,
            textAlign: TextAlign.left,
          )),
      const SizedBox(height: 24),
      if (_model.askForLanguage())
        Column(children: [
          SizedBox(
              width: double.infinity,
              child: Text(
                context.strings.init_product_page_lang_title,
                style: TextStyles.headline4,
                textAlign: TextAlign.left,
              )),
          const SizedBox(height: 16),
          DropdownPlante<LangCode>(
            key: const Key('product_lang'),
            value: _model.langCode,
            values: _model.userLangs,
            onChanged: (value) {
              if (value != null) {
                _model.langCode = value;
              }
            },
            dropdownItemBuilder: (langCode) {
              return Text(langCode.localize(context), style: TextStyles.normal);
            },
          ),
          const SizedBox(height: 12),
        ]),
      if (_model.askForFrontPhoto())
        Column(key: const Key('front_photo_group'), children: [
          SizedBox(
              width: double.infinity,
              child: Text(
                context.strings.init_product_page_take_front_photo,
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
                existingPhoto: _model.productSlice.imageFront,
              )),
          const SizedBox(height: 24),
        ]),
      if (_model.askForName())
        Column(key: const Key('name_group'), children: [
          InputFieldPlante(
            key: const Key('name'),
            label: context.strings.init_product_page_product_name,
            controller: _nameTextController,
          ),
          const SizedBox(height: 24),
        ]),
      if (_model.askForBrand())
        Column(key: const Key('brand_group'), children: [
          InputFieldPlante(
            key: const Key('brand'),
            label: context.strings.init_product_page_brand_optional,
            controller: _brandTextController,
          ),
          const SizedBox(height: 24),
        ]),
      if (_model.askForShops())
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            key: const Key('shops_group'),
            children: [
              SizedBox(
                  width: double.infinity,
                  child: Text(
                    context.strings.init_product_page_where_sold_optional,
                    style: TextStyles.headline4,
                    textAlign: TextAlign.left,
                  )),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: ButtonFilledPlante.withText(
                      context.strings.init_product_page_open_map,
                      key: const Key('shops_btn'),
                      onPressed: _markShopsOnMap)),
              if (_model.shops.isNotEmpty)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 14),
                  Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: _model.shops
                          .map((shop) => LabelCancelablePlante(
                                shop.name,
                                key: Key('shop_label_${shop.osmUID}'),
                                onCanceledCallback: () {
                                  final newShops = _model.shops.toList();
                                  newShops.remove(shop);
                                  _model.shops = newShops;
                                },
                              ))
                          .toList()),
                ]),
              const SizedBox(height: 22),
            ]),
      if (_model.askForIngredientsData())
        Column(key: const Key('ingredients_group'), children: [
          SizedBox(
              width: double.infinity,
              child: Text(
                context.strings.init_product_page_take_ingredients_photo,
                style: TextStyles.headline4,
                textAlign: TextAlign.left,
              )),
          const SizedBox(height: 16),
          SizedBox(
              width: double.infinity,
              child: AddPhotoButtonPlante(
                keyButton: const Key('ingredients_photo'),
                onAddTap: _takeIngredientsPhoto,
                onCancelTap: _removeIngredientsPhoto,
                existingPhoto: _model.productSlice.imageIngredients,
              )),
          const SizedBox(height: 16),
          _ingredientsTextGroup(),
        ]),
      if (_model.askForVeganStatus())
        Column(key: const Key('vegan_status_group'), children: [
          VegStatusSelectionPanel(
            keyPositive: const Key('vegan_positive_btn'),
            keyNegative: const Key('vegan_negative_btn'),
            keyUnknown: const Key('vegan_unknown_btn'),
            title: context.strings.init_product_page_is_it_vegan,
            vegStatus: _model.productSlice.veganStatus,
            onChanged: (value) {
              setState(() {
                _model.productSlice =
                    _model.productSlice.rebuild((e) => e.veganStatus = value);
              });
            },
          ),
          const SizedBox(height: 24),
        ]),
      const SizedBox(height: 24),
      SizedBox(
          width: double.infinity,
          child: ButtonFilledPlante.withText(
            context.strings.global_done,
            key: const Key('done_btn'),
            onPressed: _model.canSaveProduct() && !_model.loading
                ? _saveProduct
                : null,
          )),
      const SizedBox(height: 24)
    ]);

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
                      controller: _contentScrollController,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HeaderPlante(
                                rightAction: FabPlante(
                                    onPressed: _cancel,
                                    svgAsset: 'assets/cancel.svg')),
                            Container(
                                padding:
                                    const EdgeInsets.only(left: 24, right: 24),
                                child: content),
                          ])),
                  AnimatedSwitcher(
                      duration: DURATION_DEFAULT,
                      child: _model.loading
                          ? const LinearProgressIndicatorPlante()
                          : const SizedBox.shrink())
                ]))));
  }

  Widget _ingredientsTextGroup() {
    final Widget result;
    if (_model.askForIngredientsText()) {
      switch (_model.ocrState) {
        case InitProductPageOcrState.NONE:
          Log.w('model.askForIngredientsText true, but ocr state is NONE');
          result = const SizedBox.shrink();
          break;
        case InitProductPageOcrState.IN_PROGRESS:
          result = Column(key: const Key('ingredients_text_group'), children: [
            Row(children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 8),
              Text(context.strings.init_product_page_ocr_in_progress,
                  style: TextStyles.normal)
            ]),
            const SizedBox(height: 17),
          ]);
          break;
        case InitProductPageOcrState.SUCCESS:
          result = Column(
            key: const Key('ingredients_text_group'),
            children: [
              Text(context.strings.init_product_page_verify_ingredients_ocr,
                  style: TextStyles.hint),
              const SizedBox(height: 12),
              InputFieldMultilinePlante(
                key: const Key('ingredients_text'),
                controller: _ingredientsTextController,
              ),
              const SizedBox(height: 17),
            ],
          );
          break;
        case InitProductPageOcrState.FAILURE:
          result = Column(
            key: const Key('ingredients_text_group'),
            children: [
              Text(context.strings.init_product_page_ocr_error_descr,
                  style: TextStyles.hint),
              const SizedBox(height: 8),
              ButtonFilledPlante.withText(context.strings.global_try_again,
                  key: const Key('ocr_try_again'), onPressed: _performOcr),
              const SizedBox(height: 12),
              InputFieldMultilinePlante(
                key: const Key('ingredients_text'),
                controller: _ingredientsTextController,
              ),
              const SizedBox(height: 17),
            ],
          );
          break;
      }
    } else {
      result = const SizedBox.shrink();
    }

    return AnimatedSwitcher(duration: DURATION_DEFAULT, child: result);
  }

  void _cancel() {
    if (widget.initialProduct == _model.productFull) {
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
    if (!await _ensureCameraPermissions()) {
      return;
    }
    final result = await _model.takePhoto(imageType, context);
    _handlePossibleError(result);
  }

  Future<bool> _ensureCameraPermissions() async {
    return await maybeRequestPermission(
        context,
        _permissionsManager,
        PermissionKind.CAMERA,
        context.strings.init_product_page_camera_permission_reasoning_settings,
        context.strings.global_open_app_settings,
        settingsDialogCancelWhat: context.strings.global_cancel);
  }

  void _removePhoto(ProductImageType imageType) {
    showYesNoDialog(context, context.strings.init_product_page_delete_photo_q,
        () {
      Log.i('InitProductPage: _removePhoto confirmation');
      _model.productSlice =
          _model.productSlice.rebuildWithImage(imageType, null);
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
    _ingredientsTextController.text = '';
  }

  void _performOcr() async {
    final result = await _model.performOcr();
    _handlePossibleError(result);
  }

  void _handlePossibleError<T>(Result<T, InitProductPageModelError> result) {
    if (!result.isErr) {
      return;
    }
    switch (result.unwrapErr()) {
      case InitProductPageModelError.LANG_CODE_MISSING:
        _contentScrollController.animateTo(0,
            duration: DURATION_DEFAULT, curve: Curves.easeIn);
        showSnackBar(
            context.strings.init_product_page_please_select_lang, context);
        break;
      case InitProductPageModelError.OTHER:
        showSnackBar(context.strings.global_something_went_wrong, context);
        break;
    }
  }

  void _saveProduct() async {
    Log.i('InitProductPage: _saveProduct start: ${_model.productSlice}');
    final result = await _model.saveProduct();
    if (result.isOk) {
      Log.i('InitProductPage: _saveProduct success');
      widget.productUpdatedCallback?.call(result.unwrap());
      Navigator.of(context).pop();
      showSnackBar(context.strings.global_done_thanks, context);
      if (!isInTests()) {
        await (await widget.cacheDir()).delete(recursive: true);
      } else {
        (await widget.cacheDir()).deleteSync();
      }
      widget.doneCallback?.call();
    } else {
      _handlePossibleError(result);
    }
  }

  void _markShopsOnMap() async {
    if (_model.productFull?.veganStatus == VegStatus.negative) {
      showSnackBar(
          context.strings.init_product_page_adding_non_vegan_product, context);
    } else {
      Log.i('InitProductPage: _markShopsOnMap start');
      final shops = await Navigator.push<List<Shop>>(
          context,
          MaterialPageRoute(
              builder: (context) => MapPage(
                  requestedMode: MapPageRequestedMode.SELECT_SHOPS,
                  initialSelectedShops: _model.shops)));
      if (shops == null) {
        Log.i('InitProductPage: _markShopsOnMap no shops marked');
        return;
      }
      Log.i('InitProductPage: _markShopsOnMap success: $shops');
      _model.shops = shops;
    }
  }
}
