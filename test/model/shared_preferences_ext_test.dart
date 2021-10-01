import 'dart:math';

import 'package:plante/model/shared_preferences_ext.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final controller = UserParamsController();
    await controller.setUserParams(null);
  });

  test('can save and restore a point', () async {
    const myKey = 'shared_preferences_ext_test key 1';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(myKey)) {
      await prefs.remove(myKey);
    }

    const point = Point<double>(123.123, 321.321);
    await prefs.setPoint(myKey, point);

    final obtainedPoint = prefs.getPoint(myKey);
    expect(obtainedPoint, equals(point));
  });

  test('corrupted point not restored and erased', () async {
    const myKey = 'shared_preferences_ext_test key 2';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(myKey)) {
      await prefs.remove(myKey);
    }

    const point = Point<double>(123.123, 321.321);
    await prefs.setPoint(myKey, point);

    // Corrupt!
    await prefs.setString(myKey, 'oopsie doopsie');

    // Not erased yet
    expect(prefs.get(myKey), isNotNull);
    // Not restored
    final obtainedPoint = prefs.getPoint(myKey);
    expect(obtainedPoint, isNull);
    // Erased!
    expect(prefs.get(myKey), isNull);
  });
}
