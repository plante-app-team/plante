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
      'moderatorVeganChoiceReasonsIds',
      serializers.serialize(object.moderatorVeganChoiceReasonsIds,
          specifiedType:
              const FullType(BuiltList, const [const FullType(int)])),
      'likesCount',
      serializers.serialize(object.likesCount,
          specifiedType: const FullType(int)),
      'likedByMe',
      serializers.serialize(object.likedByMe,
          specifiedType: const FullType(bool)),
      'langsPrioritized',
      serializers.serialize(object.langsPrioritized,
          specifiedType:
              const FullType(BuiltList, const [const FullType(LangCode)])),
      'nameLangs',
      serializers.serialize(object.nameLangs,
          specifiedType: const FullType(BuiltMap,
              const [const FullType(LangCode), const FullType(String)])),
      'ingredientsTextLangs',
      serializers.serialize(object.ingredientsTextLangs,
          specifiedType: const FullType(BuiltMap,
              const [const FullType(LangCode), const FullType(String)])),
      'imageFrontLangs',
      serializers.serialize(object.imageFrontLangs,
          specifiedType: const FullType(
              BuiltMap, const [const FullType(LangCode), const FullType(Uri)])),
      'imageFrontThumbLangs',
      serializers.serialize(object.imageFrontThumbLangs,
          specifiedType: const FullType(
              BuiltMap, const [const FullType(LangCode), const FullType(Uri)])),
      'imageIngredientsLangs',
      serializers.serialize(object.imageIngredientsLangs,
          specifiedType: const FullType(
              BuiltMap, const [const FullType(LangCode), const FullType(Uri)])),
      'ingredientsAnalyzedLangs',
      serializers.serialize(object.ingredientsAnalyzedLangs,
          specifiedType: const FullType(BuiltMap, const [
            const FullType(LangCode),
            const FullType(BuiltList, const [const FullType(Ingredient)])
          ])),
    ];
    Object? value;
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
    return result;
  }

  @override
  Product deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ProductBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
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
        case 'likesCount':
          result.likesCount = serializers.deserialize(value,
              specifiedType: const FullType(int))! as int;
          break;
        case 'likedByMe':
          result.likedByMe = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
        case 'langsPrioritized':
          result.langsPrioritized.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(LangCode)]))!
              as BuiltList<Object?>);
          break;
        case 'brands':
          result.brands.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(String)]))!
              as BuiltList<Object?>);
          break;
        case 'nameLangs':
          result.nameLangs.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap,
                  const [const FullType(LangCode), const FullType(String)]))!);
          break;
        case 'ingredientsTextLangs':
          result.ingredientsTextLangs.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap,
                  const [const FullType(LangCode), const FullType(String)]))!);
          break;
        case 'imageFrontLangs':
          result.imageFrontLangs.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap,
                  const [const FullType(LangCode), const FullType(Uri)]))!);
          break;
        case 'imageFrontThumbLangs':
          result.imageFrontThumbLangs.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap,
                  const [const FullType(LangCode), const FullType(Uri)]))!);
          break;
        case 'imageIngredientsLangs':
          result.imageIngredientsLangs.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap,
                  const [const FullType(LangCode), const FullType(Uri)]))!);
          break;
        case 'ingredientsAnalyzedLangs':
          result.ingredientsAnalyzedLangs.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(LangCode),
                const FullType(BuiltList, const [const FullType(Ingredient)])
              ]))!);
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
  final VegStatus? veganStatus;
  @override
  final VegStatusSource? veganStatusSource;
  @override
  final BuiltList<int> moderatorVeganChoiceReasonsIds;
  @override
  final String? moderatorVeganSourcesText;
  @override
  final int likesCount;
  @override
  final bool likedByMe;
  @override
  final BuiltList<LangCode> langsPrioritized;
  @override
  final BuiltList<String>? brands;
  @override
  final BuiltMap<LangCode, String> nameLangs;
  @override
  final BuiltMap<LangCode, String> ingredientsTextLangs;
  @override
  final BuiltMap<LangCode, Uri> imageFrontLangs;
  @override
  final BuiltMap<LangCode, Uri> imageFrontThumbLangs;
  @override
  final BuiltMap<LangCode, Uri> imageIngredientsLangs;
  @override
  final BuiltMap<LangCode, BuiltList<Ingredient>> ingredientsAnalyzedLangs;

  factory _$Product([void Function(ProductBuilder)? updates]) =>
      (new ProductBuilder()..update(updates))._build();

  _$Product._(
      {required this.barcode,
      this.veganStatus,
      this.veganStatusSource,
      required this.moderatorVeganChoiceReasonsIds,
      this.moderatorVeganSourcesText,
      required this.likesCount,
      required this.likedByMe,
      required this.langsPrioritized,
      this.brands,
      required this.nameLangs,
      required this.ingredientsTextLangs,
      required this.imageFrontLangs,
      required this.imageFrontThumbLangs,
      required this.imageIngredientsLangs,
      required this.ingredientsAnalyzedLangs})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(barcode, r'Product', 'barcode');
    BuiltValueNullFieldError.checkNotNull(moderatorVeganChoiceReasonsIds,
        r'Product', 'moderatorVeganChoiceReasonsIds');
    BuiltValueNullFieldError.checkNotNull(likesCount, r'Product', 'likesCount');
    BuiltValueNullFieldError.checkNotNull(likedByMe, r'Product', 'likedByMe');
    BuiltValueNullFieldError.checkNotNull(
        langsPrioritized, r'Product', 'langsPrioritized');
    BuiltValueNullFieldError.checkNotNull(nameLangs, r'Product', 'nameLangs');
    BuiltValueNullFieldError.checkNotNull(
        ingredientsTextLangs, r'Product', 'ingredientsTextLangs');
    BuiltValueNullFieldError.checkNotNull(
        imageFrontLangs, r'Product', 'imageFrontLangs');
    BuiltValueNullFieldError.checkNotNull(
        imageFrontThumbLangs, r'Product', 'imageFrontThumbLangs');
    BuiltValueNullFieldError.checkNotNull(
        imageIngredientsLangs, r'Product', 'imageIngredientsLangs');
    BuiltValueNullFieldError.checkNotNull(
        ingredientsAnalyzedLangs, r'Product', 'ingredientsAnalyzedLangs');
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
        veganStatus == other.veganStatus &&
        veganStatusSource == other.veganStatusSource &&
        moderatorVeganChoiceReasonsIds ==
            other.moderatorVeganChoiceReasonsIds &&
        moderatorVeganSourcesText == other.moderatorVeganSourcesText &&
        likesCount == other.likesCount &&
        likedByMe == other.likedByMe &&
        langsPrioritized == other.langsPrioritized &&
        brands == other.brands &&
        nameLangs == other.nameLangs &&
        ingredientsTextLangs == other.ingredientsTextLangs &&
        imageFrontLangs == other.imageFrontLangs &&
        imageFrontThumbLangs == other.imageFrontThumbLangs &&
        imageIngredientsLangs == other.imageIngredientsLangs &&
        ingredientsAnalyzedLangs == other.ingredientsAnalyzedLangs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, barcode.hashCode);
    _$hash = $jc(_$hash, veganStatus.hashCode);
    _$hash = $jc(_$hash, veganStatusSource.hashCode);
    _$hash = $jc(_$hash, moderatorVeganChoiceReasonsIds.hashCode);
    _$hash = $jc(_$hash, moderatorVeganSourcesText.hashCode);
    _$hash = $jc(_$hash, likesCount.hashCode);
    _$hash = $jc(_$hash, likedByMe.hashCode);
    _$hash = $jc(_$hash, langsPrioritized.hashCode);
    _$hash = $jc(_$hash, brands.hashCode);
    _$hash = $jc(_$hash, nameLangs.hashCode);
    _$hash = $jc(_$hash, ingredientsTextLangs.hashCode);
    _$hash = $jc(_$hash, imageFrontLangs.hashCode);
    _$hash = $jc(_$hash, imageFrontThumbLangs.hashCode);
    _$hash = $jc(_$hash, imageIngredientsLangs.hashCode);
    _$hash = $jc(_$hash, ingredientsAnalyzedLangs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Product')
          ..add('barcode', barcode)
          ..add('veganStatus', veganStatus)
          ..add('veganStatusSource', veganStatusSource)
          ..add(
              'moderatorVeganChoiceReasonsIds', moderatorVeganChoiceReasonsIds)
          ..add('moderatorVeganSourcesText', moderatorVeganSourcesText)
          ..add('likesCount', likesCount)
          ..add('likedByMe', likedByMe)
          ..add('langsPrioritized', langsPrioritized)
          ..add('brands', brands)
          ..add('nameLangs', nameLangs)
          ..add('ingredientsTextLangs', ingredientsTextLangs)
          ..add('imageFrontLangs', imageFrontLangs)
          ..add('imageFrontThumbLangs', imageFrontThumbLangs)
          ..add('imageIngredientsLangs', imageIngredientsLangs)
          ..add('ingredientsAnalyzedLangs', ingredientsAnalyzedLangs))
        .toString();
  }
}

