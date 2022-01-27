import 'package:flutter_test/flutter_test.dart';
import 'package:plante/ui/photos/photo_requester.dart';

void main() {
  setUp(() async {});

  test('persistent codes values', () {
    // If new elements added, test must be changed
    expect(PhotoRequester.values.length, equals(2));

    // The persistent values are also stored persistently
    expect(PhotoRequester.AVATAR_INIT.persistentCode, equals(1));
    expect(PhotoRequester.PRODUCT_INIT.persistentCode, equals(2));
  });
}
