import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/langs/user_langs_page.dart';
import 'package:plante/ui/settings/settings_buttons.dart';
import 'package:plante/ui/settings/settings_cache_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends PagePlante {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends PageStatePlante<SettingsPage> {
  late final _loading = UIValue<bool>(true, ref);
  bool _developer = false;
  bool _enableNewestFeatures = false;

  final _settings = GetIt.I.get<Settings>();
  final _sysLangCodeHolder = GetIt.I.get<SysLangCodeHolder>();
  late UserParams _user;
  late PackageInfo _packageInfo;

  _SettingsPageState() : super('SettingsPage');

  @override
  void initState() {
    super.initState();
    initStateImpl();
  }

  void initStateImpl() async {
    final userNullable =
        await GetIt.I.get<UserParamsController>().getUserParams();
    _user = userNullable!;
    _packageInfo = await getPackageInfo();
    if (kReleaseMode && (_user.userGroup == null || _user.userGroup == 1)) {
      _loading.setValue(false);
      return;
    }

    _developer = true;
    _enableNewestFeatures = await _settings.enableNewestFeatures();
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
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Stack(children: [
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
                      Clipboard.setData(
                          ClipboardData(text: _user.backendId ?? ''));
                      showSnackBar(
                          context.strings.global_copied_to_clipboard, context);
                    },
                    icon: SvgPicture.asset('assets/copy.svg'))),
          ])),
      const SizedBox(height: 16),
      SettingsGeneralButton(
          text: context.strings.settings_page_langs_i_know,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const UserLangsPage()));
          }),
      SettingsGeneralButton(
          text: context.strings.settings_page_send_logs,
          onTap: Log.startLogsSending),
      SettingsGeneralButton(
          text: context.strings.settings_page_open_cache_settings,
          onTap: _openCachePage),
      SettingsGeneralButton(
          text: context.strings.external_auth_page_privacy_policy,
          onTap: () {
            launch(privacyPolicyUrl(_sysLangCodeHolder));
          }),
      if (_developer)
        SettingsGeneralButton(
            text: 'Clear user data and exit (dev option)',
            onTap: () async {
              final paramsController = GetIt.I.get<UserParamsController>();
              final params = await paramsController.getUserParams();
              final newParams = params!.rebuild((e) => e.name = '😁');
              await paramsController.setUserParams(newParams);

              final backend = GetIt.I.get<Backend>();
              await backend.updateUserParams(newParams);

              exit(0);
            }),
      if (_developer)
        SettingsCheckButton(
            text: 'Newest features (dev option)',
            value: _enableNewestFeatures,
            onChanged: (value) {
              setState(() {
                _enableNewestFeatures = value;
                _settings.setEnableNewestFeatures(_enableNewestFeatures);
              });
            })
    ]);

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HeaderPlante(
            title: Text(context.strings.settings_page_title,
                style: TextStyles.pageTitle),
            leftAction: const FabPlante.backBtnPopOnClick(),
          ),
          Expanded(child: SingleChildScrollView(child: content)),
          Center(
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 26),
                  child: InkWell(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _packageInfo.asString()));
                        showSnackBar(context.strings.global_copied_to_clipboard,
                            context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(_packageInfo.asString(),
                              style: TextStyles.hint))))),
        ])));
  }

  void _openCachePage() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const SettingsCachePage()));
  }
}

extension _PackageInfoExt on PackageInfo {
  String asString() {
    return '$appName $version $buildNumber';
  }
}
