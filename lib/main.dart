import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/di.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/ui/main/main_page.dart';
import 'package:untitled_vegan_app/ui/user_params/user_params_page.dart';
import 'package:untitled_vegan_app/model/user_params_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDI();
  final initialUserParams = await GetIt.I.get<UserParamsController>().getUserParams();
  runApp(MyApp(initialUserParams));
}

class MyApp extends StatefulWidget {
  final UserParams? _initialUserParams;

  MyApp(this._initialUserParams);

  @override
  State<StatefulWidget> createState() => (_MyAppState(_initialUserParams));
}

class _MyAppState extends State<MyApp> {
  UserParams? _initialUserParams;

  _MyAppState(this._initialUserParams);

  void _onUserParamsSpecified(UserParams params) async {
    await GetIt.I.get<UserParamsController>().setUserParams(params);
    setState(() {
      _initialUserParams = params;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: _initialUserParams != null
          ? MainPage()
          : UserParamsPage(_onUserParamsSpecified),
    );
  }
}
