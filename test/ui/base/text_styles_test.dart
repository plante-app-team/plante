import 'package:get_it/get_it.dart';
import 'package:plante/ui/base/safe_font_environment_detector.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_safe_font_environment_detector.dart';

void main() {
  test('montserrat when safe font env detector is not available', () async {
    await GetIt.I.reset();
    expect(TextStyles.montserrat, equals('Montserrat'));
  });

  test('montserrat when safe font env detector allows unsafe fonts', () async {
    await GetIt.I.reset();
    final detector = FakeSafeFontEnvironmentDetector();
    detector.setShouldUseSafeFont(false);
    GetIt.I.registerSingleton<SafeFontEnvironmentDetector>(detector);

    expect(TextStyles.montserrat, equals('Montserrat'));
  });

  test('montserrat when safe font env detector DOES NOT allow unsafe fonts',
      () async {
    await GetIt.I.reset();
    final detector = FakeSafeFontEnvironmentDetector();
    detector.setShouldUseSafeFont(true);
    GetIt.I.registerSingleton<SafeFontEnvironmentDetector>(detector);

    expect(TextStyles.montserrat, equals('OpenSans'));
  });
}
