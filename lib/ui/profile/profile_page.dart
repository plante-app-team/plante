import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/profile/edit_user_data_widget.dart';

class ProfilePage extends PagePlante {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends PageStatePlante<ProfilePage>
    implements UserAvatarManagerObserver, UserParamsControllerObserver {
  final _userParamsController = GetIt.I.get<UserParamsController>();
  final _avatarManager = GetIt.I.get<UserAvatarManager>();

  late final _editUserDataController = EditUserDataWidgetController(
    userAvatarManager: _avatarManager,
    initialUserParams: _userParams(),
  );

  _ProfilePageState() : super('ProfilePage');

  @override
  void initState() {
    super.initState();
    _avatarManager.addObserver(this);
    _userParamsController.addObserver(this);
  }

  @override
  void dispose() {
    _avatarManager.removeObserver(this);
    _userParamsController.removeObserver(this);
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(children: [
        EditUserDataWidget(controller: _editUserDataController)
      ])),
    );
  }

  Future<UserParams> _userParams() async {
    return (await _userParamsController.getUserParams())!;
  }

  @override
  void onUserAvatarChange() async {
    _editUserDataController.userAvatar = await _avatarManager.userAvatarUri();
  }

  @override
  void onUserParamsUpdate(UserParams? userParams) {
    _editUserDataController.userParams = userParams ?? UserParams();
  }
}
