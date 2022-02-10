import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/settings/settings_buttons.dart';

class SettingsStoresPage extends PagePlante {
  const SettingsStoresPage({Key? key}) : super(key: key);

  @override
  _SettingsStoresPageState createState() => _SettingsStoresPageState();
}

class _SettingsStoresPageState extends PageStatePlante<SettingsStoresPage> {
  final _settings = GetIt.I.get<Settings>();

  late final _productsSuggestionsRadius = UIValue<bool?>(null, ref);
  late final _productsSuggestionsOff = UIValue<bool?>(null, ref);

  _SettingsStoresPageState() : super('SettingsStoresPage');

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  void _initAsync() async {
    _productsSuggestionsRadius
        .setValue(await _settings.enableRadiusProductsSuggestions());
    _productsSuggestionsOff
        .setValue(await _settings.enableOFFProductsSuggestions());

    _productsSuggestionsRadius.callOnChanges((val) {
      if (val != null) {
        _settings.setEnableRadiusProductsSuggestions(val);
      }
    });
    _productsSuggestionsOff.callOnChanges((val) {
      if (val != null) {
        _settings.setEnableOFFProductsSuggestions(val);
      }
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: [
          HeaderPlante(
              title: Text(context.strings.settings_page_stores_settings_title,
                  style: TextStyles.pageTitle),
              leftAction: const FabPlante.backBtnPopOnClick()),
          Column(children: [
            consumer((ref) => _productsSuggestionsRadius.watch(ref) == null
                ? const SizedBox()
                : SettingsCheckButton(
                    onChanged: _productsSuggestionsRadius.setValue,
                    text: context
                        .strings.settings_page_show_products_radius_suggestions,
                    value: _productsSuggestionsRadius.watch(ref)!)),
            consumer((ref) => _productsSuggestionsOff.watch(ref) == null
                ? const SizedBox()
                : SettingsCheckButton(
                    onChanged: _productsSuggestionsOff.setValue,
                    text: context
                        .strings.settings_page_show_products_off_suggestions,
                    value: _productsSuggestionsOff.watch(ref)!)),
          ])
        ]))));
  }
}
