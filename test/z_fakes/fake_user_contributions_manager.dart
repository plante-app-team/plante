import 'package:plante/base/result.dart';
import 'package:plante/contributions/user_contribution.dart';
import 'package:plante/contributions/user_contributions_manager.dart';
import 'package:plante/outside/backend/backend_error.dart';

class FakeUserContributionsManager implements UserContributionsManager {
  Future<Result<List<UserContribution>, BackendError>>? _contributions;
  var _getContributionsCallsCount = 0;

  // ignore: non_constant_identifier_names
  void setContributions_testing(
      Future<Result<List<UserContribution>, BackendError>> contributions) {
    _contributions = contributions;
  }

  // ignore: non_constant_identifier_names
  void setContributionsResult_testing(
      Result<List<UserContribution>, BackendError> contributions) {
    _contributions = (() async => contributions).call();
  }

  // ignore: non_constant_identifier_names
  void setContributionsSimple_testing(List<UserContribution> contributions) {
    setContributionsResult_testing(Ok(contributions));
  }

  // ignore: non_constant_identifier_names
  int getContributionsCallsCount_testing() => _getContributionsCallsCount;

  @override
  Future<Result<List<UserContribution>, BackendError>>
      getContributions() async {
    _getContributionsCallsCount += 1;
    if (_contributions != null) {
      return await _contributions!;
    } else {
      return Ok(const []);
    }
  }
}
