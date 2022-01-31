import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/profile/components/avatar_widget.dart';

class EditUserDataWidgetController {
  UserParams? _userParams;
  Uri? _userAvatar;
  final Future<Map<String, String>> _userAvatarHttpHeaders;
  final ResCallback<Future<Uri?>> _selectImageFromGallery;
  final _callbacks = <VoidCallback>[];

  bool get _inited => _userParams != null;

  /// User params, initial or edited by the user
  UserParams get userParams => _userParams ?? UserParams();
  set userParams(UserParams newValue) {
    if (newValue != _userParams) {
      _userParams = newValue;
      _notifyCallbacks();
    }
  }

  /// User avatar, initial, or changed by the user.
  /// If initial, most likely this URI is a URL.
  /// If edited, most likely this URI is a path to local file (which needs
  /// to be uploaded to the backend).
  Uri? get userAvatar => _userAvatar;
  set userAvatar(Uri? newValue) {
    if (newValue != _userAvatar) {
      _userAvatar = newValue;
      _notifyCallbacks();
    }
  }

  EditUserDataWidgetController(
      {required Future<UserParams> initialUserParams,
      required Future<Uri?> initialAvatar,
      required Future<Map<String, String>> userAvatarHttpHeaders,
      required ResCallback<Future<Uri?>> selectImageFromGallery})
      : _selectImageFromGallery = selectImageFromGallery,
        _userAvatarHttpHeaders = userAvatarHttpHeaders {
    _initAsync(initialUserParams, initialAvatar);
  }

  void _initAsync(
      Future<UserParams> initialUserParams, Future<Uri?> initialAvatar) async {
    userAvatar = await initialAvatar;
    // Must be the last statement of _initAsync
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

  void _notifyCallbacks() {
    for (final callback in _callbacks) {
      callback.call();
    }
  }
}

class EditUserDataWidget extends ConsumerStatefulWidget {
  static const MIN_NAME_LENGTH = 3;
  static const MAX_NAME_LENGTH = 40;
  static const MAX_SELF_DESCRIPTION_LENGTH = 512;
  final EditUserDataWidgetController controller;
  const EditUserDataWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  _EditUserDataWidgetState createState() => _EditUserDataWidgetState();
}

class _EditUserDataWidgetState extends ConsumerState<EditUserDataWidget> {
  final _nameController = TextEditingController();
  final _selfDescriptionController = TextEditingController();
  late final _avatarUri = UIValue<Uri?>(widget.controller.userAvatar, ref);

  late final _controllerInited = UIValue<bool>(false, ref);

  EditUserDataWidgetController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      _controller.userParams = _controller.userParams
          .rebuild((v) => v.name = _nameController.text.trim());
    });
    _selfDescriptionController.addListener(() {
      _controller.userParams = _controller.userParams.rebuild(
          (v) => v.selfDescription = _selfDescriptionController.text.trim());
    });
    _avatarUri.callOnChanges((uri) => _controller.userAvatar = uri);
    _controller.registerChangeCallback(_onControllerDataChanged);
    // UIValue cannot be changed from [initState], so we'll call it
    // during next frame.
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _onControllerDataChanged();
    });
  }

  void _onControllerDataChanged() {
    _controllerInited.setValue(_controller._inited);
    final controllerName = _controller.userParams.name ?? '';
    final controllerSelfDescription =
        _controller.userParams.selfDescription ?? '';
    if (_nameController.text.trim() != controllerName) {
      _nameController.text = controllerName;
    }
    if (_selfDescriptionController.text.trim() != controllerSelfDescription) {
      _selfDescriptionController.text = controllerSelfDescription;
    }
    // It won't change if the value is the same
    _avatarUri.setValue(_controller.userAvatar);
  }

  @override
  void dispose() {
    _controller.unregisterChangeCallback(_onControllerDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      consumer((ref) => SizedBox(
          width: 127,
          height: 127,
          child: AvatarWidget(
              uri: _avatarUri.watch(ref),
              authHeaders: widget.controller._userAvatarHttpHeaders,
              onChangeClick: _onChangeAvatarClick))),
      const SizedBox(height: 4),
      consumer((ref) => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _avatarUri.watch(ref) != null ? _onDeleteAvatarClick : null,
          child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedSwitcher(
                  duration: DURATION_DEFAULT,
                  child: _avatarUri.watch(ref) != null
                      ? Text(
                          context.strings.edit_user_data_widget_avatar_delete,
                          style: TextStyles.normalColored
                              .copyWith(color: ColorsPlante.red))
                      : Text(
                          context
                              .strings.edit_user_data_widget_avatar_description,
                          style: TextStyles.normalColored
                              .copyWith(color: ColorsPlante.grey)))))),
      const SizedBox(height: 20),
      InputFieldPlante(
        key: const Key('name_input'),
        inputFormatters: [
          LengthLimitingTextInputFormatter(EditUserDataWidget.MAX_NAME_LENGTH),
        ],
        textCapitalization: TextCapitalization.sentences,
        label: context.strings.edit_user_data_widget_name_label,
        hint: context.strings.edit_user_data_widget_name_hint,
        controller: _controllerInited.watch(ref) ? _nameController : null,
      ),
      const SizedBox(height: 24),
      InputFieldMultilinePlante(
        key: const Key('self_description_input'),
        minLines: 2,
        maxLines: 4,
        inputFormatters: [
          LengthLimitingTextInputFormatter(
              EditUserDataWidget.MAX_SELF_DESCRIPTION_LENGTH),
        ],
        label: context.strings.edit_user_data_widget_about_me_label,
        controller:
            _controllerInited.watch(ref) ? _selfDescriptionController : null,
      ),
    ]);
  }

  void _onChangeAvatarClick() async {
    final selectedPhoto = await _controller._selectImageFromGallery.call();
    if (selectedPhoto != null) {
      _avatarUri.setValue(selectedPhoto);
    }
  }

  void _onDeleteAvatarClick() {
    _avatarUri.setValue(null);
  }
}
