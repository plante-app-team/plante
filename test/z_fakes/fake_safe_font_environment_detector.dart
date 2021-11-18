import 'package:plante/model/user_langs.dart';
import 'package:plante/ui/base/safe_font_environment_detector.dart';

class FakeSafeFontEnvironmentDetector implements SafeFontEnvironmentDetector {
  bool _shouldUseSafeFont = false;

  void setShouldUseSafeFont(bool value) {
    _shouldUseSafeFont = value;
  }

  @override
  Future<void> get initFuture => Future.value();

  @override
  void onUserLangsChange(UserLangs userLangs) {
    throw UnimplementedError();
  }

  @override
  bool shouldUseSafeFont() => _shouldUseSafeFont;
}
