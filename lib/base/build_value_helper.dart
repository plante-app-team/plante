import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:untitled_vegan_app/model/ingredient.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';
import 'package:untitled_vegan_app/outside/backend/backend_product.dart';

part 'build_value_helper.g.dart';

@SerializersFor([
  UserParams,
  BackendProduct,
  VegStatus,
  VegStatusSource,
  Product,
  Ingredient,
])
final Serializers _serializers = _$_serializers;
final _jsonSerializers =
(_serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

class BuildValueHelper {
  static final Serializers serializers = _serializers;
  static final jsonSerializers = _jsonSerializers;
}
