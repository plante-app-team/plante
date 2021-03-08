import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/model/location_controller.dart';
import 'package:untitled_vegan_app/model/user_params_controller.dart';

void initDI() {
  GetIt.I.registerSingleton<UserParamsController>(UserParamsController());
  GetIt.I.registerSingleton<LocationController>(LocationController());
}
