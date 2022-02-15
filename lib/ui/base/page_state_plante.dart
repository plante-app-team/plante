import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/ui_value.dart';

abstract class PagePlante extends ConsumerStatefulWidget {
  const PagePlante({Key? key}) : super(key: key);
}

abstract class PageStatePlante<T extends PagePlante> extends ConsumerState<T>
    with AutomaticKeepAliveClientMixin<T> {
  late final Analytics _analytics;
  final String _pageName;
  final bool _keepAlive;
  late final UIValuesFactory _uiValuesFactory;

  @protected
  Analytics get analytics => _analytics;

  @protected
  UIValuesFactory get uiValuesFactory => _uiValuesFactory;

  /// For [keepAlive] see [AutomaticKeepAliveClientMixin]
  PageStatePlante(this._pageName, {bool keepAlive = false})
      : _analytics = GetIt.I.get<Analytics>(),
        _keepAlive = keepAlive {
    _uiValuesFactory = UIValuesFactory(() => ref);
  }

  Widget buildPage(BuildContext context);

  @nonVirtual
  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin
    return VisibilityDetectorPlante(
      keyStr: '${_pageName}_base_visibility_detector',
      onVisibilityChanged: _onVisibilityChanged,
      child: buildPage(context),
    );
  }

  void _onVisibilityChanged(bool visible, bool firstCall) {
    if (visible) {
      _analytics.onPageShown(_pageName);
    } else {
      _analytics.onPageHidden(_pageName);
    }
  }

  @override
  bool get wantKeepAlive => _keepAlive;
}

class UIValuesFactory {
  final ResCallback<WidgetRef> _ref;
  UIValuesFactory(this._ref);
  UIValue<T> create<T>(T initialValue) {
    return UIValue(initialValue, _ref.call());
  }
}
