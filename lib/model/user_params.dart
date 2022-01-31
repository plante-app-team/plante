import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';

part 'user_params.g.dart';

abstract class UserParams implements Built<UserParams, UserParamsBuilder> {
  @BuiltValueField(wireName: 'user_id')
  String? get backendId;
  @BuiltValueField(wireName: 'client_token')
  String? get backendClientToken;
  @BuiltValueField(wireName: 'name')
  String? get name;
  @BuiltValueField(wireName: 'self_description')
  String? get selfDescription;
  @BuiltValueField(wireName: 'avatar_id')
  String? get avatarId;
  @BuiltValueField(wireName: 'rights_group')
  int? get userGroup;

  /// Please use `UserLangsManager` instead of this field.
  @BuiltValueField(wireName: 'langs_prioritized')
  BuiltList<String>? get langsPrioritized;

  String requireBackendID() => backendId!;
  String requireBackendClientToken() => backendClientToken!;

  static UserParams? fromJson(Map<dynamic, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(UserParams.serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers
        .serializeWith(UserParams.serializer, this)! as Map<String, dynamic>;
  }

  factory UserParams([void Function(UserParamsBuilder) updates]) = _$UserParams;
  UserParams._();
  static Serializer<UserParams> get serializer => _$userParamsSerializer;
}
