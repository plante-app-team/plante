import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/settings/app_version_widget.dart';
import 'package:plante/ui/settings/ask_if_user_wants_deletion_dialog.dart';
import 'package:plante/ui/settings/settings_buttons.dart';
import 'package:plante/ui/settings/settings_cache_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsHelpAndFeedbackPage extends PagePlante {
  const SettingsHelpAndFeedbackPage({Key? key}) : super(key: key);

  @override
  _SettingsHelpAndFeedbackPageState createState() =>
      _SettingsHelpAndFeedbackPageState();
}

class _SettingsHelpAndFeedbackPageState
    extends PageStatePlante<SettingsHelpAndFeedbackPage> {
  final _langsManager = GetIt.I.get<UserLangsManager>();
  final _googleAuthorizer = GetIt.I.get<GoogleAuthorizer>();
  final _appleAuthorizer = GetIt.I.get<AppleAuthorizer>();
  final _backend = GetIt.I.get<Backend>();

  late final _loading = UIValue<bool>(true, ref);
  late UserParams _user;
  late UserLangs _userLangs;

  _SettingsHelpAndFeedbackPageState() : super('SettingsHelpAndFeedbackPage');

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  void _initAsync() async {
    final userNullable =
        await GetIt.I.get<UserParamsController>().getUserParams();
    _user = userNullable!;
    _userLangs = await _langsManager.getUserLangs();
    _loading.setValue(false);
  }

  @override
  Widget buildPage(BuildContext context) {
    if (_loading.watch(ref)) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: const Center(child: CircularProgressIndicatorPlante()),
      );
    }

    final content = Column(children: [
      const SizedBox(height: 24),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Padding24(Text(
            context.strings.settings_page_help_and_feedback_contacts_title,
            style: TextStyles.normal)),
        const SizedBox(height: 18),
        SizedBox(
            height: 52,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              const SizedBox(width: 20),
              ..._contactButtons(),
            ])),
        const SizedBox(height: 18),
      ]),
      const SizedBox(height: 6),
      _Padding24(Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.strings.settings_page_your_id,
              style: TextStyles.headline3),
          const SizedBox(height: 8),
          Text(_user.backendId ?? '???', style: TextStyles.hint),
        ]),
        Align(
            alignment: Alignment.centerRight,
            child: IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _user.backendId ?? ''));
                  showSnackBar(
                      context.strings.global_copied_to_clipboard, context);
                },
                icon: SvgPicture.asset('assets/copy.svg'))),
      ])),
      const SizedBox(height: 16),
      SettingsGeneralButton(
          text: context.strings.settings_page_send_logs,
          onTap: Log.startLogsSending),
      SettingsGeneralButton(
          text: context.strings.settings_page_open_cache_settings,
          onTap: _openCachePage),
      SettingsGeneralButton(
          text: context.strings.settings_button_delete_my_account,
          onTap: _deleteMyAccount),
    ]);

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HeaderPlante(
              title: Text(context.strings.settings_page_help_and_feedback_title,
                  style: TextStyles.pageTitle),
              leftAction: const FabPlante.backBtnPopOnClick()),
          Expanded(child: SingleChildScrollView(child: content)),
          const AppVersionWidget(),
        ])));
  }

  List<Widget> _contactButtons() {
    final buttons = <Widget>[];

    buttons.add(_ContactButton(
      png: 'assets/contact_email.png',
      url: Uri(
        scheme: 'mailto',
        path: 'plante.application@gmail.com',
        queryParameters: {'subject': 'Feedback'},
      ),
    ));

    if (_userLangs.langs.contains(LangCode.en)) {
      buttons.add(_ContactButton(
        png: 'assets/contact_discord.png',
        url: Uri.parse('https://discord.gg/kXgXrTVpGY'),
      ));
    }

    if (_userLangs.langs.contains(LangCode.ru)) {
      buttons.add(_ContactButton(
        png: 'assets/contact_telegram.png',
        url: Uri.parse('https://t.me/+MyYIO93--xdhOGRi'),
      ));
    }

    if (_userLangs.langs.contains(LangCode.ru)) {
      buttons.add(_ContactButton(
        png: 'assets/contact_instagram.png',
        url: Uri.parse('https://instagram.com/plante.vegan.app.ru/'),
      ));
    } else {
      buttons.add(_ContactButton(
        png: 'assets/contact_instagram.png',
        url: Uri.parse('https://instagram.com/plante.vegan.app/'),
      ));
    }

    if (_userLangs.langs.contains(LangCode.en)) {
      buttons.add(_ContactButton(
        png: 'assets/contact_facebook.png',
        url: Uri.parse('https://facebook.com/planteapp'),
      ));
    }

    if (_userLangs.langs.contains(LangCode.ru)) {
      buttons.add(_ContactButton(
        png: 'assets/contact_vk.png',
        url: Uri.parse('https://vk.com/planteapp'),
      ));
    }

    return buttons;
  }

  void _openCachePage() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const SettingsCachePage()));
  }

  void _deleteMyAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AskIfUserWantsDeletion(user: _user);
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      _loading.setValue(true);
      String? appleAuthCode;
      String? googleAuthCode;
      if (_user.appleId != null) {
        final appleUser = await _appleAuthorizer.auth();
        if (appleUser == null) {
          showSnackBar(context.strings.global_something_went_wrong, context);
          return;
        }
        appleAuthCode = appleUser.authorizationCode;
      }
      if (_user.googleId != null) {
        final googleUser = await _googleAuthorizer.auth();
        if (googleUser == null) {
          showSnackBar(context.strings.global_something_went_wrong, context);
          return;
        }
        googleAuthCode = googleUser.idToken;
      }

      final result = await _backend.deleteMyUser(
        googleIdToken: googleAuthCode,
        appleAuthorizationCode: appleAuthCode,
      );
      if (result.isErr) {
        showSnackBar(context.strings.global_something_went_wrong, context);
        return;
      }

      exit(0);
    } finally {
      _loading.setValue(false);
    }
  }
}

class _ContactButton extends StatelessWidget {
  final String png;
  final Uri url;
  const _ContactButton({Key? key, required this.png, required this.url})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              launchUrl(url);
            },
            icon: SizedBox(width: 38, height: 38, child: Image.asset(png))));
  }
}

class _Padding24 extends StatelessWidget {
  final Widget child;
  const _Padding24(this.child, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24), child: child);
  }
}
