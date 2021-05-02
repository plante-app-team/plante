import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension Strings on BuildContext {
  AppLocalizations get strings {
    return AppLocalizations.of(this)!;
  }

  String get langCode => Localizations.localeOf(this).languageCode;
}
