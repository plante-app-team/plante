import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';

/// A wrapper for mechanism of requesting addresses of entities
/// presently displayed in some ListView.
///
/// It's main goal is to let its clients to dynamically change lists
/// of displayed items, cancelling requests for old addresses if they're
/// no longer needed.
///
/// For example, if we have next list:
/// - item1
/// - item2
/// - item3
/// - item4
/// - item5
/// - item6
/// And at first item1 and item2 are displayed, but then user quickly scrolls
/// to item5 and item6 - [UiListAddressesObtainer] will cancel a request
/// for address of item2, will not request addresses of item3 and item4,
/// and then will request addresses of item5 and item6.
class UiListAddressesObtainer<T> {
  final AddressObtainer _addressObtainer;

  late final ArgResCallback<T, FutureShortAddress> _requester;

  final _requestsQueue = <VoidCallback>{};
  final _addressesCompleters = <T, Completer<ShortAddressResult>>{};

  UiListAddressesObtainer(this._addressObtainer) {
    if (T == Shop) {
      _requester = (T entity) {
        return _addressObtainer.addressOfShop(entity as Shop);
      };
    } else if (T == Coord) {
      _requester = (T entity) {
        return _addressObtainer.shortAddressOfCoords(entity as Coord);
      };
    } else {
      throw ArgumentError(
          'Even though the class is generic, only Shop and Coord are allowed');
    }
  }

  void onDisplayedEntitiesChanged(
      {required Iterable<T> displayedEntities,
      required List<T> allEntitiesOrdered}) {
    // Defensive copying
    displayedEntities = displayedEntities.toSet();
    allEntitiesOrdered = allEntitiesOrdered.toList();

    VoidCallback? action;
    action = () async {
      final finishRequest = () {
        _requestsQueue.remove(action);
        if (_requestsQueue.isNotEmpty) {
          _requestsQueue.first.call();
        }
      };

      final displayedEntitiesOrdered =
          allEntitiesOrdered.where((shop) => displayedEntities.contains(shop));
      for (final entity in displayedEntitiesOrdered) {
        final completer = _addressCompleterFor(entity);
        if (completer.isCompleted) {
          continue;
        }
        final address = await _requester.call(entity);
        if (!completer.isCompleted) {
          // Let's check completion again -
          // async things can have unpredictable order of execution
          completer.complete(address);
        }
        if (_requestsQueue.length > 1) {
          finishRequest.call();
          break;
        }
      }
      finishRequest.call();
    };
    if (_requestsQueue.length > 1) {
      _requestsQueue.remove(_requestsQueue.last);
    }
    _requestsQueue.add(action);
    if (_requestsQueue.length == 1) {
      _requestsQueue.first.call();
    }
  }

  Completer<ShortAddressResult> _addressCompleterFor(T entity) {
    var completer = _addressesCompleters[entity];
    if (completer == null) {
      completer = Completer<ShortAddressResult>();
      _addressesCompleters[entity] = completer;
    }
    return completer;
  }

  FutureShortAddress requestAddressOf(T entity) {
    return _addressCompleterFor(entity).future;
  }
}
