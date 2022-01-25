import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/profile/avatar_widget.dart';
import 'package:plante/ui/profile/edit_profile_page.dart';
import 'package:plante/ui/settings/settings_page.dart';

class ProfilePage extends PagePlante {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends PageStatePlante<ProfilePage>
    implements UserAvatarManagerObserver, UserParamsControllerObserver {
  final _userParamsController = GetIt.I.get<UserParamsController>();
  final _avatarManager = GetIt.I.get<UserAvatarManager>();

  late final _userParams = UIValue<UserParams?>(null, ref);
  late final _avatar = UIValue<Uri?>(null, ref);

  _ProfilePageState() : super('ProfilePage');

  @override
  void initState() {
    super.initState();
    _avatarManager.addObserver(this);
    _userParamsController.addObserver(this);
    _initAsync();
  }

  void _initAsync() async {
    _userParams.setValue(await _userParamsController.getUserParams());
    _avatar.setValue(await _avatarManager.userAvatarUri());
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
        backgroundColor: ColorsPlante.lightGrey,
        body: SafeArea(
            child: Column(children: [
          HeaderPlante(
              title: const SizedBox(),
              spacingTop: 0,
              spacingBottom: 0,
              height: 64,
              rightActionPadding: 12,
              rightAction: IconButton(
                  key: const Key('settings_button'),
                  onPressed: _openSettings,
                  icon: SvgPicture.asset('assets/settings.svg'))),
          Material(
              color: Colors.white,
              child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Column(children: [
                    Row(children: [
                      SizedBox(
                          width: 75,
                          height: 75,
                          child: consumer((ref) => AvatarWidget(
                              uri: _avatar.watch(ref),
                              authHeaders:
                                  _avatarManager.userAvatarAuthHeaders()))),
                      const SizedBox(width: 16),
                      consumer((ref) {
                        final userParams = _userParams.watch(ref);
                        if (userParams == null) {
                          return const SizedBox();
                        }
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userParams.name ?? '',
                                  style: TextStyles.headline3
                                      .copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              if (userParams.selfDescription != null)
                                Text(userParams.selfDescription!,
                                    style: TextStyles.hint),
                            ]);
                      }),
                    ]),
                    const SizedBox(height: 12),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                            key: const Key('edit_profile_button'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: _onEditProfileClick,
                            child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                    context.strings.profile_page_edit_profile,
                                    style: TextStyles.smallBoldBlack)))),
                    const SizedBox(height: 16),
                  ]))),
        ])));
  }

  void _onEditProfileClick() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const EditProfilePage()));
  }

  void _openSettings() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }

  @override
  void onUserAvatarChange() async {
    _avatar.setValue(await _avatarManager.userAvatarUri());
  }

  @override
  void onUserParamsUpdate(UserParams? userParams) async {
    _userParams.setValue(await _userParamsController.getUserParams());
  }
}
