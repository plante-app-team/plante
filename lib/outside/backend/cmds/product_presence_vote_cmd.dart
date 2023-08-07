import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

const PRODUCT_PRESENCE_VOTE_CMD = 'product_presence_vote';

extension BackendExt on Backend {
  Future<Result<ProductPresenceVoteResult, BackendError>> productPresenceVote(
          String barcode, OsmUID osmUID, bool positive) =>
      executeCmd(_ProductPresenceVoteCmd(barcode, osmUID, positive));
}

class _ProductPresenceVoteCmd extends BackendCmd<ProductPresenceVoteResult> {
  final String barcode;
  final OsmUID osmUID;
  final bool positive;
  _ProductPresenceVoteCmd(this.barcode, this.osmUID, this.positive);

  @override
  Future<Result<ProductPresenceVoteResult, BackendError>> execute() async {
    final response = await backendGetJson('$PRODUCT_PRESENCE_VOTE_CMD/', {
      'barcode': barcode,
      'shopOsmUID': osmUID.toString(),
      'voteVal': positive ? '1' : '0',
    });
    if (response.isErr) {
      return Err(response.unwrapErr());
    }
    final json = response.unwrap();
    final deleted = json['deleted'] as bool?;
    return Ok(ProductPresenceVoteResult(productDeleted: deleted ?? false));
  }
}
