import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/ui_value_wrapper.dart';
import 'package:plante/ui/map/components/timed_hints.dart';

class MapPageTimedHints extends StatelessWidget {
  const MapPageTimedHints({
    Key? key,
    required UIValueWrapper<bool> loading,
    required UIValueWrapper<bool> loadingSuggestions,
  })  : _loading = loading,
        _loadingSuggestions = loadingSuggestions,
        super(key: key);

  final UIValueWrapper<bool> _loading;
  final UIValueWrapper<bool> _loadingSuggestions;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final loading = _loading.watch(ref);
      final loadingSuggestions = _loadingSuggestions.watch(ref);
      if (loading) {
        return TimedHints(
          inProgress: true,
          hints: [
            const Pair('', Duration(seconds: 5)),
            Pair(context.strings.map_page_loading_shops_hint1,
                const Duration(seconds: 10)),
            Pair(context.strings.map_page_loading_shops_hint2,
                const Duration(seconds: 20)),
            Pair(context.strings.map_page_loading_shops_hint3,
                const Duration(days: 1)),
          ],
        );
      } else if (loadingSuggestions) {
        return TimedHints(inProgress: true, hints: [
          const Pair('', Duration(seconds: 5)),
          Pair(context.strings.map_page_loading_suggested_products_hint1,
              const Duration(days: 1)),
        ]);
      } else {
        return const TimedHints(inProgress: false, hints: []);
      }
    });
  }
}
