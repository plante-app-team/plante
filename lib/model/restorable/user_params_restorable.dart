import 'package:flutter/widgets.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_params.dart';

class UserParamsRestorable extends RestorableValue<UserParams> {
  final UserParams _defaultValue;

  UserParamsRestorable(this._defaultValue);

  @override
  UserParams createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(UserParams? oldValue) {
    notifyListeners();
  }

  @override
  UserParams fromPrimitives(Object? data) {
    if (data != null && data is Map<dynamic, dynamic>) {
      return UserParams.fromJson(data)!;
    }
    Log.w('UserParamsRestorable could not restore from $data');
    return createDefaultValue();
  }

  @override
  Object toPrimitives() {
    return value.toJson();
  }
}
