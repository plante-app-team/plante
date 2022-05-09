import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/ui_value.dart';

class StatefulStackForTesting extends ConsumerStatefulWidget {
  final WidgetTester tester;
  final List<Widget> children;
  final _storage = StatefulStackForTestingStorage();
  StatefulStackForTesting(
      {Key? key, required this.tester, required this.children})
      : super(key: key);

  @override
  _StatefulStackForTestingState createState() =>
      _StatefulStackForTestingState();

  Future<void> switchStackToIndex(int index) async {
    _storage.switchToIndexFn!.call(index);
    await tester.pumpAndSettle();
  }
}

class StatefulStackForTestingStorage {
  ArgCallback<int>? switchToIndexFn;
}

class _StatefulStackForTestingState
    extends ConsumerState<StatefulStackForTesting> {
  late final _index = UIValue<int?>(null, ref);

  @override
  void initState() {
    super.initState();
    widget._storage.switchToIndexFn = _index.setValue;
  }

  @override
  Widget build(BuildContext context) {
    final index = _index.watch(ref);
    if (index == null) {
      return const SizedBox();
    }
    return IndexedStack(index: index, children: widget.children);
  }
}
