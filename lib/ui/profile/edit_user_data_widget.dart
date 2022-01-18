import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';

class EditUserDataWidgetController {
  UserParams? _userParams;
  final _callbacks = <VoidCallback>[];

  bool get _inited => _userParams != null;

  UserParams get userParams => _userParams ?? UserParams();
  set userParams(UserParams newValue) {
    if (newValue != _userParams) {
      _userParams = newValue;
      for (final callback in _callbacks) {
        callback.call();
      }
    }
  }

  EditUserDataWidgetController(
      {required Future<UserParams> initialUserParams}) {
    _initAsync(initialUserParams);
  }

  void _initAsync(Future<UserParams> initialUserParams) async {
    userParams = await initialUserParams;
  }

  bool isDataValid() {
    final name = userParams.name;
    if (name == null) {
      return false;
    }
    return EditUserDataWidget.MIN_NAME_LENGTH <= name.length;
  }

  void registerChangeCallback(VoidCallback callback) {
    _callbacks.add(callback);
  }

  void unregisterChangeCallback(VoidCallback callback) {
    _callbacks.remove(callback);
  }
}

class EditUserDataWidget extends StatefulWidget {
  static const MIN_NAME_LENGTH = 3;
  final EditUserDataWidgetController controller;
  const EditUserDataWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  _EditUserDataWidgetState createState() => _EditUserDataWidgetState();
}

class _EditUserDataWidgetState extends State<EditUserDataWidget> {
  final _nameController = TextEditingController();

  EditUserDataWidgetController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      _controller.userParams = _controller.userParams
          .rebuild((v) => v.name = _nameController.text.trim());
    });
    _controller.registerChangeCallback(_onControllerParamsChanged);
    _onControllerParamsChanged();
  }

  void _onControllerParamsChanged() {
    if (_nameController.text.trim() != (_controller.userParams.name ?? '')) {
      _nameController.text = _controller.userParams.name ?? '';
    }
  }

  @override
  void dispose() {
    _controller.unregisterChangeCallback(_onControllerParamsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InputFieldPlante(
        key: const Key('name'),
        textCapitalization: TextCapitalization.sentences,
        hint: context.strings.edit_user_data_widget_name_hint,
        controller: _controller._inited ? _nameController : null,
      ),
    ]);
  }
}
