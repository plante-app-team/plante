import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';

class MapSearchBarQueryView {
  String? _latestQuery;
  final _queryChangesController = StreamController<String>.broadcast();

  String get query => _latestQuery ?? '';
  Stream<String> get queryChanges => _queryChangesController.stream;

  MapSearchBarQueryView() {
    queryChanges.listen((event) {
      _latestQuery = event;
    });
  }

  void dispose() {
    _queryChangesController.close();
  }
}

class MapSearchBar extends StatefulWidget {
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? customPrefixSvgIcon;
  final VoidCallback? onPrefixIconTap;
  final ArgCallback<String>? onSearchTap;
  final VoidCallback? onDisabledTap;
  final VoidCallback? onCleared;
  final Duration? searchButtonAppearanceDelay;
  final String? queryInitial;
  final MapSearchBarQueryView? queryView;
  final String? queryOverride;
  const MapSearchBar(
      {Key? key,
      this.enabled = true,
      this.autofocus = false,
      this.focusNode,
      this.customPrefixSvgIcon,
      this.onPrefixIconTap,
      this.onSearchTap,
      this.onDisabledTap,
      this.onCleared,
      this.searchButtonAppearanceDelay,
      this.queryInitial,
      this.queryView,
      this.queryOverride})
      : super(key: key);

  @override
  _MapSearchBarState createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar>
    with TickerProviderStateMixin {
  static const _SIZE = 46.0;
  static const _DURATION = Duration(milliseconds: 200);
  var _canSearch = false;
  var _showSearchButton = false;
  final _textController = TextEditingController();
  String? previousQueryOverride;

  @override
  void initState() {
    super.initState();
    if (widget.queryOverride != null && widget.queryInitial != null) {
      Log.e('Providing both query override and '
          'initial values does not makes sense');
    }
    if (widget.queryOverride != null) {
      _textController.text = widget.queryOverride!;
    } else if (widget.queryInitial != null) {
      _textController.text = widget.queryInitial!;
    }
    previousQueryOverride = widget.queryOverride;

    _textController.addListener(_onQueryChange);
    if (widget.enabled) {
      if (widget.searchButtonAppearanceDelay != null) {
        final showSearchButton = () {
          if (mounted) {
            setState(() {
              _showSearchButton = true;
            });
          }
        };

        if (!isInTests()) {
          Future.delayed(widget.searchButtonAppearanceDelay!, showSearchButton);
        } else {
          showSearchButton.call();
        }
      } else {
        _showSearchButton = true;
      }
    }
  }

  void _onQueryChange() {
    _updateCanSearch();
    final query = _textController.text;
    widget.queryView?._queryChangesController.add(query);
  }

  void _updateCanSearch() {
    setState(() {
      _canSearch = widget.onSearchTap != null &&
          widget.enabled &&
          _textController.text.length > 1;
    });
  }

  @override
  void didUpdateWidget(MapSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queryOverride != null) {
      _textController.text = widget.queryOverride!;
    } else if (previousQueryOverride != null) {
      _textController.text = '';
    }
    previousQueryOverride = widget.queryOverride;
  }

  @override
  Widget build(BuildContext context) {
    final prefixSvgIcon = widget.customPrefixSvgIcon ?? 'assets/search.svg';
    final prefixIcon = _TextFieldIcon(
      onTap: widget.onPrefixIconTap,
      svg: prefixSvgIcon,
    );

    final showSuffixIcon = _textController.text.isNotEmpty;
    // Why [suffixIconEmpty] and [suffixIconReally] instead of
    // a single suffixIcon:
    // - Sometimes we want to show a disabled search bar,
    // - when a [TextField] is disabled, it ignores all clicks,
    // - "all clicks" include clicks on all of its icons,
    // - as a result, we cannot listen to clicks on icons while
    //   the widget is disabled,
    // - but we want to listen to such clicks,
    // - so we put a fake icon onto the [TextField] so that the field's text
    //   would be cut when it approaches the icon,
    // - and we put a real icon on top of this fake icon,
    // - the real icon's clickability is not limited by anything.
    const suffixIconEmpty = _TextFieldIcon(svg: 'assets/empty.svg');
    final suffixIconReally = SizedBox(
        width: _SIZE,
        height: _SIZE,
        child: _TextFieldIcon(
          key: const Key('map_search_bar_cancel'),
          onTap: () {
            _textController.clear();
            widget.onCleared?.call();
          },
          svg: 'assets/cancel_circle.svg',
        ));
    final textField = Stack(children: [
      InkWell(
          onTap: !widget.enabled ? widget.onDisabledTap : null,
          child: AnimatedSize(
              duration: _DURATION,
              vsync: this,
              child: TextField(
                key: const Key('map_search_bar_text_field'),
                textCapitalization: TextCapitalization.sentences,
                style: TextStyles.searchBarText,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                focusNode: widget.focusNode,
                onSubmitted: (query) {
                  widget.onSearchTap?.call(query);
                },
                decoration: InputDecoration(
                  prefixIcon: prefixIcon,
                  suffixIcon: showSuffixIcon ? suffixIconEmpty : null,
                  hintText: context.strings.map_search_bar_hint,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyles.searchBarHint,
                  fillColor: Colors.white,
                  filled: true,
                  disabledBorder: const OutlineInputBorder(
                    gapPadding: 2,
                    borderSide: BorderSide(width: 1, color: ColorsPlante.grey),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    gapPadding: 2,
                    borderSide:
                        BorderSide(width: 1, color: ColorsPlante.primary),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    gapPadding: 2,
                    borderSide:
                        BorderSide(width: 1, color: ColorsPlante.primary),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                controller: _textController,
              ))),
      if (showSuffixIcon)
        Align(alignment: Alignment.centerRight, child: suffixIconReally),
    ]);

    return SizedBox(
        height: _SIZE,
        child: Material(
            color: Colors.transparent,
            child: Row(children: [
              Expanded(child: textField),
              AnimatedSize(
                  duration: _DURATION,
                  vsync: this,
                  child: !_showSearchButton
                      ? const SizedBox.shrink()
                      : Row(children: [
                          const SizedBox(width: 10),
                          ButtonFilledPlante(
                              onPressed: _canSearch ? _onSearchPressed : null,
                              child: Text(
                                  context.strings.map_search_bar_button_title,
                                  style: TextStyles.normalWhite))
                        ]))
            ])));
  }

  void _onSearchPressed() {
    widget.onSearchTap?.call(_textController.text);
  }
}

class _TextFieldIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final String svg;
  const _TextFieldIcon({Key? key, this.onTap, required this.svg})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [SvgPicture.asset(svg)]),
        ));
  }
}
