import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/langs/user_langs_page.dart';
import 'package:plante/ui/settings/app_version_widget.dart';
import 'package:plante/ui/settings/settings_buttons.dart';
import 'package:plante/ui/settings/settings_help_and_feedback_page.dart';
import 'package:plante/ui/settings/settings_stores_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends PagePlante {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends PageStatePlante<SettingsPage> {
  late final _loading = UIValue<bool>(true, ref);
  late final _distanceInMiles = UIValue<bool?>(null, ref);
  bool _developer = false;
  bool _enableNewestFeatures = false;

  final _settings = GetIt.I.get<Settings>();
  final _sysLangCodeHolder = GetIt.I.get<SysLangCodeHolder>();
  late UserParams _user;

  _SettingsPageState() : super('SettingsPage');

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  void _initAsync() async {
    _distanceInMiles.setValue(await _settings.distanceInMiles());
    _distanceInMiles.callOnChanges((val) {
      if (val != null) {
        _settings.setDistanceInMiles(val);
      }
    });

    final userNullable =
        await GetIt.I.get<UserParamsController>().getUserParams();
    _user = userNullable!;
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
      SettingsGeneralButton(
          text: context.strings.settings_page_help_and_feedback_title,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsHelpAndFeedbackPage()));
          }),
      SettingsGeneralButton(
          text: context.strings.settings_page_langs_i_know,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const UserLangsPage()));
          }),
      SettingsGeneralButton(
          text: context.strings.settings_page_stores_settings_title,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsStoresPage()));
          }),
      SettingsGeneralButton(
          text: context.strings.external_auth_page_privacy_policy,
          onTap: () {
            launchUrl(privacyPolicyUrl(_sysLangCodeHolder));
          }),
      consumer((ref) => SettingsCheckButton(
          onChanged: _distanceInMiles.setValue,
          text: context.strings.settings_page_distance_in_miles,
          value: _distanceInMiles.watch(ref) ?? false)),
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
          const AppVersionWidget(),
        ])));
  }
}
