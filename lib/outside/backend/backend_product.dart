import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';

part 'backend_product.g.dart';

abstract class BackendProduct
    implements Built<BackendProduct, BackendProductBuilder> {
  static final BackendProduct empty = BackendProduct();

  @BuiltValueField(wireName: 'server_id')
  int? get serverId;
  @BuiltValueField(wireName: 'barcode')
  String get barcode;

  @BuiltValueField(wireName: 'vegan_status')
  String? get veganStatus;
  @BuiltValueField(wireName: 'vegan_status_source')
  String? get veganStatusSource;

  @BuiltValueField(wireName: 'moderator_vegan_choice_reasons')
  String? get moderatorVeganChoiceReasons;
  @BuiltValueField(wireName: 'moderator_vegan_sources_text')
  String? get moderatorVeganSourcesText;

  static BackendProduct? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(BackendProduct.serializer, json);
  }

  factory BackendProduct([void Function(BackendProductBuilder) updates]) =
      _$BackendProduct;
  BackendProduct._();
  static Serializer<BackendProduct> get serializer =>
      _$backendProductSerializer;
}
