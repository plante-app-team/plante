import 'package:flutter/foundation.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:plante/base/base.dart';

class FuzzyRated<T> {
  final int ratio;
  final T value;
  FuzzyRated(this.ratio, this.value);
}

class FuzzySearch {
  FuzzySearch._();

  /// A threshold used by [searchSortCut] to tell which 2 values are
  /// similar and which aren't.
  /// The [weightedRatio] function returns a similarity value we call 'ratio'
  /// when it compares strings. The bigger ratio is, the more
  /// similar compared strings are.
  /// Current value of [DEFAULT_SEARCH_RATIO_THRESHOLD] is chosen arbitrary
  /// based on manual testing of different threshold values.
  /// Feel free to use a custom value if default doesn't satisfy your needs.
  static const int DEFAULT_SEARCH_RATIO_THRESHOLD = 70;

  /// Performs a fuzzy search in a separate isolate, sorts results
  /// according to how similar they are to [query],
  /// cuts off values which ratios are less than [ratioThreshold];
  static Future<List<T>> searchSortCut<T>(
      List<T> values, ArgResCallback<T, String> toStr, String query,
      {int ratioThreshold = DEFAULT_SEARCH_RATIO_THRESHOLD}) async {
    final ratios = await search(values, toStr, query, sort: true);
    return ratios
        .where((e) => e.ratio >= ratioThreshold)
        .map((e) => e.value)
        .toList();
  }

  /// Performs a fuzzy search in a separate isolate.
  static Future<List<FuzzyRated<T>>> search<T>(
      List<T> values, ArgResCallback<T, String> toStr, String query,
      {bool sort = false}) async {
    final strs = values.map((val) => toStr.call(val)).toList();
    final List<_RatedVal> ratedVals;
    if (!isInTests()) {
      ratedVals = await compute(_searchImpl, _SearchParams(strs, query, sort));
    } else {
      ratedVals = _searchImpl(_SearchParams(strs, query, sort));
    }
    final result = <FuzzyRated<T>>[];
    for (final ratedVal in ratedVals) {
      result.add(FuzzyRated(ratedVal.ratio, values[ratedVal.indexOld]));
    }
    return result;
  }

  static List<_RatedVal> _searchImpl(_SearchParams params) {
    final result = <_RatedVal>[];
    for (var index = 0; index < params.values.length; ++index) {
      result.add(
          _RatedVal(index, _fuzzyRatio(params.values[index], params.query)));
    }
    if (params.sort) {
      result.sort((lhs, rhs) => rhs.ratio - lhs.ratio);
    }
    return result;
  }

  static int _fuzzyRatio(String lhs, String rhs) {
    return weightedRatio(lhs, rhs);
  }

  static bool areSimilar(String lhs, String rhs,
      {int ratioThreshold = DEFAULT_SEARCH_RATIO_THRESHOLD}) {
    final ratio = _fuzzyRatio(lhs, rhs);
    return ratio >= ratioThreshold;
  }
}

class _SearchParams {
  final List<String> values;
  final String query;
  final bool sort;
  _SearchParams(this.values, this.query, this.sort);
}

class _RatedVal {
  final int indexOld;
  final int ratio;
  _RatedVal(this.indexOld, this.ratio);
}
