import 'package:plante/base/fuzzy_search.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {});

  test('searchSortCut: string is similar to itself', () async {
    final input = ['some_string'];
    final result =
        await FuzzySearch.searchSortCut<String>(input, (e) => e, 'some_string');
    expect(result, equals(input));
  });

  test('searchSortCut: string is not similar to another string', () async {
    final input = ['some_string'];
    final result = await FuzzySearch.searchSortCut<String>(
        input, (e) => e, 'completely different');
    expect(result, isEmpty);
  });

  test('searchSortCut: result is ordered from most similar to least similar',
      () async {
    final input = ['some_striAA', 'some_strinA', 'some_string'];
    final result =
        await FuzzySearch.searchSortCut<String>(input, (e) => e, 'some_string');
    expect(result, equals(['some_string', 'some_strinA', 'some_striAA']));
  });

  test('searchSortCut: sentences with same words are similar', () async {
    final input = ['elephants like humans'];
    final result = await FuzzySearch.searchSortCut<String>(
        input, (e) => e, 'humans like elephants');
    expect(result, equals(input));
  });

  test('searchSortCut: substring of big string is considered to be match',
      () async {
    final input = ['with product in middle'];
    final result =
        await FuzzySearch.searchSortCut<String>(input, (e) => e, 'product');
    expect(result, equals(input));
  });
}
