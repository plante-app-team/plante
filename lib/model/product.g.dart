// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Product> _$productSerializer = new _$ProductSerializer();

class _$ProductSerializer implements StructuredSerializer<Product> {
  @override
  final Iterable<Type> types = const [Product, _$Product];
  @override
  final String wireName = 'Product';

  @override
  Iterable<Object?> serialize(Serializers serializers, Product object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'barcode',
      serializers.serialize(object.barcode,
          specifiedType: const FullType(String)),
    ];
    Object? value;
    value = object.vegetarianStatus;
    if (value != null) {
      result
        ..add('vegetarianStatus')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(VegStatus)));
    }
    value = object.vegetarianStatusSource;
    if (value != null) {
      result
        ..add('vegetarianStatusSource')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(VegStatusSource)));
    }
    value = object.veganStatus;
    if (value != null) {
      result
        ..add('veganStatus')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(VegStatus)));
    }
    value = object.veganStatusSource;
    if (value != null) {
      result
        ..add('veganStatusSource')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(VegStatusSource)));
    }
    value = object.moderatorVegetarianChoiceReasonId;
    if (value != null) {
      result
        ..add('moderatorVegetarianChoiceReasonId')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
    }
    value = object.moderatorVegetarianSourcesText;
    if (value != null) {
      result
        ..add('moderatorVegetarianSourcesText')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.moderatorVeganChoiceReasonId;
    if (value != null) {
      result
        ..add('moderatorVeganChoiceReasonId')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
    }
    value = object.moderatorVeganSourcesText;
    if (value != null) {
      result
        ..add('moderatorVeganSourcesText')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.name;
    if (value != null) {
      result
        ..add('name')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.brands;
    if (value != null) {
      result
        ..add('brands')
        ..add(serializers.serialize(value,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    value = object.categories;
    if (value != null) {
      result
        ..add('categories')
        ..add(serializers.serialize(value,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    value = object.ingredientsText;
    if (value != null) {
      result
        ..add('ingredientsText')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.ingredientsAnalyzed;
    if (value != null) {
      result
        ..add('ingredientsAnalyzed')
        ..add(serializers.serialize(value,
            specifiedType:
                const FullType(BuiltList, const [const FullType(Ingredient)])));
    }
    value = object.imageFront;
    if (value != null) {
      result
        ..add('imageFront')
        ..add(serializers.serialize(value, specifiedType: const FullType(Uri)));
    }
    value = object.imageFrontThumb;
    if (value != null) {
      result
        ..add('imageFrontThumb')
        ..add(serializers.serialize(value, specifiedType: const FullType(Uri)));
    }
    value = object.imageIngredients;
    if (value != null) {
      result
        ..add('imageIngredients')
        ..add(serializers.serialize(value, specifiedType: const FullType(Uri)));
    }
    return result;
  }

  @override
  Product deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ProductBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'barcode':
          result.barcode = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'vegetarianStatus':
          result.vegetarianStatus = serializers.deserialize(value,
              specifiedType: const FullType(VegStatus)) as VegStatus?;
          break;
        case 'vegetarianStatusSource':
          result.vegetarianStatusSource = serializers.deserialize(value,
                  specifiedType: const FullType(VegStatusSource))
              as VegStatusSource?;
          break;
        case 'veganStatus':
          result.veganStatus = serializers.deserialize(value,
              specifiedType: const FullType(VegStatus)) as VegStatus?;
          break;
        case 'veganStatusSource':
          result.veganStatusSource = serializers.deserialize(value,
                  specifiedType: const FullType(VegStatusSource))
              as VegStatusSource?;
          break;
        case 'moderatorVegetarianChoiceReasonId':
          result.moderatorVegetarianChoiceReasonId = serializers
              .deserialize(value, specifiedType: const FullType(int)) as int?;
          break;
        case 'moderatorVegetarianSourcesText':
          result.moderatorVegetarianSourcesText = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'moderatorVeganChoiceReasonId':
          result.moderatorVeganChoiceReasonId = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int?;
          break;
        case 'moderatorVeganSourcesText':
          result.moderatorVeganSourcesText = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'brands':
          result.brands.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(String)]))!
              as BuiltList<Object?>);
          break;
        case 'categories':
          result.categories.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(String)]))!
              as BuiltList<Object?>);
          break;
        case 'ingredientsText':
          result.ingredientsText = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'ingredientsAnalyzed':
          result.ingredientsAnalyzed.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(Ingredient)]))!
              as BuiltList<Object?>);
          break;
        case 'imageFront':
          result.imageFront = serializers.deserialize(value,
              specifiedType: const FullType(Uri)) as Uri?;
          break;
        case 'imageFrontThumb':
          result.imageFrontThumb = serializers.deserialize(value,
              specifiedType: const FullType(Uri)) as Uri?;
          break;
        case 'imageIngredients':
          result.imageIngredients = serializers.deserialize(value,
              specifiedType: const FullType(Uri)) as Uri?;
          break;
      }
    }

    return result.build();
  }
}

