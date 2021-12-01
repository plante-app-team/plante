import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/map/osm/osm_interactions_queue.dart';
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
    for (final service in OsmInteractionService.values) {
      final firstInteractionCompleter = Completer<int>();
      unawaited(queue.enqueue(
          () async => Ok(await firstInteractionCompleter.future),
          service: service));

      var secondInteractionDone = false;
      final secondInteractionFuture = queue.enqueue(() async {
        secondInteractionDone = true;
        return Ok(1);
      }, service: service);

      await awaitWithTimeout(secondInteractionFuture);
      expect(secondInteractionDone, isFalse);

      firstInteractionCompleter.complete(123);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(secondInteractionDone, isTrue);
    }
  });

  test('interactions with different services ARE executed simultaneously',
      () async {
    expect(OsmInteractionService.values.length, greaterThan(1),
        reason: 'If there is only 1 service then test cannot verify anything');
    final firstInteractionCompleter = Completer<int>();
    unawaited(queue.enqueue(
        () async => Ok(await firstInteractionCompleter.future),
        service: OsmInteractionService.values[0]));

    var secondInteractionDone = false;
    final secondInteractionFuture = queue.enqueue(() async {
      secondInteractionDone = true;
      return Ok(1);
    }, service: OsmInteractionService.values[1]);

    await awaitWithTimeout(secondInteractionFuture);
    // [firstInteractionCompleter] hasn't completed yet but we expect the second
    // interaction to be done, because we send interactions to different
    // services.
    expect(secondInteractionDone, isTrue);
  });
}
