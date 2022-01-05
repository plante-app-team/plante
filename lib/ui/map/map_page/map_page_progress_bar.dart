import 'package:flutter/material.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/ui/base/components/incremental_progress_bar.dart';

class MapPageProgressBar extends StatelessWidget {
  static const _STOP = 0;
  static const _SHOPS_LOADING = 1;
  static const _PRODUCTS_SUGGESTIONS_LOADING = 2;
  final bool inProgress;
  final int purpose;

  const MapPageProgressBar._(
      {Key? key, required this.inProgress, required this.purpose})
      : super(key: key);

  factory MapPageProgressBar.stop({Key? key}) =>
      MapPageProgressBar._(key: key, inProgress: false, purpose: _STOP);
  factory MapPageProgressBar.forLoadingShops(
          {Key? key, required bool inProgress}) =>
      MapPageProgressBar._(
          key: key, inProgress: inProgress, purpose: _SHOPS_LOADING);
  factory MapPageProgressBar.forLoadingProductsSuggestions(
          {Key? key, required bool inProgress}) =>
      MapPageProgressBar._(
          key: key,
          inProgress: inProgress,
          purpose: _PRODUCTS_SUGGESTIONS_LOADING);

  @override
  Widget build(BuildContext context) {
    switch (purpose) {
      case _STOP:
        return _forStop(context);
      case _SHOPS_LOADING:
        return _forShops(context);
      case _PRODUCTS_SUGGESTIONS_LOADING:
        return _forProductsSuggestions(context);
      default:
        Log.e('Invalid purpose: $purpose');
        return const SizedBox();
    }
  }

  Widget _forStop(BuildContext context) {
    return IncrementalProgressBar(
      inProgress: false,
      progresses: {
        1: Duration.zero,
      },
    );
  }

  Widget _forShops(BuildContext context) {
    return IncrementalProgressBar(
      inProgress: inProgress,
      progresses: {
        0.20: const Duration(seconds: 4),
        0.40: const Duration(seconds: 5),
        0.60: const Duration(seconds: 8),
        0.80: const Duration(seconds: 12),
        0.99: const Duration(seconds: 24),
        1: const Duration(days: 1),
      },
    );
  }

  Widget _forProductsSuggestions(BuildContext context) {
    return IncrementalProgressBar(
      inProgress: inProgress,
      progresses: {
        0.1: const Duration(seconds: 1),
        0.2: const Duration(seconds: 2),
        0.3: const Duration(seconds: 3),
        0.4: const Duration(seconds: 4),
        0.5: const Duration(seconds: 6),
        0.6: const Duration(seconds: 9),
        0.7: const Duration(seconds: 13),
        0.8: const Duration(seconds: 19),
        0.9: const Duration(seconds: 28),
        0.95: const Duration(seconds: 28),
        1: const Duration(seconds: 60),
      },
    );
  }
}