class ProductBuilder implements Builder<Product, ProductBuilder> {
  _$Product? _$v;

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

  int? _likesCount;
  int? get likesCount => _$this._likesCount;
  set likesCount(int? likesCount) => _$this._likesCount = likesCount;

  bool? _likedByMe;
  bool? get likedByMe => _$this._likedByMe;
  set likedByMe(bool? likedByMe) => _$this._likedByMe = likedByMe;

  ListBuilder<LangCode>? _langsPrioritized;
  ListBuilder<LangCode> get langsPrioritized =>
      _$this._langsPrioritized ??= new ListBuilder<LangCode>();
  set langsPrioritized(ListBuilder<LangCode>? langsPrioritized) =>
      _$this._langsPrioritized = langsPrioritized;

  ListBuilder<String>? _brands;
  ListBuilder<String> get brands =>
      _$this._brands ??= new ListBuilder<String>();
  set brands(ListBuilder<String>? brands) => _$this._brands = brands;

  MapBuilder<LangCode, String>? _nameLangs;
  MapBuilder<LangCode, String> get nameLangs =>
      _$this._nameLangs ??= new MapBuilder<LangCode, String>();
  set nameLangs(MapBuilder<LangCode, String>? nameLangs) =>
      _$this._nameLangs = nameLangs;

