import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/popup/popup_plante.dart';

import '../../../widget_tester_extension.dart';

// ignore_for_file: must_be_immutable

void main() {
  setUp(() async {});

  testWidgets('showCustomPopUp', (WidgetTester tester) async {
    final widget = _TestingHelperWidget();
    await tester.superPump(widget);

    expect(find.text(widget.state.popUpText), findsNothing);
    await tester.superTap(find.byKey(widget.state.popupButtonKey));
    expect(find.text(widget.state.popUpText), findsOneWidget);
  });
}

class _TestingHelperWidget extends StatefulWidget {
  late _TestingHelperWidgetState state;

  _TestingHelperWidget({Key? key}) : super(key: key);

  @override
  _TestingHelperWidgetState createState() {
    state = _TestingHelperWidgetState();
    return state;
  }
}

class _TestingHelperWidgetState extends State<_TestingHelperWidget> {
  final popupButtonKey = GlobalKey();
  final popUpText = 'pop up text';

  @override
  Widget build(BuildContext context) {
    return ButtonFilledPlante(
        key: popupButtonKey,
        onPressed: () {
          showCustomPopUp(
            target: popupButtonKey,
            context: context,
            child: Text(popUpText),
          );
        },
        child: const SizedBox());
  }
}
