import 'package:test/test.dart';
import 'package:untitled_vegan_app/model/gender.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/model/user_params_controller.dart';

void main() {
  setUp(() async {
    final controller = UserParamsController();
    await controller.setUserParams(null);
  });

  test('Save and restore params', () async {
    final controller = UserParamsController();
    final initialParams = await controller.getUserParams();
    expect(initialParams, equals(null));

    final params = UserParams(
        "Bob",
        gender: Gender.MALE,
        birthday: DateTime.now(),
        eatsMilk: true,
        eatsEggs: false,
        eatsHoney: true);
    await controller.setUserParams(params);

    final finalParams = await controller.getUserParams();
    expect(finalParams, equals(params));
  });

  test('Gradual parameters filling', () async {
    final controller = UserParamsController();

    var params = UserParams("");
    await controller.setUserParams(params);
    expect(params, equals(await controller.getUserParams()));

    params = UserParams("Bob");
    await controller.setUserParams(params);
    expect(params, equals(await controller.getUserParams()));

    params = UserParams("Bob", birthday: DateTime.now());
    await controller.setUserParams(params);
    expect(params, equals(await controller.getUserParams()));

    params = UserParams("Bob", birthday: DateTime.now(), eatsMilk: true);
    await controller.setUserParams(params);
    expect(params, equals(await controller.getUserParams()));

    params = UserParams(
        "Bob",
        birthday: DateTime.now(),
        eatsMilk: true,
        eatsEggs: false);
    await controller.setUserParams(params);
    expect(params, equals(await controller.getUserParams()));

    params = UserParams("Bob",
        birthday: DateTime.now(),
        eatsMilk: true,
        eatsEggs: false,
        eatsHoney: true);
    await controller.setUserParams(params);
    expect(params, equals(await controller.getUserParams()));

    params = UserParams("Bob",
        birthday: DateTime.now(),
        eatsMilk: true,
        eatsEggs: false,
        eatsHoney: true,
        gender: Gender.FEMALE);
    await controller.setUserParams(params);
    expect(params, equals(await controller.getUserParams()));
  });
}