  MapBuilder<LangCode, String>? _ingredientsTextLangs;
  MapBuilder<LangCode, String> get ingredientsTextLangs =>
      _$this._ingredientsTextLangs ??= new MapBuilder<LangCode, String>();
  set ingredientsTextLangs(
          MapBuilder<LangCode, String>? ingredientsTextLangs) =>
      _$this._ingredientsTextLangs = ingredientsTextLangs;

  MapBuilder<LangCode, Uri>? _imageFrontLangs;
  MapBuilder<LangCode, Uri> get imageFrontLangs =>
      _$this._imageFrontLangs ??= new MapBuilder<LangCode, Uri>();
  set imageFrontLangs(MapBuilder<LangCode, Uri>? imageFrontLangs) =>
      _$this._imageFrontLangs = imageFrontLangs;

  MapBuilder<LangCode, Uri>? _imageFrontThumbLangs;
  MapBuilder<LangCode, Uri> get imageFrontThumbLangs =>
      _$this._imageFrontThumbLangs ??= new MapBuilder<LangCode, Uri>();
  set imageFrontThumbLangs(MapBuilder<LangCode, Uri>? imageFrontThumbLangs) =>
      _$this._imageFrontThumbLangs = imageFrontThumbLangs;

  MapBuilder<LangCode, Uri>? _imageIngredientsLangs;
  MapBuilder<LangCode, Uri> get imageIngredientsLangs =>
      _$this._imageIngredientsLangs ??= new MapBuilder<LangCode, Uri>();
  set imageIngredientsLangs(MapBuilder<LangCode, Uri>? imageIngredientsLangs) =>
      _$this._imageIngredientsLangs = imageIngredientsLangs;

