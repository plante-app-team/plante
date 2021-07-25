import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';

import '../../../fake_app_lifecycle_watcher.dart';
import '../../../widget_tester_extension.dart';

void main() {
  testWidgets('notified when widget removed from tree and returned',
      (WidgetTester tester) async {
    bool? visible;
    var callsCount = 0;
    final visibilityDetector = VisibilityDetectorPlante(
      keyStr: 'key',
      onVisibilityChanged: (visibleIn, isFirst) {
        visible = visibleIn;
        callsCount += 1;
        if (isFirst) {
          expect(callsCount, equals(1));
        } else {
          expect(callsCount, isNot(equals(1)));
        }
      },
      child: Container(width: 10, height: 10, color: Colors.white),
    );
    final helper = _VisibilityDetectorTestHelper(visibilityDetector);

    expect(visible, isNull);
    expect(callsCount, equals(0));
    await tester.superPump(helper);
    await tester.pumpAndSettle();
    expect(visible, isTrue);
    expect(callsCount, equals(1));

    helper.showPage(1);
    await tester.pumpAndSettle();
    expect(visible, isFalse);
    expect(callsCount, equals(2));

    helper.showPage(0);
    await tester.pumpAndSettle();
    expect(visible, isTrue);
    expect(callsCount, equals(3));
  });

  testWidgets('notified when app minimized and maximized',
      (WidgetTester tester) async {
    final fakeLifecycleWatcher = FakeAppLifecycleWatcher();

    bool? visible;
    var callsCount = 0;
    final visibilityDetector = VisibilityDetectorPlante(
      keyStr: 'key',
      appLifecycleWatcher: fakeLifecycleWatcher,
      onVisibilityChanged: (visibleIn, isFirst) {
        visible = visibleIn;
        callsCount += 1;
        if (isFirst) {
          expect(callsCount, equals(1));
        } else {
          expect(callsCount, isNot(equals(1)));
        }
      },
      child: Container(width: 10, height: 10, color: Colors.white),
    );

    expect(visible, isNull);
    expect(callsCount, equals(0));
    await tester.superPump(visibilityDetector);
    await tester.pumpAndSettle();
    expect(visible, isTrue);
    expect(callsCount, equals(1));

    // Not in the background yet
    fakeLifecycleWatcher.changeAppStateTo(AppLifecycleState.inactive);
    expect(visible, isTrue);
    expect(callsCount, equals(1));

    // In the background!
    fakeLifecycleWatcher.changeAppStateTo(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(visible, isFalse);
    expect(callsCount, equals(2));

    // In the foreground!
    fakeLifecycleWatcher.changeAppStateTo(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(visible, isTrue);
    expect(callsCount, equals(3));
  });

  testWidgets(
      'each notification fires once when hidden, minimized, maximized and shown',
      (WidgetTester tester) async {
    final fakeLifecycleWatcher = FakeAppLifecycleWatcher();
    bool? visible;
    var callsCount = 0;
    final visibilityDetector = VisibilityDetectorPlante(
      keyStr: 'key',
      appLifecycleWatcher: fakeLifecycleWatcher,
      onVisibilityChanged: (visibleIn, isFirst) {
        visible = visibleIn;
        callsCount += 1;
        if (isFirst) {
          expect(callsCount, equals(1));
        } else {
          expect(callsCount, isNot(equals(1)));
        }
      },
      child: Container(width: 10, height: 10, color: Colors.white),
    );
    final helper = _VisibilityDetectorTestHelper(visibilityDetector);

    expect(visible, isNull);
    expect(callsCount, equals(0));
    await tester.superPump(helper);
    await tester.pumpAndSettle();
    expect(visible, isTrue);
    expect(callsCount, equals(1));

    // Hidden!
    helper.showPage(1);
    await tester.pumpAndSettle();
    expect(visible, isFalse);
    expect(callsCount, equals(2));

    // Minimized, expecting no new calls!
    fakeLifecycleWatcher.changeAppStateTo(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(visible, isFalse);
    expect(callsCount, equals(2));

    // Maximized, expecting no new calls!
    fakeLifecycleWatcher.changeAppStateTo(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(visible, isFalse);
    expect(callsCount, equals(2));

    // Shown!
    helper.showPage(0);
    await tester.pumpAndSettle();
    expect(visible, isTrue);
    expect(callsCount, equals(3));
  });
}

class _VisibilityDetectorTestHelper extends StatefulWidget {
  final VisibilityDetectorPlante visibilityDetector;
  final _storage = _VisibilityDetectorTestHelperCallbacksStorage();
  _VisibilityDetectorTestHelper(this.visibilityDetector, {Key? key})
      : super(key: key);

  @override
  __VisibilityDetectorTestHelperState createState() =>
      __VisibilityDetectorTestHelperState();

  void showPage(int page) {
    _storage._showPageCallback!.call(page);
  }
}

class _VisibilityDetectorTestHelperCallbacksStorage {
  ArgCallback<int>? _showPageCallback;
}

class __VisibilityDetectorTestHelperState
    extends State<_VisibilityDetectorTestHelper> {
  var _page = 0;

  @override
  void initState() {
    super.initState();
    widget._storage._showPageCallback = (page) {
      setState(() {
        _page = page;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(index: _page, children: [
      widget.visibilityDetector,
      const SizedBox.shrink(),
    ]);
  }
}
