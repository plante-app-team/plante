import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/langs/user_langs_page.dart';
import 'package:plante/ui/settings/settings_cache_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends PagePlante {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends PageStatePlante<SettingsPage> {
  bool _loading = true;
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
      setState(() {
        _loading = false;
      });
      return;
    }

    _developer = true;
    _enableNewestFeatures = await _settings.enableNewestFeatures();
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    if (_loading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
            child: !isInTests()
                ? const CircularProgressIndicator()
                : const SizedBox()),
      );
    }
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: [
          HeaderPlante(
              title: Text(context.strings.settings_page_title,
                  style: TextStyles.headline1),
              leftAction: const FabPlante.backBtnPopOnClick()),
          Container(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: Column(children: [
                Row(children: [
                  InkWell(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _user.backendId ?? ''));
                        showSnackBar(context.strings.global_copied_to_clipboard,
                            context);
                      },
                      child: Text(
                          context.strings.settings_page_your_id +
                              (_user.backendId ?? ''),
                          style: TextStyles.normal)),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: Text(context.strings.settings_page_general,
                        style: TextStyles.headline3)),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: ButtonFilledPlante.withText(
                        context.strings.settings_page_langs_i_know,
                        onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const UserLangsPage()));
                    })),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: ButtonFilledPlante.withText(
                        context.strings.settings_page_send_logs,
                        onPressed: Log.startLogsSending)),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: ButtonFilledPlante.withText(
                        context.strings.settings_page_open_cache_settings,
                        onPressed: _openCachePage)),
                if (_developer) const SizedBox(height: 24),
                if (_developer)
                  SizedBox(
                      width: double.infinity,
                      child: Text(
                          context.strings.settings_page_developer_options,
                          style: TextStyles.headline3)),
                if (_developer) const SizedBox(height: 12),
                if (_developer)
                  SizedBox(
                      width: double.infinity,
                      child: ButtonFilledPlante.withText(
                          context.strings.settings_page_erase_user_data,
                          onPressed: () async {
                        final paramsController =
                            GetIt.I.get<UserParamsController>();
                        final params = await paramsController.getUserParams();
                        final newParams = params!.rebuild((e) => e.name = '😁');
                        await paramsController.setUserParams(newParams);

                        final backend = GetIt.I.get<Backend>();
                        await backend.updateUserParams(newParams);

                        exit(0);
                      })),
                if (_developer)
                  _CheckboxSettings(
                      text: 'Newest features',
                      value: _enableNewestFeatures,
                      onChanged: (value) {
                        setState(() {
                          _enableNewestFeatures = value;
                          _settings
                              .setEnableNewestFeatures(_enableNewestFeatures);
                        });
                      }),
                const SizedBox(height: 10),
                Center(
                    child: InkWell(
                        onTap: () {
                          launch(privacyPolicyUrl(_sysLangCodeHolder));
                        },
                        child: Text(
                            context.strings.external_auth_page_privacy_policy,
                            style: TextStyles.normal.copyWith(
                                color: Colors.blue,
                                decoration: TextDecoration.underline)))),
                const SizedBox(height: 10),
                Center(
                    child: InkWell(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: _packageInfo.asString()));
                          showSnackBar(
                              context.strings.global_copied_to_clipboard,
                              context);
                        },
                        child: Text(_packageInfo.asString(),
                            style: TextStyles.hint))),
              ]))
        ]))));
  }

  void _openCachePage() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const SettingsCachePage()));
  }
}

class _CheckboxSettings extends StatelessWidget {
  final String text;
  final bool value;
  final dynamic Function(bool value) onChanged;

  const _CheckboxSettings(
      {required this.text, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (value) {
        onChanged.call(value ?? false);
      },
      title: Text(text, style: TextStyles.normal),
      contentPadding: EdgeInsets.zero,
    );
  }
}

extension _PackageInfoExt on PackageInfo {
  String asString() {
    return '$appName $version $buildNumber';
  }
}