  MapBuilder<LangCode, BuiltList<Ingredient>>? _ingredientsAnalyzedLangs;
  MapBuilder<LangCode, BuiltList<Ingredient>> get ingredientsAnalyzedLangs =>
      _$this._ingredientsAnalyzedLangs ??=
          new MapBuilder<LangCode, BuiltList<Ingredient>>();
  set ingredientsAnalyzedLangs(
          MapBuilder<LangCode, BuiltList<Ingredient>>?
              ingredientsAnalyzedLangs) =>
      _$this._ingredientsAnalyzedLangs = ingredientsAnalyzedLangs;

  ProductBuilder();

  ProductBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _barcode = $v.barcode;
      _veganStatus = $v.veganStatus;
      _veganStatusSource = $v.veganStatusSource;
      _moderatorVeganChoiceReasonsIds =
          $v.moderatorVeganChoiceReasonsIds.toBuilder();
      _moderatorVeganSourcesText = $v.moderatorVeganSourcesText;
      _likesCount = $v.likesCount;
      _likedByMe = $v.likedByMe;
      _langsPrioritized = $v.langsPrioritized.toBuilder();
      _brands = $v.brands?.toBuilder();
      _nameLangs = $v.nameLangs.toBuilder();
      _ingredientsTextLangs = $v.ingredientsTextLangs.toBuilder();
      _imageFrontLangs = $v.imageFrontLangs.toBuilder();
      _imageFrontThumbLangs = $v.imageFrontThumbLangs.toBuilder();
      _imageIngredientsLangs = $v.imageIngredientsLangs.toBuilder();
      _ingredientsAnalyzedLangs = $v.ingredientsAnalyzedLangs.toBuilder();
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
  Product build() => _build();

  _$Product _build() {
    Product._defaults(this);
    _$Product _$result;
    try {
      _$result = _$v ??
          new _$Product._(
              barcode: BuiltValueNullFieldError.checkNotNull(
                  barcode, r'Product', 'barcode'),
              veganStatus: veganStatus,
              veganStatusSource: veganStatusSource,
              moderatorVeganChoiceReasonsIds:
                  moderatorVeganChoiceReasonsIds.build(),
              moderatorVeganSourcesText: moderatorVeganSourcesText,
              likesCount: BuiltValueNullFieldError.checkNotNull(
                  likesCount, r'Product', 'likesCount'),
              likedByMe: BuiltValueNullFieldError.checkNotNull(
                  likedByMe, r'Product', 'likedByMe'),
              langsPrioritized: langsPrioritized.build(),
              brands: _brands?.build(),
              nameLangs: nameLangs.build(),
              ingredientsTextLangs: ingredientsTextLangs.build(),
              imageFrontLangs: imageFrontLangs.build(),
              imageFrontThumbLangs: imageFrontThumbLangs.build(),
              imageIngredientsLangs: imageIngredientsLangs.build(),
              ingredientsAnalyzedLangs: ingredientsAnalyzedLangs.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'moderatorVeganChoiceReasonsIds';
        moderatorVeganChoiceReasonsIds.build();

        _$failedField = 'langsPrioritized';
        langsPrioritized.build();
        _$failedField = 'brands';
        _brands?.build();
        _$failedField = 'nameLangs';
        nameLangs.build();
        _$failedField = 'ingredientsTextLangs';
        ingredientsTextLangs.build();
        _$failedField = 'imageFrontLangs';
        imageFrontLangs.build();
        _$failedField = 'imageFrontThumbLangs';
        imageFrontThumbLangs.build();
        _$failedField = 'imageIngredientsLangs';
        imageIngredientsLangs.build();
        _$failedField = 'ingredientsAnalyzedLangs';
        ingredientsAnalyzedLangs.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'Product', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
