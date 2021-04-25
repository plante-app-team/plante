import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/gender.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/general_date_Input_formatter.dart';
import 'package:plante/ui/base/stepper/customizable_stepper.dart';
import 'package:plante/ui/base/stepper/stepper_page.dart';

typedef UserParamsSpecifiedCallback = Future<bool> Function(
    UserParams userParams);

class InitUserPage extends StatefulWidget {
  static const minNameLength = 3;

  final UserParams userParams;
  final UserParamsSpecifiedCallback callback;

  InitUserPage(this.userParams, this.callback);

  @override
  _InitUserPageState createState() => _InitUserPageState(userParams, callback);
}

class _InitUserPageState extends State<InitUserPage> {
  bool _loading = false;

  UserParams _userParams;
  final UserParamsSpecifiedCallback _resultCallback;

  final _stepperController = CustomizableStepperController();

  static const _minUserBirthYear = 1900;
  static const _minUserAge = 16;
  static final _dateFormat = DateFormat('dd.MM.yyyy');

  final _nameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthdayInputFormatter = GeneralDateInputFormatter(
      _minUserBirthYear, DateTime.now().minusYears(_minUserAge).year);

  var _firstPageHasData = false;

  _InitUserPageState(this._userParams, this._resultCallback);

  @override
  void initState() {
    super.initState();
    _nameController.text = _userParams.name ?? "";

    _nameController.addListener(() {
      if (_validateFirstPageInputs()) {
        _userParams = _userParams.rebuild((v) => v.name = _nameController.text);
      }
    });
    _birthdayController.addListener(() {
      if (_validateFirstPageInputs()) {
        if (_birthdayController.text.isNotEmpty) {
          _userParams = _userParams
              .rebuild((v) => v.birthdayStr = _birthdayController.text);
        } else {
          _userParams = _userParams.rebuild((v) => v.birthdayStr = null);
        }
      }
      _validateFirstPageInputs();
      _userParams = _userParams.rebuild((v) => v.name = _nameController.text);
    });
    _validateFirstPageInputs();
  }

  bool _validateFirstPageInputs() {
    final firstPageHasData = _calcFirstPageHasData();
    if (firstPageHasData != _firstPageHasData) {
      setState(() {
        _firstPageHasData = firstPageHasData;
      });
    }
    return firstPageHasData;
  }

