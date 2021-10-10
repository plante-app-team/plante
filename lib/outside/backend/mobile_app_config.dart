import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';

part 'mobile_app_config.g.dart';

abstract class MobileAppConfig
    implements Built<MobileAppConfig, MobileAppConfigBuilder> {
  /// PLEASE USE [UserParamsController] INSTEAD OF TOUCHING THIS FIELD.
  /// User params as are (or were) stored on the backed.
  @BuiltValueField(wireName: 'user_data')
  UserParams get remoteUserParams;
  @BuiltValueField(wireName: 'nominatim_enabled')
  bool get nominatimEnabled;

  MobileAppConfig rebuildWithUserParams(UserParams userParams) {
    return rebuild((e) => e.remoteUserParams.replace(userParams));
  }

  static MobileAppConfig? fromJson(dynamic json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(MobileAppConfig.serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers.serializeWith(serializer, this)!
        as Map<String, dynamic>;
  }

  factory MobileAppConfig([void Function(MobileAppConfigBuilder) updates]) =
      _$MobileAppConfig;
  MobileAppConfig._();
  static Serializer<MobileAppConfig> get serializer =>
      _$mobileAppConfigSerializer;
}
