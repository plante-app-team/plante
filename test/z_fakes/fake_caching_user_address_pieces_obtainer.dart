import 'package:plante/base/pair.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';

class FakeCachingUserAddressPiecesObtainer
    implements CachingUserAddressPiecesObtainer {
  final Map<Pair<UserAddressType, UserAddressPiece>, String> _map = {};

  void setResultFor(
      UserAddressType type, UserAddressPiece piece, String? result) {
    final key = Pair(type, piece);
    if (result != null) {
      _map[key] = result;
    } else {
      _map.remove(key);
    }
  }

  @override
  Future<String?> getAddressPiece(UserAddressType userAddressType,
      UserAddressPiece userAddressPiece) async {
    return _map[Pair(userAddressType, userAddressPiece)];
  }
}
