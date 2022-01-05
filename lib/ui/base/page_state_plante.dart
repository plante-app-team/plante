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

abstract class PageStatePlante<T extends PagePlante> extends ConsumerState<T> {
  late final Analytics _analytics;
  final String _pageName;
  late final UIValuesFactory _uiValuesFactory;

  @protected
  Analytics get analytics => _analytics;

  @protected
  UIValuesFactory get uiValuesFactory => _uiValuesFactory;

  PageStatePlante(this._pageName) : _analytics = GetIt.I.get<Analytics>() {
    _uiValuesFactory = UIValuesFactory(() => ref);
  }

  Widget buildPage(BuildContext context);

  @nonVirtual
  @override
  Widget build(BuildContext context) {
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
}

class UIValuesFactory {
  final ResCallback<WidgetRef> _ref;
  UIValuesFactory(this._ref);
  UIValue<T> create<T>(T initialValue) {
    return UIValue(initialValue, _ref.call());
  }
}
