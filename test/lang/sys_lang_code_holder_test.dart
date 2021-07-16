import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:test/test.dart';

void main() {
  late SysLangCodeHolder langCodeHolder;

  setUp(() async {
    langCodeHolder = SysLangCodeHolder();
  });

  test('callWhenInited callbacks', () async {
    String? code1;
    String? code2;
    final callback1 = (String code) {
      code1 = code;
    };
    final callback2 = (String code) {
      code2 = code;
    };

    langCodeHolder.callWhenInited(callback1);
    expect(code1, isNull);
    langCodeHolder.langCode = 'en';
    expect(code1, equals('en'));

    expect(code2, isNull);
    langCodeHolder.callWhenInited(callback2);
    expect(code2, equals('en'));
  });
}
