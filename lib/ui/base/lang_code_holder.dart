class LangCodeHolder {
  String? _langCode;

  LangCodeHolder();
  LangCodeHolder.inited(String initialLangCode) : _langCode = initialLangCode;

  String get langCode => _langCode!;
  set langCode(String value) {
    _langCode = value;
  }
}
