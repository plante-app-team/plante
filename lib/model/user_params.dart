import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:intl/intl.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/gender.dart';

part 'user_params.g.dart';

abstract class UserParams implements Built<UserParams, UserParamsBuilder> {
  @BuiltValueField(wireName: 'user_id')
  String? get backendId;
  @BuiltValueField(wireName: 'client_token')
  String? get backendClientToken;
  @BuiltValueField(wireName: 'name')
  String? get name;
  @BuiltValueField(wireName: 'gender')
  String? get genderStr;
  @BuiltValueField(wireName: 'birthday')
  String? get birthdayStr;
  @BuiltValueField(wireName: 'eats_milk')
  bool? get eatsMilk;
  @BuiltValueField(wireName: 'eats_eggs')
  bool? get eatsEggs;
  @BuiltValueField(wireName: 'eats_honey')
  bool? get eatsHoney;
  @BuiltValueField(wireName: 'rights_group')
  int? get userGroup;

  bool? get eatsVeggiesOnly {
    if (eatsMilk == null && eatsEggs == null && eatsHoney == null) {
      return null;
    }
    return !((eatsMilk == true) || (eatsEggs == true) || (eatsHoney == true));
  }

  Gender? get gender {
    if (genderStr == null) {
      return null;
    }
    return genderFromGenderName(genderStr!);
  }

  DateTime? get birthday {
    if (birthdayStr == null) {
      return null;
    }
    try {
      return DateFormat('dd.MM.yyyy').parse(birthdayStr!);
    } on FormatException {
      return null;
    }
  }

  String requireBackendID() => backendId!;
  String requireBackendClientToken() => backendClientToken!;

  static UserParams? fromJson(Map<String, dynamic> json) {
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
