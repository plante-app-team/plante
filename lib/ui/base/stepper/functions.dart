import 'package:flutter/widgets.dart';

typedef PageIndicatorMaker = Widget Function(int page, bool pageReached);
typedef DividerMaker = Widget Function(
    int leftPage, int rightPage, bool leftReached, bool rightReached);
