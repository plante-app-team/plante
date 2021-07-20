import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/lang_code.dart';

part 'user_langs.g.dart';

abstract class UserLangs implements Built<UserLangs, UserLangsBuilder> {
  BuiltList<LangCode> get codes;
  bool get auto;

  static UserLangs? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(UserLangs.serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers
        .serializeWith(UserLangs.serializer, this)! as Map<String, dynamic>;
  }

  factory UserLangs([void Function(UserLangsBuilder) updates]) = _$UserLangs;
  UserLangs._();
  static Serializer<UserLangs> get serializer => _$userLangsSerializer;
}
