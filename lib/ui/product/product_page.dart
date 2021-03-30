import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openfoodfacts/model/IngredientsAnalysisTags.dart' as off;
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;

import 'package:untitled_vegan_app/l10n/strings.dart';
import 'package:untitled_vegan_app/outside/off/off_product_restorable.dart';

class ProductPage extends StatefulWidget {
  final off.Product? _initialProduct;
  final String _barcode;

  ProductPage(this._initialProduct, this._barcode);

  @override
  _ProductPageState createState() => _ProductPageState(_initialProduct, _barcode);
}

class _ProductPageState extends State<ProductPage> with RestorationMixin {
  final _offUser = off.User(userId: '', password: '');

  OffProductRestorable _product;
  RestorableString _takenProductPhotoPath = RestorableString('');
  RestorableString _takenIngredientsPhotoPath = RestorableString('');
  RestorableBool _editing;

  final _imagePicker = ImagePicker();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _ingredientsController = TextEditingController();

  off.Product get product => _product.value;
  bool get editing => _editing.value;

  off.VegetarianStatus? get vegetarianStatus =>
      _product.value.ingredientsAnalysisTags?.vegetarianStatus;
  set vegetarianStatus(off.VegetarianStatus? newVal) {
    _updateProduct((product) {
      _ensureVegTagsInited(product);
      product.ingredientsAnalysisTags!.vegetarianStatus = newVal;
    });
  }
  
  off.VeganStatus? get veganStatus =>
      _product.value.ingredientsAnalysisTags?.veganStatus;
  set veganStatus(off.VeganStatus? newVal) {
    _updateProduct((product) {
      _ensureVegTagsInited(product);
      product.ingredientsAnalysisTags!.veganStatus = newVal;
    });
  }

  void _ensureVegTagsInited(off.Product product) {
     if (product.ingredientsAnalysisTags != null) {
       return;
     }
     final tags = off.IngredientsAnalysisTags([]);
     tags.vegetarianStatus = null;
     tags.veganStatus = null;
     product.ingredientsAnalysisTags = tags;
  }

  _ProductPageState(off.Product? initialProduct, String barcode)
      : _product = OffProductRestorable(initialProduct ?? off.Product(barcode: barcode)),
        _editing = RestorableBool(initialProduct == null) {
    if (initialProduct != null) {
      assert(initialProduct.barcode == barcode);
    }

    _nameController.addListener(() {
      _updateProduct((product) {
        product.productName = _nameController.text;
      });
    });
    _brandController.addListener(() {
      _updateProduct((product) {
        product.brands = _brandController.text;
      });
    });
    _categoriesController.addListener(() {
      _updateProduct((product) {
        final categories = _categoriesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        product.categoriesTags = categories.toList();
        product.categories = categories.join(', ');
      });
    });
    _ingredientsController.addListener(() {
      _updateProduct((product) {
        product.ingredientsText = _ingredientsController.text;
      });
    });
  }

  void _updateProduct(_ProductFunction fn) {
    fn.call(_product.value);
    setState(() {
      _product.value = _product.value;
    });
  }

  /// NOTE: multiple product pages are not supported
  @override
  String? get restorationId => 'product_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_product, 'product');
    registerForRestoration(_takenProductPhotoPath, 'taken_product_photo_path');
    registerForRestoration(_takenIngredientsPhotoPath, 'taken_ingredients_photo_path');
    registerForRestoration(_editing, 'editing');
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
          appBar: AppBar(title: Text(
              !editing
                  ? context.strings.product_page_title_display
                  : context.strings.product_page_title_creating)),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(left: 10, top: 20, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                _crossFade(
                    whenDisplaying: SizedBox(
                        width: double.infinity,
                        child: Text(
                            product.productName ?? context.strings.product_page_no_data,
                            style: Theme.of(context).textTheme.headline5)),
                    whenEditing: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(hintText: 'Product name'))),

                // Image
                SizedBox(height: 10),
                _crossFade(
                  whenDisplaying: _displayedProductPhotoWidget(),
                  whenEditing: InkWell(
                      child: _editedProductPhotoWidget(), onTap: _onProductImageTap)
                ),

                // Brand
                SizedBox(height: 20),
                Row(children: [
                  Text(context.strings.product_page_brand, style: Theme.of(context).textTheme.headline6),
                  Expanded(child: _crossFade(
                      whenDisplaying: Text(product.brands ?? context.strings.product_page_no_data),
                      whenEditing: TextField(controller: _brandController))),
                ]),

