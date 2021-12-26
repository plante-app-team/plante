import 'package:flutter_test/flutter_test.dart';
import 'package:plante/ui/map/components/delayed_lossy_arg_callback.dart';

void main() {
  setUp(() async {});

  testWidgets('callback is called after delay', (WidgetTester tester) async {
    final receivedArgs = <int>[];
    final callback = DelayedLossyArgCallback<int>(
      const Duration(seconds: 2),
      receivedArgs.add,
      enabledInTests: true,
    );
    expect(receivedArgs, isEmpty);

    callback.call(123);
    expect(receivedArgs, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(receivedArgs, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(receivedArgs, equals([123]));

    callback.call(321);
    expect(receivedArgs, equals([123]));

    await tester.pump(const Duration(seconds: 1));
    expect(receivedArgs, equals([123]));

    await tester.pump(const Duration(seconds: 1));
    expect(receivedArgs, equals([123, 321]));
  });

  testWidgets('callback call is delayed with each of new calls',
      (WidgetTester tester) async {
    final receivedArgs = <int>[];
    final callback = DelayedLossyArgCallback<int>(
      const Duration(seconds: 2),
      receivedArgs.add,
      enabledInTests: true,
    );

    callback.call(123);
    await tester.pump(const Duration(seconds: 1));
    callback.call(321);
    await tester.pump(const Duration(seconds: 1));
    callback.call(111);
    await tester.pump(const Duration(seconds: 1));
    callback.call(222);
    await tester.pump(const Duration(seconds: 1));
    callback.call(333);
    await tester.pump(const Duration(seconds: 1));
    expect(receivedArgs, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    expect(receivedArgs, equals([333]));

    callback.call(123);
    await tester.pump(const Duration(seconds: 2));
    expect(receivedArgs, equals([333, 123]));
  });
}
