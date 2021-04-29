import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:plante/l10n/strings.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SettingsList(
      sections: [
        SettingsSection(
          title: context.strings.settings_page_general,
          tiles: [
            SettingsTile(
              title: context.strings.settings_page_send_logs,
              leading: Icon(Icons.notes),
              onPressed: (BuildContext context) {
                Log.startLogsSending();
              },
            ),
            SettingsTile(
              title: context.strings.settings_page_erase_user_data,
              leading: Icon(Icons.phonelink_erase),
              onPressed: (BuildContext context) async {
                final controller = GetIt.I.get<UserParamsController>();
                final params = await controller.getUserParams();
                await controller.setUserParams(params!.rebuild((e) => e
                  ..name = ""
                  ..eatsHoney = null
                  ..eatsEggs = null
                  ..eatsMilk = null));
                exit(0);
              },
            ),
          ],
        ),
      ],
    ));
  }
}
