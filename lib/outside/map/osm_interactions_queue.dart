import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';

typedef InteractionFn<R, E> = Future<Result<R, E>> Function();

enum OsmInteractionsGoal {
  FETCH_SHOPS,
  FETCH_ROADS,
  FETCH_ADDRESS,
  SEARCH,
}

enum OsmInteractionService {
  OVERPASS,
  NOMINATIM,
}

extension OsmInteractionsGoalExt on OsmInteractionsGoal {
  OsmInteractionService get service {
    switch (this) {
      case OsmInteractionsGoal.FETCH_SHOPS:
        return OsmInteractionService.OVERPASS;
      case OsmInteractionsGoal.FETCH_ROADS:
        return OsmInteractionService.OVERPASS;
      case OsmInteractionsGoal.FETCH_ADDRESS:
        return OsmInteractionService.NOMINATIM;
      case OsmInteractionsGoal.SEARCH:
        return OsmInteractionService.NOMINATIM;
    }
  }
}

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
  final _impls = <OsmInteractionService, _OsmInteractionsQueueImpl>{};

  OsmInteractionsQueue() {
    _impls[OsmInteractionService.OVERPASS] =
        _OsmInteractionsQueueImpl(OsmInteractionService.OVERPASS.cooldown);
    _impls[OsmInteractionService.NOMINATIM] =
        _OsmInteractionsQueueImpl(OsmInteractionService.NOMINATIM.cooldown);
    if (_impls.length != OsmInteractionService.values.length) {
      throw Error();
    }
  }

  Future<Result<R, E>> enqueue<R, E>(InteractionFn<R, E> interactionFn,
      {required List<OsmInteractionsGoal> goals}) async {
    final services = goals.map((e) => e.service).toSet();
    if (services.length > 1) {
      throw ArgumentError(
          'Simultaneous requests to multiple OSM services are not supported. '
          'Please either split your interaction into several distinct ones, '
          'or add the support to OsmInteractionsQueue by modifying it');
    }
    final service = services.first;
    final impl = _impls[service]!;
    return await impl.enqueue(interactionFn);
  }

  bool isInteracting(OsmInteractionService service) =>
      _impls[service]!.interacting;
}

class _OsmInteractionsQueueImpl {
  final Duration _interactionsCooldown;
  DateTime _lastInteractionTime = DateTime(2000);
  bool _interacting = false;
  final _delayedInteractions = <VoidCallback>[];

  bool get interacting => _interacting;

  _OsmInteractionsQueueImpl(this._interactionsCooldown);

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

extension _OsmServiceExt on OsmInteractionService {
  Duration get cooldown {
    if (isInTests()) {
      return const Duration(milliseconds: 50);
    }
    switch (this) {
      case OsmInteractionService.OVERPASS:
        return const Duration(seconds: 3);
      case OsmInteractionService.NOMINATIM:
        return const Duration(milliseconds: 1500);
    }
  }
}
