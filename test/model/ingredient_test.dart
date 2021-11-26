import 'package:plante/model/ingredient.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});
  test('name with language preposition en', () async {
    final ingredient = Ingredient((e) => e..name = 'en:gluten');
    expect(ingredient.name, 'en:gluten');
    expect(ingredient.cleanName(), 'gluten');
  });

  test('name with language no preposition NL', () async {
    final ingredient = Ingredient((e) => e..name = 'NL:gluten');
    expect(ingredient.name, 'NL:gluten');
    expect(ingredient.cleanName(), 'gluten');
  });

  test('name with language no preposition', () async {
    final ingredient = Ingredient((e) => e..name = 'gluten');
    expect(ingredient.name, 'gluten');
    expect(ingredient.cleanName(), 'gluten');
  });
}
