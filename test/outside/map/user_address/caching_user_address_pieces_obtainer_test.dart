import 'package:plante/base/pair.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:test/test.dart';

import '../../../z_fakes/fake_address_obtainer.dart';
import '../../../z_fakes/fake_shared_preferences.dart';
import '../../../z_fakes/fake_user_location_manager.dart';

void main() {
  late FakeSharedPreferences prefs;
  late FakeAddressObtainer addressObtainer;
  late FakeUserLocationManager userLocationManager;
  late LatestCameraPosStorage cameraPosStorage;
  late CachingUserAddressPiecesObtainer obtainer;

  final userPos = Coord(lat: 10, lon: 20);
  final cameraPos = Coord(lat: 20, lon: 20);

  final userAddress = OsmAddress((e) => e
    ..countryCode = 'be'
    ..city = 'Brussels');
  final cameraAddress = OsmAddress((e) => e
    ..countryCode = 'ru'
    ..city = 'Moscow');

  setUp(() async {
    prefs = FakeSharedPreferences();
    addressObtainer = FakeAddressObtainer();
    userLocationManager = FakeUserLocationManager();
    cameraPosStorage = LatestCameraPosStorage(prefs.asHolder());

    userLocationManager.setLastKnownPosition(userPos);
    await cameraPosStorage.set(cameraPos);
    addressObtainer.setResponse(userPos, userAddress);
    addressObtainer.setResponse(cameraPos, cameraAddress);

    obtainer = CachingUserAddressPiecesObtainer(
      prefs.asHolder(),
      userLocationManager,
      cameraPosStorage,
      addressObtainer,
    );
  });

  test('obtain everything', () async {
    final addressFor = (UserAddressType type) {
      switch (type) {
        case UserAddressType.USER_LOCATION:
          return userAddress;
        case UserAddressType.CAMERA_LOCATION:
          return cameraAddress;
      }
    };
    final addressPieceFor = (OsmAddress address, UserAddressPiece piece) {
      switch (piece) {
        case UserAddressPiece.COUNTRY_CODE:
          return address.countryCode;
        case UserAddressPiece.CITY:
          return address.city;
      }
    };

    final expectedResults = <Pair<UserAddressType, UserAddressPiece>, String>{};
    for (final type in UserAddressType.values) {
      for (final piece in UserAddressPiece.values) {
        final address = addressFor(type);
        expectedResults[Pair(type, piece)] = addressPieceFor(address, piece)!;
      }
    }

    for (final type in UserAddressType.values) {
      for (final piece in UserAddressPiece.values) {
        final result = await obtainer.getAddressPiece(type, piece);
        final expectedResult = expectedResults[Pair(type, piece)];
        expect(result, equals(expectedResult));
      }
    }
  });
}
