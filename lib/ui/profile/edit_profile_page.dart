import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/restorable/uri_restorable.dart';
import 'package:plante/model/restorable/user_params_restorable.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/linear_progress_indicator_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/profile/components/edit_user_data_widget.dart';

class EditProfilePage extends PagePlante {
  final UserParams initialUserParams;
  final Uri? initialUserAvatar;
  const EditProfilePage._(
      {Key? key,
      required this.initialUserParams,
      required this.initialUserAvatar})
      : super(key: key);

  @visibleForTesting
  static EditProfilePage createForTesting(
      UserParams initialUserParams, Uri? initialUserAvatar,
      {Key? key}) {
    if (!isInTests()) {
      throw Exception('!isInTests()');
    }
    return EditProfilePage._(
        key: key,
        initialUserParams: initialUserParams,
        initialUserAvatar: initialUserAvatar);
  }

  @override
  _EditProfilePageState createState() => _EditProfilePageState();

  static void show(
      {Key? key,
      required BuildContext context,
      required UserParams initialUserParams,
      required Uri? initialUserAvatar}) {
    final args = [
      initialUserParams.toJson(),
      initialUserAvatar?.toString() ?? '',
    ];
    Navigator.restorablePush(context, _routeBuilder, arguments: args);
  }

  static Route<void> _routeBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute<void>(builder: (BuildContext context) {
      UserParams userParams = UserParams();
      Uri? avatarUri;
      if (arguments != null) {
        final args = arguments as List<dynamic>;
        userParams = UserParams.fromJson(args[0] as Map<dynamic, dynamic>) ??
            UserParams();
        avatarUri = args[1] == '' ? null : Uri.tryParse(args[1] as String);
      }
      if (userParams == UserParams()) {
        Log.w(
            'EditProfilePage is created with empty user params. Args: $arguments');
      }
      return EditProfilePage._(
          initialUserParams: userParams, initialUserAvatar: avatarUri);
    });
  }
}

class _EditProfilePageState extends PageStatePlante<EditProfilePage>
    with RestorationMixin {
  final _userParamsController = GetIt.I.get<UserParamsController>();
  final _avatarManager = GetIt.I.get<UserAvatarManager>();
  final _backend = GetIt.I.get<Backend>();
  late final EditUserDataWidgetController _editUserDataController;

  late final UserParamsRestorable _userParamsRestorable;
  late final UriRestorable _userAvatarRestorable;
  late final _loading = UIValue<bool>(false, ref);

  _EditProfilePageState() : super('EditProfilePage');

  @override
  String? get restorationId => 'edit_profile_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    _userParamsRestorable = UserParamsRestorable(widget.initialUserParams);
    _userAvatarRestorable = UriRestorable(widget.initialUserAvatar);
    registerForRestoration(_userParamsRestorable, 'user_params');
    registerForRestoration(_userAvatarRestorable, 'user_avatar');

    final initialUserParams = () async => _userParamsRestorable.value;
    final initialUserAvatar = () async => _userAvatarRestorable.value;
    _editUserDataController = EditUserDataWidgetController(
        initialUserParams: initialUserParams.call(),
        initialAvatar: initialUserAvatar.call(),
        userAvatarHttpHeaders: _avatarManager.userAvatarAuthHeaders(),
        selectImageFromGallery: _selectImageFromGallery);

    _editUserDataController.registerChangeCallback(_onUserDataChanged);

    _initAsync();
  }

  void _onUserDataChanged() {
    _userParamsRestorable.value = _editUserDataController.userParams;
    _userAvatarRestorable.value = _editUserDataController.userAvatar;
  }

  Future<Uri?> _selectImageFromGallery() async {
    return _avatarManager.askUserToSelectImageFromGallery(context,
        iHaveTriedRetrievingLostImage: true);
  }

  void _initAsync() async {
    final lostAvatar = await _avatarManager.retrieveLostSelectedAvatar(context);
    if (lostAvatar != null) {
      _editUserDataController.userAvatar = lostAvatar;
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
                child: Stack(children: [
              Column(verticalDirection: VerticalDirection.up, children: [
                Padding(
                    padding: const EdgeInsets.only(
                        left: 24, right: 24, top: 26, bottom: 26),
                    child: SizedBox(
                        width: double.infinity,
                        child: consumer((ref) => ButtonFilledPlante.withText(
                            context.strings.global_save,
                            onPressed: _loading.watch(ref) == false
                                ? _onSavePress
                                : null)))),
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
                      child: EditUserDataWidget(
                          controller: _editUserDataController))
                ])))
              ]),
              if (!isInTests())
                consumer((ref) => AnimatedSwitcher(
                    duration: DURATION_DEFAULT,
                    child: _loading.watch(ref)
                        ? const LinearProgressIndicatorPlante()
                        : const SizedBox.shrink())),
            ]))));
  }

  void _onBackPress() async {
    if (await _onWillPop() == true) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() async {
    final userParamsChanged =
        _editUserDataController.userParams != widget.initialUserParams;
    final avatarChanged =
        _editUserDataController.userAvatar != widget.initialUserAvatar;
    if (!userParamsChanged && !avatarChanged) {
      return true;
    }

    final cancel = await showYesNoDialog(
        context, context.strings.edit_profile_page_cancel_editing_q);
    return cancel == true;
  }

  void _onSavePress() async {
    _longAction(() async {
      if (widget.initialUserParams != _editUserDataController.userParams) {
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

      if (widget.initialUserAvatar != _editUserDataController.userAvatar) {
        final Result<dynamic, BackendError> avatarChangeRes;
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
    });
  }

  void _longAction(dynamic Function() action) async {
    try {
      _loading.setValue(true);
      await action.call();
    } finally {
      _loading.setValue(false);
    }
  }

  void _showError(BackendError error) {
    if (error.errorKind == BackendErrorKind.NETWORK_ERROR) {
      showSnackBar(context.strings.global_network_error, context);
    } else {
      showSnackBar(context.strings.global_something_went_wrong, context);
    }
  }
}
