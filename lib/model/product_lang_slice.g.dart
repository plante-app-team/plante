// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_lang_slice.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ProductLangSlice> _$productLangSliceSerializer =
    new _$ProductLangSliceSerializer();

class _$ProductLangSliceSerializer
    implements StructuredSerializer<ProductLangSlice> {
  @override
  final Iterable<Type> types = const [ProductLangSlice, _$ProductLangSlice];
  @override
  final String wireName = 'ProductLangSlice';

  @override
  Iterable<Object?> serialize(Serializers serializers, ProductLangSlice object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'barcode',
      serializers.serialize(object.barcode,
          specifiedType: const FullType(String)),
      'moderatorVeganChoiceReasonsIds',
      serializers.serialize(object.moderatorVeganChoiceReasonsIds,
          specifiedType:
              const FullType(BuiltList, const [const FullType(int)])),
      'ingredientsAnalyzed',
      serializers.serialize(object.ingredientsAnalyzed,
          specifiedType:
              const FullType(BuiltList, const [const FullType(Ingredient)])),
    ];
    Object? value;
    value = object.lang;
    if (value != null) {
      result
        ..add('lang')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(LangCode)));
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
    value = object.moderatorVeganSourcesText;
    if (value != null) {
      result
        ..add('moderatorVeganSourcesText')
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
    value = object.name;
    if (value != null) {
      result
        ..add('name')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.ingredientsText;
    if (value != null) {
      result
        ..add('ingredientsText')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
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
  ProductLangSlice deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ProductLangSliceBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'lang':
          result.lang = serializers.deserialize(value,
              specifiedType: const FullType(LangCode)) as LangCode?;
          break;
        case 'barcode':
          result.barcode = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
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
        case 'moderatorVeganChoiceReasonsIds':
          result.moderatorVeganChoiceReasonsIds.replace(serializers.deserialize(
                  value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(int)]))!
              as BuiltList<Object?>);
          break;
        case 'moderatorVeganSourcesText':
          result.moderatorVeganSourcesText = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'brands':
          result.brands.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(String)]))!
              as BuiltList<Object?>);
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
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

class _$ProductLangSlice extends ProductLangSlice {
  @override
  final LangCode? lang;
  @override
  final String barcode;
  @override
  final VegStatus? veganStatus;
  @override
  final VegStatusSource? veganStatusSource;
  @override
  final BuiltList<int> moderatorVeganChoiceReasonsIds;
  @override
  final String? moderatorVeganSourcesText;
  @override
  final BuiltList<String>? brands;
  @override
  final String? name;
  @override
  final String? ingredientsText;
  @override
  final BuiltList<Ingredient> ingredientsAnalyzed;
  @override
  final Uri? imageFront;
  @override
  final Uri? imageFrontThumb;
  @override
  final Uri? imageIngredients;

  factory _$ProductLangSlice(
          [void Function(ProductLangSliceBuilder)? updates]) =>
      (new ProductLangSliceBuilder()..update(updates))._build();

  _$ProductLangSlice._(
      {this.lang,
      required this.barcode,
      this.veganStatus,
      this.veganStatusSource,
      required this.moderatorVeganChoiceReasonsIds,
      this.moderatorVeganSourcesText,
      this.brands,
      this.name,
      this.ingredientsText,
      required this.ingredientsAnalyzed,
      this.imageFront,
      this.imageFrontThumb,
      this.imageIngredients})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        barcode, r'ProductLangSlice', 'barcode');
    BuiltValueNullFieldError.checkNotNull(moderatorVeganChoiceReasonsIds,
        r'ProductLangSlice', 'moderatorVeganChoiceReasonsIds');
    BuiltValueNullFieldError.checkNotNull(
        ingredientsAnalyzed, r'ProductLangSlice', 'ingredientsAnalyzed');
  }

  @override
  ProductLangSlice rebuild(void Function(ProductLangSliceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductLangSliceBuilder toBuilder() =>
      new ProductLangSliceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductLangSlice &&
        lang == other.lang &&
        barcode == other.barcode &&
        veganStatus == other.veganStatus &&
        veganStatusSource == other.veganStatusSource &&
        moderatorVeganChoiceReasonsIds ==
            other.moderatorVeganChoiceReasonsIds &&
        moderatorVeganSourcesText == other.moderatorVeganSourcesText &&
        brands == other.brands &&
        name == other.name &&
        ingredientsText == other.ingredientsText &&
        ingredientsAnalyzed == other.ingredientsAnalyzed &&
        imageFront == other.imageFront &&
        imageFrontThumb == other.imageFrontThumb &&
        imageIngredients == other.imageIngredients;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, lang.hashCode);
    _$hash = $jc(_$hash, barcode.hashCode);
    _$hash = $jc(_$hash, veganStatus.hashCode);
    _$hash = $jc(_$hash, veganStatusSource.hashCode);
    _$hash = $jc(_$hash, moderatorVeganChoiceReasonsIds.hashCode);
    _$hash = $jc(_$hash, moderatorVeganSourcesText.hashCode);
    _$hash = $jc(_$hash, brands.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, ingredientsText.hashCode);
    _$hash = $jc(_$hash, ingredientsAnalyzed.hashCode);
    _$hash = $jc(_$hash, imageFront.hashCode);
    _$hash = $jc(_$hash, imageFrontThumb.hashCode);
    _$hash = $jc(_$hash, imageIngredients.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductLangSlice')
          ..add('lang', lang)
          ..add('barcode', barcode)
          ..add('veganStatus', veganStatus)
          ..add('veganStatusSource', veganStatusSource)
          ..add(
              'moderatorVeganChoiceReasonsIds', moderatorVeganChoiceReasonsIds)
          ..add('moderatorVeganSourcesText', moderatorVeganSourcesText)
          ..add('brands', brands)
          ..add('name', name)
          ..add('ingredientsText', ingredientsText)
          ..add('ingredientsAnalyzed', ingredientsAnalyzed)
          ..add('imageFront', imageFront)
          ..add('imageFrontThumb', imageFrontThumb)
          ..add('imageIngredients', imageIngredients))
        .toString();
  }
}