class _$Product extends Product {
  @override
  final String barcode;
  @override
  final VegStatus? vegetarianStatus;
  @override
  final VegStatusSource? vegetarianStatusSource;
  @override
  final VegStatus? veganStatus;
  @override
  final VegStatusSource? veganStatusSource;
  @override
  final int? moderatorVegetarianChoiceReasonId;
  @override
  final String? moderatorVegetarianSourcesText;
  @override
  final int? moderatorVeganChoiceReasonId;
  @override
  final String? moderatorVeganSourcesText;
  @override
  final String? name;
  @override
  final BuiltList<String>? brands;
  @override
  final BuiltList<String>? categories;
  @override
  final String? ingredientsText;
  @override
  final BuiltList<Ingredient>? ingredientsAnalyzed;
  @override
  final Uri? imageFront;
  @override
  final Uri? imageFrontThumb;
  @override
  final Uri? imageIngredients;

  factory _$Product([void Function(ProductBuilder)? updates]) =>
      (new ProductBuilder()..update(updates)).build();

  _$Product._(
      {required this.barcode,
      this.vegetarianStatus,
      this.vegetarianStatusSource,
      this.veganStatus,
      this.veganStatusSource,
      this.moderatorVegetarianChoiceReasonId,
      this.moderatorVegetarianSourcesText,
      this.moderatorVeganChoiceReasonId,
      this.moderatorVeganSourcesText,
      this.name,
      this.brands,
      this.categories,
      this.ingredientsText,
      this.ingredientsAnalyzed,
      this.imageFront,
      this.imageFrontThumb,
      this.imageIngredients})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(barcode, 'Product', 'barcode');
  }

  @override
  Product rebuild(void Function(ProductBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductBuilder toBuilder() => new ProductBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Product &&
        barcode == other.barcode &&
        vegetarianStatus == other.vegetarianStatus &&
        vegetarianStatusSource == other.vegetarianStatusSource &&
        veganStatus == other.veganStatus &&
        veganStatusSource == other.veganStatusSource &&
        moderatorVegetarianChoiceReasonId ==
            other.moderatorVegetarianChoiceReasonId &&
        moderatorVegetarianSourcesText ==
            other.moderatorVegetarianSourcesText &&
        moderatorVeganChoiceReasonId == other.moderatorVeganChoiceReasonId &&
        moderatorVeganSourcesText == other.moderatorVeganSourcesText &&
        name == other.name &&
        brands == other.brands &&
        categories == other.categories &&
        ingredientsText == other.ingredientsText &&
        ingredientsAnalyzed == other.ingredientsAnalyzed &&
        imageFront == other.imageFront &&
        imageFrontThumb == other.imageFrontThumb &&
        imageIngredients == other.imageIngredients;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc(
                                                    $jc(
                                                        $jc(
                                                            $jc(
                                                                $jc(
                                                                    $jc(
                                                                        0,
                                                                        barcode
                                                                            .hashCode),
                                                                    vegetarianStatus
                                                                        .hashCode),
                                                                vegetarianStatusSource
                                                                    .hashCode),
                                                            veganStatus
                                                                .hashCode),
                                                        veganStatusSource
                                                            .hashCode),
                                                    moderatorVegetarianChoiceReasonId
                                                        .hashCode),
                                                moderatorVegetarianSourcesText
                                                    .hashCode),
                                            moderatorVeganChoiceReasonId
                                                .hashCode),
                                        moderatorVeganSourcesText.hashCode),
                                    name.hashCode),
                                brands.hashCode),
                            categories.hashCode),
                        ingredientsText.hashCode),
                    ingredientsAnalyzed.hashCode),
                imageFront.hashCode),
            imageFrontThumb.hashCode),
        imageIngredients.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Product')
          ..add('barcode', barcode)
          ..add('vegetarianStatus', vegetarianStatus)
          ..add('vegetarianStatusSource', vegetarianStatusSource)
          ..add('veganStatus', veganStatus)
          ..add('veganStatusSource', veganStatusSource)
          ..add('moderatorVegetarianChoiceReasonId',
              moderatorVegetarianChoiceReasonId)
          ..add(
              'moderatorVegetarianSourcesText', moderatorVegetarianSourcesText)
          ..add('moderatorVeganChoiceReasonId', moderatorVeganChoiceReasonId)
          ..add('moderatorVeganSourcesText', moderatorVeganSourcesText)
          ..add('name', name)
          ..add('brands', brands)
          ..add('categories', categories)
          ..add('ingredientsText', ingredientsText)
          ..add('ingredientsAnalyzed', ingredientsAnalyzed)
          ..add('imageFront', imageFront)
          ..add('imageFrontThumb', imageFrontThumb)
          ..add('imageIngredients', imageIngredients))
        .toString();
  }
}

