import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/model/user_params_controller.dart';

typedef UserParamsCreatedCallback = void Function(UserParams userParams);

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  UserParams? _userParams;

  @override
  void initState() {
    super.initState();
    _initUserParams();
  }

  void _initUserParams() async {
    final userParams = await GetIt.I.get<UserParamsController>().getUserParams();
    setState(() {
      _userParams = userParams;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main page'),
      ),
      body: Center(
        child: Text(_greetingMessage()),
      )
    );
  }

  String _greetingMessage() {
    final yeehaa = 'Yeee haaaaaaa!';
    if (_userParams == null) {
      return yeehaa;
    }
    return yeehaa + '\nHello, ${_userParams!.name}!';
  }
}
