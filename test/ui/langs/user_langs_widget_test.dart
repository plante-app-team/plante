import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/ui/langs/user_langs_widget.dart';

import '../../widget_tester_extension.dart';

void main() {
  testWidgets('good scenario', (WidgetTester tester) async {
    var userLangs = UserLangs((e) => e
      ..sysLang = LangCode.de
      ..langs.addAll([LangCode.ru, LangCode.be, LangCode.de])
      ..auto = false);

    final context = await tester.superPump(UserLangsWidget(
        initialUserLangs: userLangs,
        callback: (updated) => userLangs = updated));

    // Deselect Russian
    await tester.tap(find.byKey(Key('cancel_button_${LangCode.ru.name}')));
    await tester.pumpAndSettle();
    expect(
        userLangs,
        equals(UserLangs((e) => e
          ..sysLang = LangCode.de
          ..langs.addAll([LangCode.be, LangCode.de])
          ..auto = false)));

    // Cannot deselect the system language (German)
    expect(find.byKey(Key('cancel_button_${LangCode.de.name}')), findsNothing);

    // Select a new language
    await tester.tap(find.text(LangCode.ar.localize(context)));
    await tester.pumpAndSettle();
    expect(
        userLangs,
        equals(UserLangs((e) => e
          ..sysLang = LangCode.de
          ..langs.addAll([LangCode.be, LangCode.de, LangCode.ar])
          ..auto = false)));
  });
}
