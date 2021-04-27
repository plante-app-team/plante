import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/stepper/customizable_stepper.dart';
import 'package:plante/ui/base/stepper/stepper_page.dart';
import 'package:plante/ui/base/text_styles.dart';

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

  final _nameController = TextEditingController();

  var _firstPageHasData = false;

  bool? get isVegan => _userParams.eatsVeggiesOnly;
  set isVegan(bool? value) {
    if (isVegan == value) {
      return;
    }
    setState(() {
      if (value == null) {
        _userParams = _userParams.rebuild((e) => e
          ..eatsEggs = null
          ..eatsMilk = null
          ..eatsHoney = null);
      } else {
        _userParams = _userParams.rebuild((e) => e
          ..eatsEggs = !value
          ..eatsMilk = !value
          ..eatsHoney = !value);
      }
    });
  }

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
    return InitUserPage.minNameLength <= _nameController.text.trim().length;
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
        contentPadding: EdgeInsets.only(left: 26, right: 26, top: 45),
      )
    ])));
  }

  StepperPage _page1() {
    final content = Column(children: [
      Expanded(
        child: Stack(children: [
          Center(
              child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 132),
                      child: Text(context.strings.init_user_page_title,
                          style: TextStyles.headline1)))),
          Center(
              child: InputFieldPlante(
            key: Key("name"),
            textCapitalization: TextCapitalization.sentences,
            label: context.strings.init_user_page_name_field_title,
            controller: _nameController,
          ))
        ]),
      ),
    ]);

    final onNextPressed = () {
      FocusScope.of(context).unfocus();
      _stepperController.stepForward();
    };

    final buttonNext = SizedBox(
        width: double.infinity,
        child: ButtonFilledPlante.withText(
            context.strings.init_user_page_next_button_title,
            onPressed: _firstPageHasData && !_loading ? onNextPressed : null));

    final bottomControls =
        Padding(child: buttonNext, padding: EdgeInsets.only(bottom: 38));

    return StepperPage(content, bottomControls);
  }

  StepperPage _page2() {
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

    final content = Column(mainAxisSize: MainAxisSize.max, children: [
      SizedBox(height: 35),
      SizedBox(
          width: double.infinity,
          child: Text(
              context.strings.init_user_page_nice_to_meet_you +
                  _nameController.text,
              style: TextStyles.headline1)),
      SizedBox(height: 24),
      SizedBox(
          width: double.infinity,
          child: Text(context.strings.init_user_page_tell_about_yourself,
              style: TextStyles.headline2)),
      SizedBox(height: 16),
      InkWell(
        child: Container(
            color: Color(0xFFF6F7FA),
            height: 48,
            child: Row(children: [
              Radio<bool>(
                  value: true,
                  groupValue: isVegan,
                  onChanged: (bool? value) {
                    isVegan = value;
                  }),
              Text(context.strings.init_user_page_im_vegan,
                  style: TextStyles.normal)
            ])),
        onTap: () {
          isVegan = true;
        },
      ),
      SizedBox(height: 7),
      InkWell(
        child: Container(
            color: Color(0xFFF6F7FA),
            height: 48,
            child: Row(children: [
              Radio<bool>(
                  value: false,
                  groupValue: isVegan,
                  onChanged: (bool? value) {
                    if (value == null) {
                      isVegan = null;
                    } else {
                      isVegan = !value;
                    }
                  }),
              Text(context.strings.init_user_page_im_vegetarian,
                  style: TextStyles.normal)
            ])),
        onTap: () {
          isVegan = false;
        },
      ),
      SizedBox(height: 24),
      SizedBox(
          width: double.infinity,
          child: Text(context.strings.init_user_page_what_do_you_eat,
              style: TextStyles.normal)),
      SizedBox(height: 21),
      Container(
          color: Color(0xFFF6F7FA),
          height: 48,
          child: Row(children: [
            InkWell(
                child: Row(children: [
                  Checkbox(
                      value: _userParams.eatsEggs ?? false,
                      onChanged: onEggsCheckboxClick),
                  Text(context.strings.init_user_page_i_eat_eggs),
                ]),
                onTap: () {
                  onEggsCheckboxClick(!(_userParams.eatsEggs ?? false));
                }),
            SizedBox(width: 24),
            InkWell(
                child: Row(children: [
                  Checkbox(
                      value: _userParams.eatsMilk ?? false,
                      onChanged: onMilkCheckboxClick),
                  Text(context.strings.init_user_page_i_eat_milk),
                ]),
                onTap: () {
                  onMilkCheckboxClick(!(_userParams.eatsMilk ?? false));
                }),
            SizedBox(width: 24),
            InkWell(
                child: Row(children: [
                  Checkbox(
                      value: _userParams.eatsHoney ?? false,
                      onChanged: onHoneyCheckboxClick),
                  Text(context.strings.init_user_page_i_eat_honey),
                ]),
                onTap: () {
                  onHoneyCheckboxClick(!(_userParams.eatsHoney ?? false));
                }),
          ])),
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

    final buttonDone = SizedBox(
        width: double.infinity,
        child: ButtonFilledPlante.withText(
            context.strings.init_user_page_done_button_title,
            onPressed: !_loading && isVegan != null ? onDoneClicked : null));

    final bottomControls =
        Padding(child: buttonDone, padding: EdgeInsets.only(bottom: 38));

    return StepperPage(content, bottomControls);
  }
}