  bool _calcFirstPageHasData() {
    if (_nameController.text.trim().length < InitUserPage.minNameLength) {
      return false;
    }
    // No birthday is allowed
    if (_birthdayController.text.isNotEmpty) {
      final DateTime birthday;
      try {
        birthday = _dateFormat.parse(_birthdayController.text);
      } catch (e) {
        return false;
      }
      if (birthday.year < _minUserBirthYear) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Stack(children: [
      if (_loading)
        SizedBox(width: double.infinity, child: LinearProgressIndicator()),
      CustomizableStepper(
        pages: [_page1(), _page2()],
        controller: _stepperController,
        contentPadding: EdgeInsets.only(left: 50, right: 50),
      )
    ])));
  }

  StepperPage _page1() {
    final content = Column(children: [
      Expanded(
          flex: 1,
          child: Center(
              child: Text(context.strings.init_user_page_title,
                  style: Theme.of(context).textTheme.headline5))),
      Expanded(
          flex: 2,
          child: Column(children: [
            TextField(
              key: Key("name"),
              decoration: InputDecoration(
                hintText: context.strings.init_user_page_name_field_hint,
                labelText: context.strings.init_user_page_name_field_title,
              ),
              controller: _nameController,
            ),
            Row(children: [
              Expanded(
                  child: TextField(
                key: Key("birthday"),
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  hintText: context.strings.init_user_page_birthday_field_hint,
                  labelText:
                      context.strings.init_user_page_birthday_field_title,
                ),
                controller: _birthdayController,
                inputFormatters: [_birthdayInputFormatter],
              )),
              Row(children: [
                InkWell(
                    child:
                        Text(context.strings.init_user_page_gender_short_male),
                    onTap: () {
                      setState(() {
                        _userParams = _userParams
                            .rebuild((v) => v.genderStr = Gender.MALE.name);
                      });
                    }),
                Radio<Gender>(
                  value: Gender.MALE,
                  groupValue: _userParams.gender,
                  onChanged: (Gender? value) {
                    setState(() {
                      _userParams =
                          _userParams.rebuild((v) => v.genderStr = value?.name);
                    });
                  },
                ),
                InkWell(
                    child: Text(
                        context.strings.init_user_page_gender_short_female),
                    onTap: () {
                      setState(() {
                        _userParams = _userParams
                            .rebuild((v) => v.genderStr = Gender.FEMALE.name);
                      });
                    }),
                Radio<Gender>(
                  value: Gender.FEMALE,
                  groupValue: _userParams.gender,
                  onChanged: (Gender? value) {
                    setState(() {
                      _userParams =
                          _userParams.rebuild((v) => v.genderStr = value?.name);
                    });
                  },
                )
              ])
            ]),
          ]))
    ]);

    final onNextPressed = () {
      FocusScope.of(context).unfocus();
      _stepperController.stepForward();
    };
    final buttonNext = SizedBox(
        width: double.infinity,
        child: OutlinedButton(
            child: Text(context.strings.init_user_page_next_button_title),
            onPressed: _firstPageHasData && !_loading ? onNextPressed : null));

    return StepperPage(content, buttonNext);
  }

  StepperPage _page2() {
    final onVegetablesCheckboxClick = (bool? value) {
      setState(() {
        _userParams = _userParams.rebuild((v) => v
          ..eatsMilk = value != null ? !value : false
          ..eatsEggs = value != null ? !value : false
          ..eatsHoney = value != null ? !value : false);
      });
    };
    final onMilkCheckboxClick = (bool? value) {
      setState(() {
        _userParams = _userParams
            .rebuild((v) => v..eatsMilk = value != null ? value : false);
      });
    };
    final onEggsCheckboxClick = (bool? value) {
      setState(() {
        _userParams = _userParams
            .rebuild((v) => v..eatsEggs = value != null ? value : false);
      });
    };
    final onHoneyCheckboxClick = (bool? value) {
      setState(() {
        _userParams = _userParams
            .rebuild((v) => v..eatsHoney = value != null ? value : false);
      });
    };

    final content = Column(children: [
      Expanded(
          flex: 1,
          child: Center(
              child: Text(context.strings.init_user_page_i_eat,
                  style: Theme.of(context).textTheme.headline5))),
      Expanded(
          flex: 2,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Checkbox(
                  value: _userParams.eatsVeggiesOnly ?? true,
                  onChanged: onVegetablesCheckboxClick),
              InkWell(
                  child:
                      Text(context.strings.init_user_page_i_eat_veggies_only),
                  onTap: () {
                    onVegetablesCheckboxClick(
                        !(_userParams.eatsVeggiesOnly ?? true));
                  }),
            ]),
            Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Checkbox(
                  value: _userParams.eatsMilk ?? false,
                  onChanged: onMilkCheckboxClick),
              InkWell(
                  child: Text(context.strings.init_user_page_i_eat_milk),
                  onTap: () {
                    onMilkCheckboxClick(!(_userParams.eatsMilk ?? false));
                  }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Checkbox(
                  value: _userParams.eatsEggs ?? false,
                  onChanged: onEggsCheckboxClick),
              InkWell(
                  child: Text(context.strings.init_user_page_i_eat_eggs),
                  onTap: () {
                    onEggsCheckboxClick(!(_userParams.eatsEggs ?? false));
                  }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Checkbox(
                  value: _userParams.eatsHoney ?? false,
                  onChanged: onHoneyCheckboxClick),
              InkWell(
                  child: Text(context.strings.init_user_page_i_eat_honey),
                  onTap: () {
                    onHoneyCheckboxClick(!(_userParams.eatsHoney ?? false));
                  }),
            ])
          ]))
    ]);

    final onDoneClicked = () async {
      _userParams = _userParams.rebuild((v) => v
        ..eatsMilk = _userParams.eatsMilk ?? false
        ..eatsEggs = _userParams.eatsEggs ?? false
        ..eatsHoney = _userParams.eatsHoney ?? false);
      try {
        setState(() {
          _loading = true;
        });
        await _resultCallback.call(_userParams);
      } finally {
        setState(() {
          _loading = false;
        });
      }
    };

    final buttonNext = SizedBox(
        width: double.infinity,
        child: OutlinedButton(
            child: Text(context.strings.init_user_page_done_button_title),
            onPressed: !_loading ? onDoneClicked : null));

    return StepperPage(content, buttonNext);
  }
}
