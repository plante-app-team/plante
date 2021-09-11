import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/map/osm_interactions_queue.dart';
import 'package:test/test.dart';

void main() {
  late OsmInteractionsQueue queue;

  setUp(() async {
    queue = OsmInteractionsQueue();
  });

  Future<void> awaitWithTimeout(Future<Result<int, dynamic>> f) async {
    await f.timeout(const Duration(milliseconds: 50),
        onTimeout: () async => Ok(1));
  }

  test('interactions with same services are not executed simultaneously',
      () async {
    final servicesAndGoals =
        <OsmInteractionService, List<OsmInteractionsGoal>>{};
    for (final goal in OsmInteractionsGoal.values) {
      if (servicesAndGoals[goal.service] == null) {
        servicesAndGoals[goal.service] = [];
      }
      servicesAndGoals[goal.service]!.add(goal);
    }

    for (final goals in servicesAndGoals.values) {
      final firstInteractionCompleter = Completer<int>();
      unawaited(queue.enqueue(
          () async => Ok(await firstInteractionCompleter.future),
          goals: goals));

      var secondInteractionDone = false;
      final secondInteractionFuture = queue.enqueue(() async {
        secondInteractionDone = true;
        return Ok(1);
      }, goals: goals);

      await awaitWithTimeout(secondInteractionFuture);
      expect(secondInteractionDone, isFalse);

      firstInteractionCompleter.complete(123);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(secondInteractionDone, isTrue);
    }
  });

  test('interactions with different services ARE executed simultaneously',
      () async {
    final servicesAndGoals =
        <OsmInteractionService, List<OsmInteractionsGoal>>{};
    for (final goal in OsmInteractionsGoal.values) {
      if (servicesAndGoals[goal.service] == null) {
        servicesAndGoals[goal.service] = [];
      }
      servicesAndGoals[goal.service]!.add(goal);
    }

    expect(servicesAndGoals.keys.length, greaterThan(1),
        reason: 'If there is only 1 service then test cannot verify anything');
    final goalsOfDistinctServices = [
      servicesAndGoals.values.first.first,
      servicesAndGoals.values.last.first
    ];
    final goal1 = goalsOfDistinctServices.first;
    final goal2 = goalsOfDistinctServices.last;

    final firstInteractionCompleter = Completer<int>();
    unawaited(queue.enqueue(
        () async => Ok(await firstInteractionCompleter.future),
        goals: [goal1]));

    var secondInteractionDone = false;
    final secondInteractionFuture = queue.enqueue(() async {
      secondInteractionDone = true;
      return Ok(1);
    }, goals: [goal2]);

    await awaitWithTimeout(secondInteractionFuture);
    // [firstInteractionCompleter] hasn't completed yet but we expect the second
    // interaction to be done, because we send interactions to different
    // services.
    expect(secondInteractionDone, isTrue);
  });

  test('single interaction with different services throws', () async {
    final servicesAndGoals =
        <OsmInteractionService, List<OsmInteractionsGoal>>{};
    for (final goal in OsmInteractionsGoal.values) {
      if (servicesAndGoals[goal.service] == null) {
        servicesAndGoals[goal.service] = [];
      }
      servicesAndGoals[goal.service]!.add(goal);
    }

    expect(servicesAndGoals.keys.length, greaterThan(1),
        reason: 'If there is only 1 service then test cannot verify anything');
    final goalsOfDistinctServices = [
      servicesAndGoals.values.first.first,
      servicesAndGoals.values.last.first
    ];
    final goal1 = goalsOfDistinctServices.first;
    final goal2 = goalsOfDistinctServices.last;

    var exceptionCaught = false;
    try {
      await queue.enqueue(() async => Ok(123), goals: [goal1, goal2]);
    } catch (e) {
      exceptionCaught = true;
    }
    expect(exceptionCaught, isTrue);
  });
}
