import 'package:plante/base/result.dart';
import 'package:plante/contributions/user_contribution.dart';
import 'package:plante/contributions/user_contribution_type.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

const USER_CONTRIBUTIONS_CMD = 'user_contributions_data';

extension BackendExt on Backend {
  Future<Result<List<UserContribution>, BackendError>> requestUserContributions(
          int limit, Iterable<UserContributionType> types) =>
      executeCmd(_RequestUserContributionsCmd(limit, types));
}

class _RequestUserContributionsCmd extends BackendCmd<List<UserContribution>> {
  final int limit;
  final Iterable<UserContributionType> types;

  _RequestUserContributionsCmd(this.limit, this.types);

  @override
  Future<Result<List<UserContribution>, BackendError>> execute() async {
    final jsonRes = await backendGetJson('$USER_CONTRIBUTIONS_CMD/', {
      'limit': limit.toString(),
      'contributionsTypes': types.map((e) => e.persistentCode.toString()),
    });
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    if (!json.containsKey('result')) {
      Log.w('Invalid user_contributions_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final result = <UserContribution>[];
    final contributionsJson = json['result'] as List<dynamic>;
    for (final contributionJson in contributionsJson) {
      final contribution =
          UserContribution.fromJson(contributionJson as Map<String, dynamic>);
      if (contribution == null) {
        Log.w('Contribution could not pe parsed: $contributionJson');
        continue;
      }
      result.add(contribution);
    }
    return Ok(result);
  }
}