class ProductBuilder implements Builder<Product, ProductBuilder> {
  _$Product? _$v;

  String? _barcode;
  String? get barcode => _$this._barcode;
  set barcode(String? barcode) => _$this._barcode = barcode;

  VegStatus? _vegetarianStatus;
  VegStatus? get vegetarianStatus => _$this._vegetarianStatus;
  set vegetarianStatus(VegStatus? vegetarianStatus) =>
      _$this._vegetarianStatus = vegetarianStatus;

  VegStatusSource? _vegetarianStatusSource;
  VegStatusSource? get vegetarianStatusSource => _$this._vegetarianStatusSource;
  set vegetarianStatusSource(VegStatusSource? vegetarianStatusSource) =>
      _$this._vegetarianStatusSource = vegetarianStatusSource;

  VegStatus? _veganStatus;
  VegStatus? get veganStatus => _$this._veganStatus;
  set veganStatus(VegStatus? veganStatus) => _$this._veganStatus = veganStatus;

  VegStatusSource? _veganStatusSource;
  VegStatusSource? get veganStatusSource => _$this._veganStatusSource;
  set veganStatusSource(VegStatusSource? veganStatusSource) =>
      _$this._veganStatusSource = veganStatusSource;

  int? _moderatorVegetarianChoiceReasonId;
  int? get moderatorVegetarianChoiceReasonId =>
      _$this._moderatorVegetarianChoiceReasonId;
  set moderatorVegetarianChoiceReasonId(
          int? moderatorVegetarianChoiceReasonId) =>
      _$this._moderatorVegetarianChoiceReasonId =
          moderatorVegetarianChoiceReasonId;

  String? _moderatorVegetarianSourcesText;
  String? get moderatorVegetarianSourcesText =>
      _$this._moderatorVegetarianSourcesText;
  set moderatorVegetarianSourcesText(String? moderatorVegetarianSourcesText) =>
      _$this._moderatorVegetarianSourcesText = moderatorVegetarianSourcesText;

  int? _moderatorVeganChoiceReasonId;
  int? get moderatorVeganChoiceReasonId => _$this._moderatorVeganChoiceReasonId;
  set moderatorVeganChoiceReasonId(int? moderatorVeganChoiceReasonId) =>
      _$this._moderatorVeganChoiceReasonId = moderatorVeganChoiceReasonId;

