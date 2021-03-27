import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:untitled_vegan_app/model/user_params.dart';

part 'build_value_helper.g.dart';

@SerializersFor([
  UserParams,
])
final Serializers _serializers = _$_serializers;
final _jsonSerializers =
(_serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

class BuildValueHelper {
  static final Serializers serializers = _serializers;
  static final jsonSerializers = _jsonSerializers;
}