class ProductLangSliceBuilder
    implements Builder<ProductLangSlice, ProductLangSliceBuilder> {
  _$ProductLangSlice? _$v;

  LangCode? _lang;
  LangCode? get lang => _$this._lang;
  set lang(LangCode? lang) => _$this._lang = lang;

  String? _barcode;
  String? get barcode => _$this._barcode;
  set barcode(String? barcode) => _$this._barcode = barcode;

  VegStatus? _veganStatus;
  VegStatus? get veganStatus => _$this._veganStatus;
  set veganStatus(VegStatus? veganStatus) => _$this._veganStatus = veganStatus;

  VegStatusSource? _veganStatusSource;
  VegStatusSource? get veganStatusSource => _$this._veganStatusSource;
  set veganStatusSource(VegStatusSource? veganStatusSource) =>
      _$this._veganStatusSource = veganStatusSource;

  ListBuilder<int>? _moderatorVeganChoiceReasonsIds;
  ListBuilder<int> get moderatorVeganChoiceReasonsIds =>
      _$this._moderatorVeganChoiceReasonsIds ??= new ListBuilder<int>();
  set moderatorVeganChoiceReasonsIds(
          ListBuilder<int>? moderatorVeganChoiceReasonsIds) =>
      _$this._moderatorVeganChoiceReasonsIds = moderatorVeganChoiceReasonsIds;

  String? _moderatorVeganSourcesText;
  String? get moderatorVeganSourcesText => _$this._moderatorVeganSourcesText;
  set moderatorVeganSourcesText(String? moderatorVeganSourcesText) =>
      _$this._moderatorVeganSourcesText = moderatorVeganSourcesText;

  ListBuilder<String>? _brands;
  ListBuilder<String> get brands =>
      _$this._brands ??= new ListBuilder<String>();
  set brands(ListBuilder<String>? brands) => _$this._brands = brands;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

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

  ProductLangSliceBuilder();

  ProductLangSliceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _lang = $v.lang;
      _barcode = $v.barcode;
      _veganStatus = $v.veganStatus;
      _veganStatusSource = $v.veganStatusSource;
      _moderatorVeganChoiceReasonsIds =
          $v.moderatorVeganChoiceReasonsIds.toBuilder();
      _moderatorVeganSourcesText = $v.moderatorVeganSourcesText;
      _brands = $v.brands?.toBuilder();
      _name = $v.name;
      _ingredientsText = $v.ingredientsText;
      _ingredientsAnalyzed = $v.ingredientsAnalyzed.toBuilder();
      _imageFront = $v.imageFront;
      _imageFrontThumb = $v.imageFrontThumb;
      _imageIngredients = $v.imageIngredients;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductLangSlice other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ProductLangSlice;
  }

  @override
  void update(void Function(ProductLangSliceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductLangSlice build() => _build();

  _$ProductLangSlice _build() {
    _$ProductLangSlice _$result;
    try {
      _$result = _$v ??
          new _$ProductLangSlice._(
              lang: lang,
              barcode: BuiltValueNullFieldError.checkNotNull(
                  barcode, r'ProductLangSlice', 'barcode'),
              veganStatus: veganStatus,
              veganStatusSource: veganStatusSource,
              moderatorVeganChoiceReasonsIds:
                  moderatorVeganChoiceReasonsIds.build(),
              moderatorVeganSourcesText: moderatorVeganSourcesText,
              brands: _brands?.build(),
              name: name,
              ingredientsText: ingredientsText,
              ingredientsAnalyzed: ingredientsAnalyzed.build(),
              imageFront: imageFront,
              imageFrontThumb: imageFrontThumb,
              imageIngredients: imageIngredients);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'moderatorVeganChoiceReasonsIds';
        moderatorVeganChoiceReasonsIds.build();

        _$failedField = 'brands';
        _brands?.build();

        _$failedField = 'ingredientsAnalyzed';
        ingredientsAnalyzed.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ProductLangSlice', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
