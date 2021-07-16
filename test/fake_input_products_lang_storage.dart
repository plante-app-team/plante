import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';

class FakeInputProductsLangStorage implements InputProductsLangStorage {
  @override
  LangCode? selectedCode;

  FakeInputProductsLangStorage.fromCode(this.selectedCode);
  FakeInputProductsLangStorage.from(SysLangCodeHolder langCodeHolder) {
    selectedCode = LangCode.safeValueOf(langCodeHolder.langCode);
  }
}