                // Categories
                _crossFade(
                  whenDisplaying: Row(children: [
                    Text(context.strings.product_page_categories, style: Theme.of(context).textTheme.headline6),
                    Text(product.categories ?? context.strings.product_page_no_data),
                  ]),
                  whenEditing: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.strings.product_page_categories, style: Theme.of(context).textTheme.headline6),
                    TextField(controller: _categoriesController)
                  ])
                ),

                // Vegetarian status
                Row(children: [
                  Text(context.strings.product_page_is_vegetarian, style: Theme.of(context).textTheme.headline6),
                  _crossFade(
                      whenDisplaying: Text(_vegetarianStatusToStr(vegetarianStatus)),
                      whenEditing: DropdownButton<int>(
                          icon: const Icon(Icons.arrow_downward),
                          value: vegetarianStatus?.index ?? -1,
                          onChanged: (int? newValue) {
                            setState(() {
                              if (newValue != null && 0 <= newValue && newValue < off.VegetarianStatus.values.length) {
                                vegetarianStatus = off.VegetarianStatus.values[newValue];
                              } else {
                                vegetarianStatus = null;
                              }
                            });
                          },
                          items: _possibleVegetarianStatuses().map<DropdownMenuItem<int>>((off.VegetarianStatus? value) {
                            return DropdownMenuItem<int>(
                              value: value?.index ?? -1,
                              child: Text(_vegetarianStatusToStr(value)),
                            );
                          }).toList()))
                ]),

                // Vegan status
                Row(children: [
                  Text(context.strings.product_page_is_vegan, style: Theme.of(context).textTheme.headline6),
                  _crossFade(
                      whenDisplaying: Text(_veganStatusToStr(veganStatus)),
                      whenEditing: DropdownButton<int>(
                          icon: const Icon(Icons.arrow_downward),
                          value: veganStatus?.index ?? -1,
                          onChanged: (int? newValue) {
                            setState(() {
                              if (newValue != null && 0 <= newValue && newValue < off.VeganStatus.values.length) {
                                veganStatus = off.VeganStatus.values[newValue];
                              } else {
                                veganStatus = null;
                              }
                            });
                          },
                          items: _possibleVeganStatuses().map<DropdownMenuItem<int>>((off.VeganStatus? value) {
                            return DropdownMenuItem<int>(
                              value: value?.index ?? -1,
                              child: Text(_veganStatusToStr(value)),
                            );
                          }).toList()))
                ]),

                // Ingredients
                SizedBox(height: 20),
                Text(context.strings.product_page_ingredients, style: Theme.of(context).textTheme.headline6),
                _crossFade(
                    whenDisplaying: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(product.ingredientsText ?? context.strings.product_page_no_data),
                      _displayedIngredientsPhotoWidget(),
                    ]),
                    whenEditing: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      InkWell(
                          child: _editedIngredientsPhotoWidget(), onTap: _onIngredientsImageTap),
                      TextField(controller: _ingredientsController, decoration: InputDecoration(hintText: 'Ingredients text'))
                    ])),

                if (editing) SizedBox(height: 100, child: Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: Padding(
                        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                        child: ElevatedButton(
                          child: Text('Готово'),
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 35)),
                          onPressed: _onSaveButtonClick,
                        )
                    ),
                  ),
                ),
              ]),
            )
          );
  }

  // TODO: move to model
  List<off.VegetarianStatus?> _possibleVegetarianStatuses() {
    final result = List<off.VegetarianStatus?>.from(off.VegetarianStatus.values);
    result.insert(0, null);
    return result;
  }

  // TODO: move to model
  String _vegetarianStatusToStr(off.VegetarianStatus? value) {
    switch(value) {
      case off.VegetarianStatus.IS_VEGETARIAN:
        return 'Стопудово вегетарианский';
      case off.VegetarianStatus.IS_NOT_VEGETARIAN:
        return 'Стопудово не вегетарианский';
      case off.VegetarianStatus.MAYBE:
        return 'По составу не понятно!';
      default:
        return 'Совсем неизвестно!';
    }
  }

  // TODO: move to model
  List<off.VeganStatus?> _possibleVeganStatuses() {
    final result = List<off.VeganStatus?>.from(off.VeganStatus.values);
    result.insert(0, null);
    return result;
  }

  // TODO: move to model
  String _veganStatusToStr(off.VeganStatus? value) {
    switch(value) {
      case off.VeganStatus.IS_VEGAN:
        return 'Стопудово веганский';
      case off.VeganStatus.IS_NOT_VEGAN:
        return 'Стопудово не веганский';
      case off.VeganStatus.MAYBE:
        return 'По составу не понятно!';
      default:
        return 'Совсем неизвестно!';
    }
  }
  
  Widget _crossFade({required Widget whenDisplaying, required Widget whenEditing}) {
    return AnimatedCrossFade(
        firstChild: whenDisplaying,
        secondChild: whenEditing,
        crossFadeState: !editing ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        duration: Duration(milliseconds: 250));
  }

  Widget _displayedProductPhotoWidget() {
    final takenPhoto = _takenProductPhotoWidget();
    if (takenPhoto != null) {
      return takenPhoto;
    }
    final existingOffImage = _offProductImage();
    if (existingOffImage != null) {
      return existingOffImage;
    }
    return SizedBox.shrink();
  }

  Widget _editedProductPhotoWidget() {
    final takenPhoto = _takenProductPhotoWidget();
    if (takenPhoto != null) {
      return takenPhoto;
    }
    final existingOffImage = _offProductImage();
    if (existingOffImage != null) {
      return existingOffImage;
    }
    return Icon(Icons.photo_camera_outlined, size: 75);
  }

  Image? _takenProductPhotoWidget() {
    if (_takenProductPhotoPath.value.isNotEmpty) {
      final file = File.fromUri(Uri.parse(_takenProductPhotoPath.value));
      if (file.existsSync()) {
        return Image.file(file, width: 150, height: 150);
      } else {
        _takenProductPhotoPath.value = '';
      }
    }
    return null;
  }

  Image? _offProductImage() {
    if (product.imageFrontSmallUrl != null) {
      return Image.network(product.imageFrontSmallUrl!);
    }
    return null;
  }

  Widget _displayedIngredientsPhotoWidget() {
    final takenPhoto = _takenIngredientsPhotoWidget();
    if (takenPhoto != null) {
      return takenPhoto;
    }
    final existingOffImage = _offIngredientsImage();
    if (existingOffImage != null) {
      return existingOffImage;
    }
    return SizedBox.shrink();
  }

  Widget _editedIngredientsPhotoWidget() {
    final takenPhoto = _takenIngredientsPhotoWidget();
    if (takenPhoto != null) {
      return takenPhoto;
    }
    final existingOffImage = _offIngredientsImage();
    if (existingOffImage != null) {
      return existingOffImage;
    }
    return Icon(Icons.photo_camera_outlined, size: 75);
  }

  Image? _takenIngredientsPhotoWidget() {
    if (_takenIngredientsPhotoPath.value.isNotEmpty) {
      final file = File.fromUri(Uri.parse(_takenIngredientsPhotoPath.value));
      if (file.existsSync()) {
        return Image.file(file, width: 150, height: 150);
      } else {
        _takenIngredientsPhotoPath.value = '';
      }
    }
    return null;
  }

  Image? _offIngredientsImage() {
    if (_ingredientsImageUrl() != null) {
      return Image.network(_ingredientsImageUrl()!);
    }
    return null;
  }

  String? _ingredientsImageUrl() {
    if (product.images == null) {
      return null;
    }
    for (final image in product.images!) {
      if (image.field == off.ImageField.INGREDIENTS
          && image.size == off.ImageSize.DISPLAY) {
        return image.url;
      }
    }
    return null;
  }


  void _onProductImageTap() async {
    final path = await _takeAndCropPhoto();
    if (path == null) {
      return;
    }
    setState(() {
      _takenProductPhotoPath.value = path;
    });
  }

  void _onIngredientsImageTap() async {
    final path = await _takeAndCropPhoto();
    if (path == null) {
      return;
    }
    setState(() {
      _takenIngredientsPhotoPath.value = path;
    });
  }

  // TODO: files are big and other apps and activities are opened here - we need
  //       to handle a situation when a picture is taken/cropped but our app has died
  Future<String?> _takeAndCropPhoto() async {
    final pickedFile = await _imagePicker.getImage(source: ImageSource.camera);
    if (pickedFile == null) {
      return null;
    }

    final croppedFile = await ImageCropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Давайте-ка обрежем!',
            toolbarColor: Colors.green,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: true),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ));
    return croppedFile?.path;
  }

  void _onSaveButtonClick() async {
    var status = await off.OpenFoodAPIClient.saveProduct(_offUser, product);

    if (status.error != null && status.error!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Err: ${status.error}')));
      return;
    }

    if (_takenProductPhotoPath.value.isNotEmpty) {
      status = await off.OpenFoodAPIClient.addProductImage(_offUser, off.SendImage(
          lang: off.OpenFoodFactsLanguage.RUSSIAN, // TODO: nope
          barcode: product.barcode,
          imageUrl: Uri.parse(_takenProductPhotoPath.value),
          imageField: off.ImageField.FRONT
      ));

      if (status.error != null && status.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Err: ${status.error}')));
        return;
      }
    }

    if (_takenIngredientsPhotoPath.value.isNotEmpty) {
      status = await off.OpenFoodAPIClient.addProductImage(_offUser, off.SendImage(
          lang: off.OpenFoodFactsLanguage.RUSSIAN, // TODO: nope
          barcode: product.barcode,
          imageUrl: Uri.parse(_takenIngredientsPhotoPath.value),
          imageField: off.ImageField.INGREDIENTS
      ));

      if (status.error != null && status.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Err: ${status.error}')));
        return;
      }
    }

    setState(() {
      _editing.value = false;
    });
  }
}

typedef _ProductFunction = void Function(off.Product product);
