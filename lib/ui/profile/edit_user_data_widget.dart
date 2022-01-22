import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/profile/avatar_widget.dart';

class EditUserDataWidgetController {
  final UserAvatarManager _avatarManager;
  UserParams? _userParams;
  Uri? _userAvatar;
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
      _userParams =
          _userParams?.rebuild((e) => e.hasAvatar = _userAvatar != null);
      _notifyCallbacks();
    }
  }

  EditUserDataWidgetController(
      {required UserAvatarManager userAvatarManager,
      required Future<UserParams> initialUserParams})
      : _avatarManager = userAvatarManager {
    _initAsync(initialUserParams);
  }

  void _initAsync(Future<UserParams> initialUserParams) async {
    userAvatar = await _avatarManager.userAvatarUri();
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
  final EditUserDataWidgetController controller;
  const EditUserDataWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  _EditUserDataWidgetState createState() => _EditUserDataWidgetState();
}

class _EditUserDataWidgetState extends ConsumerState<EditUserDataWidget> {
  UserAvatarManager get _avatarManager => _controller._avatarManager;
  final _nameController = TextEditingController();
  late final UIValue<Uri?> _avatarUri =
      UIValue(widget.controller.userAvatar, ref);

  EditUserDataWidgetController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      _controller.userParams = _controller.userParams
          .rebuild((v) => v.name = _nameController.text.trim());
    });
    _avatarUri.callOnChanges((uri) => _controller.userAvatar = uri);
    _controller.registerChangeCallback(_onControllerDataChanged);
    _onControllerDataChanged();
    _initAsync();
  }

  void _initAsync() async {
    final selectedPhoto =
        await _avatarManager.retrieveLostSelectedAvatar(context);
    if (selectedPhoto != null) {
      _avatarUri.setValue(selectedPhoto);
    }
  }

  void _onControllerDataChanged() {
    if (_nameController.text.trim() != (_controller.userParams.name ?? '')) {
      _nameController.text = _controller.userParams.name ?? '';
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
      consumer((ref) => AvatarWidget(
          uri: _avatarUri.watch(ref),
          authHeaders: widget.controller._avatarManager.userAvatarAuthHeaders(),
          onChangeClick: _onChangeAvatarClick)),
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
        key: const Key('name'),
        textCapitalization: TextCapitalization.sentences,
        label: context.strings.edit_user_data_widget_name_label,
        hint: context.strings.edit_user_data_widget_name_hint,
        controller: _controller._inited ? _nameController : null,
      ),
    ]);
  }

  void _onChangeAvatarClick() async {
    final selectedPhoto = await _avatarManager.askUserToSelectImageFromGallery(
        context,
        iHaveTriedRetrievingLostImage: true);
    if (selectedPhoto != null) {
      _avatarUri.setValue(selectedPhoto);
    }
  }

  void _onDeleteAvatarClick() {
    _avatarUri.setValue(null);
  }
}
