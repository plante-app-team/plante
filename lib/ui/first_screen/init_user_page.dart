import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled_vegan_app/base/date_time_extensions.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';
import 'package:untitled_vegan_app/model/gender.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/ui/base/general_date_Input_formatter.dart';
import 'package:untitled_vegan_app/ui/base/stepper/customizable_stepper.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';

typedef UserParamsSpecifiedCallback = void Function(UserParams userParams);

class InitUserPage extends StatefulWidget {
  final UserParams? initialUserParams;
  final UserParamsSpecifiedCallback callback;

  InitUserPage(this.initialUserParams, this.callback);

  @override
  _InitUserPageState createState() =>
      _InitUserPageState(initialUserParams, callback);
}

class _InitUserPageState extends State<InitUserPage> {
  final UserParams? _initialUserParams;
  final UserParamsSpecifiedCallback _resultCallback;

  final _stepperController = CustomizableStepperController();

  static const _minUserBirthYear = 1900;
  static const _minUserAge = 16;
  static const _minNameLength = 3;
  static final _dateFormat = DateFormat('dd.MM.yyyy');
  Gender? _selectedGender;
  var _eatsMilk = false;
  var _eatsEggs = false;
  var _eatsHoney = false;
  bool get _eatsVeggiesOnly {
    return !_eatsMilk && !_eatsEggs && !_eatsHoney;
  }

  final _nameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _birthdayInputFormatter = GeneralDateInputFormatter(
      _minUserBirthYear, DateTime.now().minusYears(_minUserAge).year);

  var _firstPageHasData = false;

  _InitUserPageState(this._initialUserParams, this._resultCallback);

  @override
  void initState() {
    super.initState();
    _nameController.text = _initialUserParams?.name ?? "";
    assert(_initialUserParams?.gender == null);
    assert(_initialUserParams?.birthday == null);
    assert(_initialUserParams?.eatsMilk == null);
    assert(_initialUserParams?.eatsEggs == null);
    assert(_initialUserParams?.eatsHoney == null);

    _nameController.addListener(() {
      _validateFirstPageInputs();
    });
    _birthdayController.addListener(() {
      _validateFirstPageInputs();
    });
    _validateFirstPageInputs();
  }

  void _validateFirstPageInputs() {
    final firstPageHasData = _calcFirstPageHasData();
    if (firstPageHasData != _firstPageHasData) {
      setState(() {
        _firstPageHasData = firstPageHasData;
      });
    }
  }

  bool _calcFirstPageHasData() {
    if (_nameController.text.trim().length < _minNameLength) {
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
        body: SafeArea(child: CustomizableStepper(
          pages: [_page1(), _page2()],
          controller: _stepperController,
          contentPadding: EdgeInsets.only(left: 50, right: 50),
        ))
    );
  }

  StepperPage _page1() {
    final content = Column(children: [
          Expanded(
            flex: 1,
            child: Center(child: Text(
              context.strings.init_user_page_title,
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
                Expanded(child: TextField(
                  key: Key("birthday"),
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: context.strings.init_user_page_birthday_field_hint,
                    labelText: context.strings.init_user_page_birthday_field_title,
                  ),
                  controller: _birthdayController,
                  inputFormatters: [_birthdayInputFormatter],
                )),
                Row(children: [
                  InkWell(
                    child: Text(context.strings.init_user_page_gender_short_male),
                    onTap: () {
                      setState(() { _selectedGender = Gender.MALE; });
                    }),
                  Radio<Gender>(
                    value: Gender.MALE,
                    groupValue: _selectedGender,
                    onChanged: (Gender? value) {
                      setState(() { _selectedGender = value; });
                    },
                  ),
                  InkWell(
                      child: Text(context.strings.init_user_page_gender_short_female),
                      onTap: () {
                        setState(() { _selectedGender = Gender.FEMALE; });
                      }),
                  Radio<Gender>(
                    value: Gender.FEMALE,
                    groupValue: _selectedGender,
                    onChanged: (Gender? value) {
                      setState(() { _selectedGender = value; });
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
          onPressed: _firstPageHasData ? onNextPressed : null));

    return StepperPage(content, buttonNext);
  }

  StepperPage _page2() {
    final onVegetablesCheckboxClick = (bool? value) {
      setState(() {
        _eatsMilk = value != null ? !value : false;
        _eatsEggs = value != null ? !value : false;
        _eatsHoney = value != null ? !value : false;
      });
    };
    final onMilkCheckboxClick = (bool? value) {
      setState(() { _eatsMilk = value ?? false; });
    };
    final onEggsCheckboxClick = (bool? value) {
      setState(() { _eatsEggs = value ?? false; });
    };
    final onHoneyCheckboxClick = (bool? value) {
      setState(() { _eatsHoney = value ?? false; });
    };

    final content = Column(children: [
      Expanded(
          flex: 1,
          child: Center(child: Text(
              context.strings.init_user_page_i_eat,
              style: Theme.of(context).textTheme.headline5))),
      Expanded(
          flex: 2,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Checkbox(
                  value: _eatsVeggiesOnly,
                  onChanged: onVegetablesCheckboxClick),
              InkWell(
                  child: Text(context.strings.init_user_page_i_eat_veggies_only),
                  onTap: () { onVegetablesCheckboxClick(!_eatsVeggiesOnly); }),
            ]),
            Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Checkbox(value: _eatsMilk, onChanged: onMilkCheckboxClick),
              InkWell(
                child: Text(context.strings.init_user_page_i_eat_milk),
                onTap: () { onMilkCheckboxClick(!_eatsMilk); }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Checkbox(value: _eatsEggs, onChanged: onEggsCheckboxClick),
              InkWell(
                child: Text(context.strings.init_user_page_i_eat_eggs),
                onTap: () { onEggsCheckboxClick(!_eatsEggs); }),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Checkbox(value: _eatsHoney, onChanged: onHoneyCheckboxClick),
              InkWell(
                  child: Text(context.strings.init_user_page_i_eat_honey),
                  onTap: () { onHoneyCheckboxClick(!_eatsHoney); }),
            ])
          ]))
    ]);

    final buttonNext = SizedBox(
        width: double.infinity,
        child: OutlinedButton(
            child: Text(context.strings.init_user_page_done_button_title),
            onPressed: () {
              final name = _nameController.text;
              DateTime? birthday;
              try {
                birthday = _dateFormat.parse(_birthdayController.text);
              } catch (FormatException) {
                // It's ok, birthday might be not specified
              }
              final params = UserParams(
                  name,
                  gender: _selectedGender,
                  birthday: birthday,
                  eatsMilk: _eatsMilk,
                  eatsEggs: _eatsEggs,
                  eatsHoney: _eatsHoney);
              _resultCallback.call(params);
            }));

    return StepperPage(content, buttonNext);
  }
}
