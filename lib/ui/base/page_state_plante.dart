import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';

abstract class PageStatePlante<T extends StatefulWidget> extends State<T> {
  late final Analytics _analytics;
  final String _pageName;

  @protected
  Analytics get analytics => _analytics;

  PageStatePlante(this._pageName) : _analytics = GetIt.I.get<Analytics>();

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