  String? _moderatorVeganSourcesText;
  String? get moderatorVeganSourcesText => _$this._moderatorVeganSourcesText;
  set moderatorVeganSourcesText(String? moderatorVeganSourcesText) =>
      _$this._moderatorVeganSourcesText = moderatorVeganSourcesText;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  ListBuilder<String>? _brands;
  ListBuilder<String> get brands =>
      _$this._brands ??= new ListBuilder<String>();
  set brands(ListBuilder<String>? brands) => _$this._brands = brands;

  ListBuilder<String>? _categories;
  ListBuilder<String> get categories =>
      _$this._categories ??= new ListBuilder<String>();
  set categories(ListBuilder<String>? categories) =>
      _$this._categories = categories;

  String? _ingredientsText;
  String? get ingredientsText => _$this._ingredientsText;
  set ingredientsText(String? ingredientsText) =>
      _$this._ingredientsText = ingredientsText;

  ListBuilder<Ingredient>? _ingredientsAnalyzed;
  ListBuilder<Ingredient> get ingredientsAnalyzed =>
      _$this._ingredientsAnalyzed ??= new ListBuilder<Ingredient>();
  set ingredientsAnalyzed(ListBuilder<Ingredient>? ingredientsAnalyzed) =>
      _$this._ingredientsAnalyzed = ingredientsAnalyzed;

  Uri? _imageFront;
  Uri? get imageFront => _$this._imageFront;
  set imageFront(Uri? imageFront) => _$this._imageFront = imageFront;

  Uri? _imageFrontThumb;
  Uri? get imageFrontThumb => _$this._imageFrontThumb;
  set imageFrontThumb(Uri? imageFrontThumb) =>
      _$this._imageFrontThumb = imageFrontThumb;

  Uri? _imageIngredients;
  Uri? get imageIngredients => _$this._imageIngredients;
  set imageIngredients(Uri? imageIngredients) =>
      _$this._imageIngredients = imageIngredients;

  ProductBuilder();

  ProductBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _barcode = $v.barcode;
      _vegetarianStatus = $v.vegetarianStatus;
      _vegetarianStatusSource = $v.vegetarianStatusSource;
      _veganStatus = $v.veganStatus;
      _veganStatusSource = $v.veganStatusSource;
      _moderatorVegetarianChoiceReasonId = $v.moderatorVegetarianChoiceReasonId;
      _moderatorVegetarianSourcesText = $v.moderatorVegetarianSourcesText;
      _moderatorVeganChoiceReasonId = $v.moderatorVeganChoiceReasonId;
      _moderatorVeganSourcesText = $v.moderatorVeganSourcesText;
      _name = $v.name;
      _brands = $v.brands?.toBuilder();
      _categories = $v.categories?.toBuilder();
      _ingredientsText = $v.ingredientsText;
      _ingredientsAnalyzed = $v.ingredientsAnalyzed?.toBuilder();
      _imageFront = $v.imageFront;
      _imageFrontThumb = $v.imageFrontThumb;
      _imageIngredients = $v.imageIngredients;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Product other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Product;
  }

  @override
  void update(void Function(ProductBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Product build() {
    _$Product _$result;
    try {
      _$result = _$v ??
          new _$Product._(
              barcode: BuiltValueNullFieldError.checkNotNull(
                  barcode, 'Product', 'barcode'),
              vegetarianStatus: vegetarianStatus,
              vegetarianStatusSource: vegetarianStatusSource,
              veganStatus: veganStatus,
              veganStatusSource: veganStatusSource,
              moderatorVegetarianChoiceReasonId:
                  moderatorVegetarianChoiceReasonId,
              moderatorVegetarianSourcesText: moderatorVegetarianSourcesText,
              moderatorVeganChoiceReasonId: moderatorVeganChoiceReasonId,
              moderatorVeganSourcesText: moderatorVeganSourcesText,
              name: name,
              brands: _brands?.build(),
              categories: _categories?.build(),
              ingredientsText: ingredientsText,
              ingredientsAnalyzed: _ingredientsAnalyzed?.build(),
              imageFront: imageFront,
              imageFrontThumb: imageFrontThumb,
              imageIngredients: imageIngredients);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'brands';
        _brands?.build();
        _$failedField = 'categories';
        _categories?.build();

        _$failedField = 'ingredientsAnalyzed';
        _ingredientsAnalyzed?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Product', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
