import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/langs/user_langs_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends PageStatePlante<SettingsPage> {
  bool loading = true;
  bool developer = false;
  bool testingBackends = false;
  bool testingBackendsQuickAnswers = false;
  bool offScannedProductEmpty = false;

  late Settings settings;
  late UserParams user;
  late PackageInfo packageInfo;

  _SettingsPageState() : super('SettingsPage');

  @override
  void initState() {
    super.initState();
    settings = GetIt.I.get<Settings>();
    initStateImpl();
  }

  void initStateImpl() async {
    final userNullable =
        await GetIt.I.get<UserParamsController>().getUserParams();
    user = userNullable!;
    packageInfo = await getPackageInfo();
    if (kReleaseMode && (user.userGroup == null || user.userGroup == 1)) {
      setState(() {
        loading = false;
      });
      return;
    }

    developer = true;
    testingBackends = await settings.testingBackends();
    testingBackendsQuickAnswers = await settings.testingBackendsQuickAnswers();
    offScannedProductEmpty = await settings.fakeOffApiProductNotFound();
    setState(() {
      loading = false;
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    if (loading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
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
              leftAction: FabPlante.backBtnPopOnClick()),
          Container(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: Column(children: [
                Row(children: [
                  InkWell(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: user.backendId ?? ''));
                        showSnackBar(context.strings.global_copied_to_clipboard,
                            context);
                      },
                      child: Text(
                          context.strings.settings_page_your_id +
                              (user.backendId ?? ''),
                          style: TextStyles.normal)),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: Text(context.strings.settings_page_general,
                        style: TextStyles.headline3)),
                const SizedBox(height: 12),
                if (enableNewestFeatures())
                  Column(children: [
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
                  ]),
                SizedBox(
                    width: double.infinity,
                    child: ButtonFilledPlante.withText(
                        context.strings.settings_page_send_logs,
                        onPressed: Log.startLogsSending)),
                if (developer) const SizedBox(height: 24),
                if (developer)
                  SizedBox(
                      width: double.infinity,
                      child: Text(
                          context.strings.settings_page_developer_options,
                          style: TextStyles.headline3)),
                if (developer) const SizedBox(height: 12),
                if (developer)
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
                if (developer)
                  _CheckboxSettings(
                      text: context.strings.settings_page_testing_backends,
                      value: testingBackends,
                      onChanged: (value) {
                        setState(() {
                          testingBackends = value;
                          settings.setTestingBackends(testingBackends);
                        });
                      }),
                if (developer)
                  AnimatedSwitcher(
                      duration: DURATION_DEFAULT,
                      child: !testingBackends
                          ? const SizedBox.shrink()
                          : Column(children: [
                              _CheckboxSettings(
                                  text: context.strings
                                      .settings_page_fake_off_scanned_product_empty,
                                  value: offScannedProductEmpty,
                                  onChanged: (value) {
                                    setState(() {
                                      offScannedProductEmpty = value;
                                      settings.setFakeOffApiProductNotFound(
                                          offScannedProductEmpty);
                                    });
                                  }),
                              _CheckboxSettings(
                                  text: context.strings
                                      .settings_page_testing_backends_quick_answers,
                                  value: testingBackendsQuickAnswers,
                                  onChanged: (value) {
                                    setState(() {
                                      testingBackendsQuickAnswers = value;
                                      settings.setTestingBackendsQuickAnswers(
                                          testingBackendsQuickAnswers);
                                    });
                                  }),
                            ])),
                const SizedBox(height: 10),
                Center(
                    child: InkWell(
                        onTap: () {
                          launch(PRIVACY_POLICY_URL);
                        },
                        child: Text(
                            context.strings.external_auth_page_privacy_policy,
                            style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline)))),
                const SizedBox(height: 10),
                Center(
                    child: InkWell(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: packageInfo.asString()));
                          showSnackBar(
                              context.strings.global_copied_to_clipboard,
                              context);
                        },
                        child: Text(packageInfo.asString(),
                            style: TextStyles.hint))),
              ]))
        ]))));
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
