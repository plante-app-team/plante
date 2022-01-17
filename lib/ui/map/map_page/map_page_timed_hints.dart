import 'package:flutter/cupertino.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/components/timed_hints.dart';

class MapPageTimedHints extends StatelessWidget {
  const MapPageTimedHints({
    Key? key,
    required UIValueBase<bool> loading,
    required UIValueBase<bool> loadingSuggestions,
  })  : _loading = loading,
        _loadingSuggestions = loadingSuggestions,
        super(key: key);

  final UIValueBase<bool> _loading;
  final UIValueBase<bool> _loadingSuggestions;

  @override
  Widget build(BuildContext context) {
    return consumer((ref) {
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
