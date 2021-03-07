import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/ui/GeneralDateInputFormatter.dart';

typedef UserParamsCreatedCallback = void Function(UserParams userParams);

class UserParamsPage extends StatefulWidget {
  final UserParamsCreatedCallback _callback;

  UserParamsPage(this._callback, {Key? key}) : super(key: key);
  @override
  _UserParamsPageState createState() => _UserParamsPageState(_callback);
}

class _UserParamsPageState extends State<UserParamsPage> {
  final UserParamsCreatedCallback _callback;

  static const _minUserBirthYear = 1900;
  static const _minUserAge = 18;
  static final _dateFormat = DateFormat('dd.MM.yyyy');
  var _eatsMilk = false;
  var _eatsEggs = false;
  var _eatsHoney = false;

  final _nameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthdayInputFormatter =
    GeneralDateInputFormatter(_minUserBirthYear, _yearsAgo(_minUserAge).year);

  var _areInputsValid = false;

  /// NOTE: that's a crappy function since it doesn't take into account leap years.
  ///       But for our use-case it's ok.
  static DateTime _yearsAgo(int years) {
    final now = DateTime.now();
    return DateTime(
        now.year - years,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
        now.microsecond);
  }

  _UserParamsPageState(this._callback);
  
  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      _validateInputs();
    });
    _birthdayController.addListener(() {
      _validateInputs();
    });
  }

  void _validateInputs() {
    final areInputsValid = _calcAreInputsValid();
    if (areInputsValid != _areInputsValid) {
      setState(() {
        _areInputsValid = areInputsValid;
      });
    }
  }

  bool _calcAreInputsValid() {
    if (_nameController.text.trim().length < 3) {
      return false;
    }

    final DateTime birthday;
    try {
      birthday = _dateFormat.parse(_birthdayController.text);
    } catch (e) {
      return false;
    }
    if (birthday.year < _minUserBirthYear) {
      return false;
    }

    return true;
  }

  void _onDoneButtonClick() {
    final name = _nameController.text;
    final birthday = _dateFormat.parse(_birthdayController.text);
    final params = UserParams(
        name, birthday.millisecondsSinceEpoch, _eatsMilk, _eatsEggs, _eatsHoney);
    _callback(params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(context.strings.user_params_page_title),
        ),
        body: Padding(
          padding: EdgeInsets.only(left: 10, top: 15, right: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.strings.user_params_page_name_field_title,
                style: Theme.of(context).textTheme.caption,
              ),
              TextField(
                decoration: InputDecoration(hintText: context.strings.user_params_page_name_field_hint),
                controller: _nameController,
              ),

              SizedBox(height: 20),
              Text(
                context.strings.user_params_page_birthday_field_title,
                style: Theme.of(context).textTheme.caption,
              ),
              TextField(
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(hintText: context.strings.user_params_page_birthday_field_hint),
                controller: _birthdayController,
                inputFormatters: [_birthdayInputFormatter],
              ),

              SizedBox(height: 20),
              Text(
                context.strings.user_params_page_i_eat,
                style: Theme.of(context).textTheme.caption,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Column(children: [
                  Text(context.strings.user_params_page_i_eat_milk),
                  Checkbox(value: _eatsMilk, onChanged: (value) {
                    setState(() { _eatsMilk = value ?? false; });
                  })
                ]),
                Column(children: [
                  Text(context.strings.user_params_page_i_eat_eggs),
                  Checkbox(value: _eatsEggs, onChanged: (value) {
                    setState(() { _eatsEggs = value ?? false; });
                  })
                ]),
                Column(children: [
                  Text(context.strings.user_params_page_i_eat_honey),
                  Checkbox(value: _eatsHoney, onChanged: (value) {
                    setState(() { _eatsHoney = value ?? false; });
                  })
                ])
              ]),
              Expanded(
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    child: ElevatedButton(
                      child: Text(context.strings.user_params_page_done_button_title),
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 35)),
                      onPressed: _areInputsValid ? _onDoneButtonClick : null,
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
