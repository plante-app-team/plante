import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';

class MapSearchBarQueryView {
  ResCallback<String>? _query;
  String get query => _query?.call() ?? '';
}

class MapSearchBar extends StatefulWidget {
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? customPrefixSvgIcon;
  final VoidCallback? onPrefixIconTap;
  final ArgCallback<String>? onSearchTap;
  final VoidCallback? onCleared;
  final Duration? searchButtonAppearanceDelay;
  final MapSearchBarQueryView? queryView;
  const MapSearchBar(
      {Key? key,
      this.enabled = true,
      this.autofocus = false,
      this.focusNode,
      this.customPrefixSvgIcon,
      this.onPrefixIconTap,
      this.onSearchTap,
      this.onCleared,
      this.searchButtonAppearanceDelay,
      this.queryView})
      : super(key: key);

  @override
  _MapSearchBarState createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar>
    with TickerProviderStateMixin {
  static const _DURATION = Duration(milliseconds: 200);
  var _canSearch = false;
  var _showSearchButton = false;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.queryView?._query = () => _textController.text;
    _textController.addListener(_updateCanSearch);
    _updateCanSearch();
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
  }

  @override
  Widget build(BuildContext context) {
    final prefixSvgIcon = widget.customPrefixSvgIcon ?? 'assets/search.svg';
    final prefixIcon = _TextFieldIcon(
      onTap: widget.onPrefixIconTap,
      svg: prefixSvgIcon,
    );
    final suffixIcon = _TextFieldIcon(
      key: const Key('map_search_bar_cancel'),
      onTap: () {
        _textController.clear();
        widget.onCleared?.call();
      },
      svg: 'assets/cancel_circle.svg',
    );
    return SizedBox(
        height: 46,
        child: Material(
            color: Colors.transparent,
            child: Row(children: [
              Expanded(
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
                        decoration: InputDecoration(
                          prefixIcon: prefixIcon,
                          suffixIcon: _textController.text.isNotEmpty
                              ? suffixIcon
                              : null,
                          hintText: context.strings.map_search_bar_hint,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyles.searchBarHint,
                          fillColor: Colors.white,
                          filled: true,
                          disabledBorder: const OutlineInputBorder(
                            gapPadding: 2,
                            borderSide:
                                BorderSide(width: 1, color: ColorsPlante.grey),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            gapPadding: 2,
                            borderSide: BorderSide(
                                width: 1, color: ColorsPlante.primary),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            gapPadding: 2,
                            borderSide: BorderSide(
                                width: 1, color: ColorsPlante.primary),
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        controller: _textController,
                      ))),
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
  const _TextFieldIcon({Key? key, required this.onTap, required this.svg})
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
