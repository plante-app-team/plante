import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/contributions/user_contribution_type.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

part 'user_contribution.g.dart';

abstract class UserContribution
    implements Built<UserContribution, UserContributionBuilder> {
  @BuiltValueField(wireName: 'time_utc')
  int get timeSecsUtc;
  @BuiltValueField(wireName: 'type')
  int get typeCode;
  @BuiltValueField(wireName: 'barcode')
  String? get barcode;
  @BuiltValueField(wireName: 'shop_uid')
  OsmUID? get osmUID;

  DateTime get time => dateTimeFromSecondsSinceEpoch(timeSecsUtc);
  UserContributionType get type => userContributionTypeFromCode(typeCode);

  static UserContribution create(UserContributionType type, DateTime time,
      {String? barcode, OsmUID? osmUID}) {
    return UserContribution((e) => e
      ..timeSecsUtc = time.secondsSinceEpoch
      ..typeCode = type.persistentCode
      ..barcode = barcode
      ..osmUID = osmUID);
  }

  static UserContribution? fromJson(Map<dynamic, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(UserContribution.serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers.serializeWith(
        UserContribution.serializer, this)! as Map<String, dynamic>;
  }

  factory UserContribution([void Function(UserContributionBuilder) updates]) =
      _$UserContribution;
  UserContribution._();
  static Serializer<UserContribution> get serializer =>
      _$userContributionSerializer;
}
