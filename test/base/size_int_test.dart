import 'package:plante/base/size_int.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {});

  test('operator ==', () async {
    const value1 = SizeInt(width: 10, height: 10);
    const value2 = SizeInt(width: 10, height: 15);
    const value3 = SizeInt(width: 15, height: 10);
    const value4 = SizeInt(width: 15, height: 15);
    const value5 = SizeInt(width: 10, height: 10);

    expect(value1, isNot(equals(value2)));
    expect(value1, isNot(equals(value3)));
    expect(value1, isNot(equals(value4)));
    expect(value1, equals(value5));
  });

  test('hashCode', () async {
    const value1 = SizeInt(width: 10, height: 10);
    const value2 = SizeInt(width: 10, height: 15);
    const value3 = SizeInt(width: 10, height: 10);

    expect(value1.hashCode, isNot(equals(value2.hashCode)));
    expect(value1.hashCode, equals(value3.hashCode));
  });

  test('toString', () async {
    const value1 = SizeInt(width: 10, height: 10);
    const value2 = SizeInt(width: 15, height: 15);

    expect(value1.toString(), equals('[10, 10]'));
    expect(value2.toString(), equals('[15, 15]'));
  });
}
