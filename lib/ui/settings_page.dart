import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool loading = true;
  bool developer = false;
  bool fakeOffApi = false;
  bool offScannedProductEmpty = false;

  final barcodeOverrideController = TextEditingController();

  late Settings settings;
  late UserParams user;

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
    if (user.userGroup == null || user.userGroup == 1) {
      setState(() {
        loading = false;
      });
      return;
    }

    developer = true;
    fakeOffApi = await settings.fakeOffApi();
    offScannedProductEmpty = await settings.fakeOffApiProductNotFound();
    barcodeOverrideController.text = await settings.fakeScannedProductBarcode();
    barcodeOverrideController.addListener(() {
      settings.setFakeScannedProductBarcode(barcodeOverrideController.text);
    });

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
        body: SafeArea(
            child: Container(
                padding: EdgeInsets.only(left: 24, right: 24),
                child: SingleChildScrollView(
                    child: Column(children: [
                  SizedBox(height: 45),
                  SizedBox(
                      width: double.infinity,
                      child: Text(context.strings.settings_page_title,
                          style: TextStyles.headline1)),
                  SizedBox(height: 12),
                  Row(children: [
                    InkWell(
                        child: Text(
                            context.strings.settings_page_your_id +
                                (user.backendId ?? ""),
                            style: TextStyles.normal),
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: user.backendId ?? ""));
                          showSnackBar(
                              context.strings.global_copied_to_clipboard,
                              context);
                        }),
                  ]),
                  SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: Text(context.strings.settings_page_general,
                          style: TextStyles.headline2)),
                  SizedBox(height: 12),
                  SizedBox(
                      width: double.infinity,
                      child: ButtonFilledPlante.withText(
                          context.strings.settings_page_send_logs,
                          onPressed: () {
                        Log.startLogsSending();
                      })),
                  if (developer) SizedBox(height: 24),
                  if (developer)
                    SizedBox(
                        width: double.infinity,
                        child: Text(
                            context.strings.settings_page_developer_options,
                            style: TextStyles.headline2)),
                  if (developer) SizedBox(height: 12),
                  if (developer)
                    SizedBox(
                        width: double.infinity,
                        child: ButtonFilledPlante.withText(
                            context.strings.settings_page_erase_user_data,
                            onPressed: () async {
                          final controller =
                              GetIt.I.get<UserParamsController>();
                          final params = await controller.getUserParams();
                          await controller
                              .setUserParams(params!.rebuild((e) => e
                                ..name = ""
                                ..eatsHoney = null
                                ..eatsEggs = null
                                ..eatsMilk = null));
                          exit(0);
                        })),
                  if (developer)
                    _CheckboxSettings(
                        text: context.strings.settings_page_fake_off,
                        value: fakeOffApi,
                        onChanged: (value) {
                          setState(() {
                            fakeOffApi = value;
                            settings.setFakeOffApi(fakeOffApi);
                          });
                        }),
                      if (developer)
                        AnimatedSwitcher(
                            duration: Duration(milliseconds: 250),
                            child: !fakeOffApi
                                ? SizedBox.shrink()
                                : _CheckboxSettings(
                                text: context.strings
                                    .settings_page_fake_off_scanned_product_empty,
                                value: offScannedProductEmpty,
                                onChanged: (value) {
                                  setState(() {
                                    offScannedProductEmpty = value;
                                    settings.setFakeOffApiProductNotFound(
                                        offScannedProductEmpty);
                                  });
                                })),
                      if (developer)
                        InputFieldPlante(
                              label: context.strings.settings_page_fake_off_forced_scanned_barcode,
                              controller: barcodeOverrideController,
                            ),
                  SizedBox(height: 10),
                  Center(
                      child: InkWell(
                          child: Text(
                              context.strings.external_auth_page_privacy_policy,
                              style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline)),
                          onTap: () {
                            launch(PRIVACY_POLICY_URL);
                          }))
                ])))));
  }
}

class _CheckboxSettings extends StatelessWidget {
  final String text;
  final bool value;
  final dynamic Function(bool value) onChanged;

  _CheckboxSettings(
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
