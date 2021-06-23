import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/checkbox_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/radio_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/stepper/customizable_stepper.dart';
import 'package:plante/ui/base/stepper/stepper_page.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';

typedef UserParamsSpecifiedCallback = Future<bool> Function(
    UserParams userParams);

class InitUserPage extends StatefulWidget {
  static const MIN_NAME_LENGTH = 3;

  final UserParams userParams;
  final UserParamsSpecifiedCallback callback;

  const InitUserPage(this.userParams, this.callback, {Key? key})
      : super(key: key);

  @override
  _InitUserPageState createState() => _InitUserPageState(userParams, callback);
}

class _InitUserPageState extends PageStatePlante<InitUserPage> {
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

  _InitUserPageState(this._userParams, this._resultCallback)
      : super('InitUserPage');

  @override
  void initState() {
    super.initState();
    _nameController.text = _userParams.name ?? '';
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
    return InitUserPage.MIN_NAME_LENGTH <= _nameController.text.trim().length;
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Stack(children: [
          AnimatedSwitcher(
              duration: DURATION_DEFAULT,
              child: _loading
                  ? const LinearProgressIndicator()
                  : const SizedBox.shrink()),
          CustomizableStepper(
            pages: [_page1(), _page2()],
            controller: _stepperController,
            contentPadding: const EdgeInsets.only(left: 24, right: 24, top: 45),
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
                      padding: const EdgeInsets.only(bottom: 132),
                      child: Text(context.strings.init_user_page_title,
                          style: TextStyles.headline1)))),
          Center(
              child: InputFieldPlante(
            key: const Key('name'),
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
        Padding(padding: const EdgeInsets.only(bottom: 38), child: buttonNext);

    return StepperPage(content, bottomControls);
  }

  StepperPage _page2() {
    final onMilkCheckboxClick = (bool? value) {
      setState(() {
        _userParams = _userParams.rebuild((v) => v..eatsMilk = value ?? false);
      });
    };
    final onEggsCheckboxClick = (bool? value) {
      setState(() {
        _userParams = _userParams.rebuild((v) => v..eatsEggs = value ?? false);
      });
    };
    final onHoneyCheckboxClick = (bool? value) {
      setState(() {
        _userParams = _userParams.rebuild((v) => v..eatsHoney = value ?? false);
      });
    };

    final content = Column(mainAxisSize: MainAxisSize.max, children: [
      SizedBox(
          width: double.infinity,
          child: Text(
              context.strings.init_user_page_nice_to_meet_you +
                  _nameController.text,
              style: TextStyles.headline1)),
      const SizedBox(height: 12),
      SizedBox(
          width: double.infinity,
          child: Text(context.strings.init_user_page_tell_about_yourself,
              style: TextStyles.headline4)),
      const SizedBox(height: 16),
      InkWell(
        onTap: () {
          isVegan = true;
        },
        child: Container(
            color: const Color(0xFFF6F7FA),
            height: 48,
            child: Row(children: [
              const SizedBox(width: 10),
              RadioPlante<bool>(
                  value: true,
                  groupValue: isVegan,
                  onChanged: (bool? value) {
                    isVegan = value;
                  }),
              Text(context.strings.init_user_page_im_vegan,
                  style: TextStyles.normal)
            ])),
      ),
      const SizedBox(height: 7),
      InkWell(
        onTap: () {
          isVegan = false;
        },
        child: Container(
            color: const Color(0xFFF6F7FA),
            height: 48,
            child: Row(children: [
              const SizedBox(width: 10),
              RadioPlante<bool>(
                  value: false,
                  groupValue: isVegan,
                  onChanged: (bool? value) {
                    if (value == null) {
                      isVegan = null;
                    } else {
                      isVegan = value;
                    }
                  }),
              Text(context.strings.init_user_page_im_vegetarian,
                  style: TextStyles.normal)
            ])),
      ),
      const SizedBox(height: 24),
      SizedBox(
          width: double.infinity,
          child: Text(context.strings.init_user_page_what_do_you_eat,
              style: TextStyles.headline4)),
      const SizedBox(height: 21),
      Container(
          color: const Color(0xFFF6F7FA),
          height: 48,
          child: Row(children: [
            const SizedBox(width: 10),
            InkWell(
                onTap: () {
                  onEggsCheckboxClick(!(_userParams.eatsEggs ?? false));
                },
                child: Row(children: [
                  CheckboxPlante(
                      value: _userParams.eatsEggs ?? false,
                      onChanged: onEggsCheckboxClick),
                  Text(context.strings.init_user_page_i_eat_eggs),
                ])),
            const SizedBox(width: 24),
            InkWell(
                onTap: () {
                  onMilkCheckboxClick(!(_userParams.eatsMilk ?? false));
                },
                child: Row(children: [
                  CheckboxPlante(
                      value: _userParams.eatsMilk ?? false,
                      onChanged: onMilkCheckboxClick),
                  Text(context.strings.init_user_page_i_eat_milk),
                ])),
            const SizedBox(width: 24),
            InkWell(
                onTap: () {
                  onHoneyCheckboxClick(!(_userParams.eatsHoney ?? false));
                },
                child: Row(children: [
                  CheckboxPlante(
                      value: _userParams.eatsHoney ?? false,
                      onChanged: onHoneyCheckboxClick),
                  Text(context.strings.init_user_page_i_eat_honey),
                ])),
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
        Padding(padding: const EdgeInsets.only(bottom: 38), child: buttonDone);

    return StepperPage(content, bottomControls);
  }
}
