import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';

typedef InteractionFn<R, E> = Future<Result<R, E>> Function();

/// Open Street Map (OSM) has a strict rate limit for incoming requests.
/// And Plante wants to query OSM from many places (to find organizations,
/// roads, addresses).
///
/// To avoid terrorizing OSM (and to avoid Plante being banned by OSM) all
/// requests to OSM should go through one instance of [OsmInteractionsQueue].
///
/// OsmInteractionsQueue stretches requests in time to minimize the risk
/// of fast rate limit reaching.
class OsmInteractionsQueue {
  DateTime _lastInteractionTime = DateTime(2000);
  bool _interacting = false;
  final _delayedInteractions = <VoidCallback>[];

  static final _interactionsCooldown = isInTests()
      ? const Duration(milliseconds: 50)
      : const Duration(seconds: 3);

  Future<Result<R, E>> enqueue<R, E>(InteractionFn<R, E> interactionFn) async {
    final completer = Completer<Result<R, E>>();
    VoidCallback? callback;
    callback = () async {
      _interacting = true;
      try {
        await _cooldown();
        final result = await interactionFn.call();
        completer.complete(result);
        _delayedInteractions.remove(callback);
      } finally {
        _interacting = false;
      }
      if (_delayedInteractions.isNotEmpty) {
        _delayedInteractions.first.call();
      }
    };
    _delayedInteractions.add(callback);
    if (!_interacting) {
      _delayedInteractions.first.call();
    }
    return completer.future;
  }

  Future<void> _cooldown() async {
    final timeSinceLastInteraction =
        DateTime.now().difference(_lastInteractionTime);
    if (timeSinceLastInteraction < _interactionsCooldown) {
      await Future.delayed(_interactionsCooldown - timeSinceLastInteraction);
    }
    _lastInteractionTime = DateTime.now();
  }
}
