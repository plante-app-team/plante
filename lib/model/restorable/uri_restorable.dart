import 'package:flutter/widgets.dart';
import 'package:plante/logging/log.dart';

class UriRestorable extends RestorableValue<Uri?> {
  final Uri? _defaultValue;

  UriRestorable(this._defaultValue);

  @override
  Uri? createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(Uri? oldValue) {
    notifyListeners();
  }

  @override
  Uri? fromPrimitives(Object? data) {
    if (data == '') {
      return null;
    }
    if (data != null && data is String) {
      final result = Uri.tryParse(data);
      if (result != null) {
        return result;
      }
    }
    Log.w('UriRestorable could not restore from $data');
    return createDefaultValue();
  }

  @override
  Object toPrimitives() {
    if (value == null) {
      return '';
    }
    return value.toString();
  }
}
