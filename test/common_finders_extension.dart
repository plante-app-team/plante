import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

extension CommonFindersExtension on CommonFinders {
  Finder richTextContaining(Pattern pattern, {bool skipOffstage = true}) =>
      _RichTextContainingFinder(pattern, skipOffstage: skipOffstage);
}

class _RichTextContainingFinder extends MatchFinder {
  final Pattern pattern;

  _RichTextContainingFinder(this.pattern, {bool skipOffstage = true})
      : super(skipOffstage: skipOffstage);

  @override
  String get description => 'rich text containing $pattern';

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;
    if (widget is RichText) {
      final text = widget.text.toPlainText();
      return text.contains(pattern);
    }
    return false;
  }
}
