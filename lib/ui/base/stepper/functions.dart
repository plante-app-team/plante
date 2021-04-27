import 'package:flutter/widgets.dart';

enum PageIndicatorState { NOT_REACHED, CURRENT, PASSED }

typedef PageIndicatorMaker = Widget Function(
    int page, PageIndicatorState state);
typedef DividerMaker = Widget Function(
    int leftPage, int rightPage, bool leftReached, bool rightReached);
typedef BackButtonMaker = Widget? Function(Function() back);
