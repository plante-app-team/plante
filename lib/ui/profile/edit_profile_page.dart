import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/profile/edit_user_data_widget.dart';

class EditProfilePage extends PagePlante {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends PageStatePlante<EditProfilePage> {
  final _userParamsController = GetIt.I.get<UserParamsController>();
  final _avatarManager = GetIt.I.get<UserAvatarManager>();
  final _backend = GetIt.I.get<Backend>();
  late final EditUserDataWidgetController _editUserDataController;

  late final UserParams? _initialUserParams;
  late final Uri? _initialUserAvatar;

  _EditProfilePageState() : super('EditProfilePage');

  @override
  void initState() {
    super.initState();
    final initialUserParamsFn =
        () async => await _userParamsController.getUserParams() ?? UserParams();
    final initialUserParams = initialUserParamsFn.call();
    _editUserDataController = EditUserDataWidgetController(
        userAvatarManager: _avatarManager,
        initialUserParams: initialUserParams);
    _initAsync();
  }

  void _initAsync() async {
    _initialUserParams = await _userParamsController.getUserParams();
    _initialUserAvatar = await _avatarManager.userAvatarUri();
  }

  @override
  Widget buildPage(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
                child:
                    Column(verticalDirection: VerticalDirection.up, children: [
              Padding(
                  padding: const EdgeInsets.only(
                      left: 24, right: 24, top: 26, bottom: 26),
                  child: SizedBox(
                      width: double.infinity,
                      child: ButtonFilledPlante.withText(
                          context.strings.global_save,
                          onPressed: _onSavePress))),
              Expanded(
                  child: SingleChildScrollView(
                      child: Column(children: [
                HeaderPlante(
                  title: Text(context.strings.edit_profile_page_title,
                      style: TextStyles.pageTitle),
                  height: 84,
                  leftAction: FabPlante(
                      key: const Key('back_button'),
                      svgAsset: 'assets/back_arrow.svg',
                      onPressed: _onBackPress),
                ),
                Padding(
                    padding: const EdgeInsets.all(24),
                    child:
                        EditUserDataWidget(controller: _editUserDataController))
              ])))
            ]))));
  }

  void _onBackPress() async {
    if (await _onWillPop() == true) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() async {
    final userParamsChanged =
        _editUserDataController.userParams != _initialUserParams;
    final avatarChanged =
        _editUserDataController.userAvatar != _initialUserAvatar;
    if (!userParamsChanged && !avatarChanged) {
      return true;
    }

    final cancel = await showYesNoDialog(
        context, context.strings.edit_profile_page_cancel_editing_q);
    return cancel == true;
  }

  void _onSavePress() async {
    if (_initialUserParams != _editUserDataController.userParams) {
      final userParamsChangeRes =
          await _backend.updateUserParams(_editUserDataController.userParams);
      if (userParamsChangeRes.isErr) {
        _showError(userParamsChangeRes.unwrapErr());
        return;
      } else {
        await _userParamsController
            .setUserParams(_editUserDataController.userParams);
      }
    }

    if (_initialUserAvatar != _editUserDataController.userAvatar) {
      final Result<None, BackendError> avatarChangeRes;
      if (_editUserDataController.userAvatar != null) {
        avatarChangeRes = await _avatarManager
            .updateUserAvatar(_editUserDataController.userAvatar!);
      } else {
        avatarChangeRes = await _avatarManager.deleteUserAvatar();
      }
      if (avatarChangeRes.isErr) {
        _showError(avatarChangeRes.unwrapErr());
        return;
      }
    }

    Navigator.of(context).pop();
  }

  void _showError(BackendError error) {
    if (error.errorKind == BackendErrorKind.NETWORK_ERROR) {
      showSnackBar(context.strings.global_network_error, context);
    } else {
      showSnackBar(context.strings.global_something_went_wrong, context);
    }
  }
}
