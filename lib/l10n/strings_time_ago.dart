import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension Strings on AppLocalizations {
  String timeAgoFromDuration(Duration duration) {
    // This local variable is needed so that the 'find_unused_strings.py' script
    // wouldn't complain about unused strings.
    final context = _NullContext(this);
    if (duration.inHours < 1) {
      return context.strings.global_n_minutes_ago_v2(duration.inMinutes);
    } else if (duration.inDays < 1) {
      return context.strings.global_n_hours_ago_v2(duration.inHours);
    } else if (duration.inDays < 7) {
      return context.strings.global_n_days_ago_v2(duration.inDays);
    } else if (duration.inDays < 30) {
      return context.strings.global_n_weeks_ago_v2(duration.inDays ~/ 7);
    } else if (duration.inDays < 365) {
      return context.strings.global_n_months_ago_v2(duration.inDays ~/ 30);
    } else {
      return context.strings.global_n_years_ago_v2(duration.inDays ~/ 365);
    }
  }
}

class _NullContext {
  AppLocalizations strings;
  _NullContext(this.strings);
}
