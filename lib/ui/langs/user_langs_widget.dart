import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/ui/langs/lang_list_item.dart';
import 'package:plante/l10n/strings.dart';

/// Widget with a list of languages selected by user, which allows the user
/// to select and deselect them.
///
/// Selection and deselection is animated and the animating code is a mess.
/// Maybe that is because of the nature of Flutter, maybe because I can't cook
/// animations - either way I'm sorry.
class UserLangsWidget extends StatefulWidget {
  final UserLangs initialUserLangs;
  final ArgCallback<UserLangs> callback;
  const UserLangsWidget(
      {Key? key, required this.initialUserLangs, required this.callback})
      : super(key: key);

  @override
  _UserLangsWidgetState createState() => _UserLangsWidgetState();
}

class _UserLangsWidgetState extends State<UserLangsWidget>
    with TickerProviderStateMixin {
  late UserLangs _userLangs;

  /// Field being used for declarative-style animations of [LangListItem].
  /// See also [LangListItem.animationState].
  final _langsBeingSelected = <LangCode>{};

  /// Field being used for declarative-style animations of [LangListItem].
  /// See also [LangListItem.animationState].
  final _langsBeingDeselected = <LangCode>{};

  @override
  void initState() {
    super.initState();
    _userLangs = widget.initialUserLangs;
  }

  @override
  Widget build(BuildContext context) {
    final selectedLangsWidgets = _selectedLanguagesWidgets();
    final notSelectedLangsWidgets = _notSelectedLanguagesWidgets();

    return SingleChildScrollView(
        child: Column(children: [
      ReorderableListView(
          buildDefaultDragHandles: false,
          onReorder: _onSelectedLangReorder,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: selectedLangsWidgets),
      ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: notSelectedLangsWidgets,
      ),
    ]));
  }

  List<Widget> _selectedLanguagesWidgets() {
    final result = <Widget>[];
    for (var index = 0; index < _userLangs.langs.length; ++index) {
      final lang = _userLangs.langs[index];
      final sysLang = lang == _userLangs.sysLang;
      final selectedChangeCallback = sysLang
          ? null
          : (_) {
              setState(() {
                _langsBeingDeselected.add(lang);
              });
            };
      var animState = LangListItemAnimationState.NONE;
      if (_langsBeingSelected.contains(lang)) {
        animState = LangListItemAnimationState.BEING_ADDED;
      } else if (_langsBeingDeselected.contains(lang)) {
        animState = LangListItemAnimationState.BEING_REMOVED;
      }

      final child = LangListItem(
        key: Key(lang.name),
        index: index,
        lang: lang,
        displayIndex: true,
        reorderable: true,
        selected: true,
        hint: sysLang ? context.strings.user_langs_widget_system_lang : null,
        animationState: animState,
        animationTickerProvider: this,
        selectedChangeCallback: selectedChangeCallback,
        onRemoveAnimationEnd: () {
          _setStateALittleLater(() {
            _langsBeingDeselected.remove(lang);
            final updatedCodes = _userLangs.langs.toList();
            updatedCodes.remove(lang);
            _userLangs =
                _userLangs.rebuild((e) => e.langs = ListBuilder(updatedCodes));
            widget.callback.call(_userLangs);
          });
        },
      );
      result.add(child);
    }
    return result;
  }

  List<Widget> _notSelectedLanguagesWidgets() {
    final notSelectedLangsWidgets = <Widget>[];
    final notSelectedLangs = LangCode.valuesForUI(context);
    notSelectedLangs.removeWhere((l) {
      if (_langsBeingDeselected.contains(l) ||
          _langsBeingSelected.contains(l)) {
        return false;
      }
      return _userLangs.langs.contains(l);
    });
    for (var index = 0; index < notSelectedLangs.length; ++index) {
      final lang = notSelectedLangs[index];
      var animState = LangListItemAnimationState.NONE;
      if (_langsBeingSelected.contains(lang)) {
        animState = LangListItemAnimationState.BEING_REMOVED;
      } else if (_langsBeingDeselected.contains(lang)) {
        animState = LangListItemAnimationState.BEING_ADDED;
      }
      final child = LangListItem(
          key: Key(lang.name),
          index: index,
          lang: lang,
          reorderable: false,
          selected: false,
          animationState: animState,
          animationTickerProvider: this,
          selectedChangeCallback: (_) {
            setState(() {
              _langsBeingSelected.add(lang);
              final updatedCodes = _userLangs.langs.toList();
              updatedCodes.add(lang);
              _userLangs = _userLangs
                  .rebuild((e) => e.langs = ListBuilder(updatedCodes));
            });
            widget.callback.call(_userLangs);
          },
          onRemoveAnimationEnd: () {
            _setStateALittleLater(() {
              _langsBeingSelected.remove(lang);
            });
          });
      notSelectedLangsWidgets.add(child);
    }
    return notSelectedLangsWidgets;
  }

  /// Helper function to avoid calling of `setState` during `build`.
  void _setStateALittleLater(VoidCallback callback) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {
        callback.call();
      });
    });
  }

  void _onSelectedLangReorder(int oldIndex, int newIndex) {
    final langs = _userLangs.langs.toList();
    final item = langs.removeAt(oldIndex);
    if (oldIndex < newIndex) {
      langs.insert(newIndex - 1, item);
    } else {
      langs.insert(newIndex, item);
    }
    setState(() {
      _userLangs = _userLangs.rebuild((e) => e.langs = ListBuilder(langs));
    });
    widget.callback.call(_userLangs);
  }
}
