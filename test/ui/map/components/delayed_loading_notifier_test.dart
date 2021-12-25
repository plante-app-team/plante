import 'package:flutter_test/flutter_test.dart';
import 'package:plante/ui/map/components/delayed_loading_notifier.dart';

void main() {
  setUp(() async {});

  testWidgets('first notification delayed', (WidgetTester tester) async {
    var callsCount = 0;
    final callback = () {
      callsCount += 1;
    };
    final notifier = DelayedLoadingNotifier(
        firstLoadingInstantNotification: false,
        callback: callback,
        delay: const Duration(seconds: 2));

    notifier.onLoadingStart();
    expect(callsCount, equals(0));
    expect(notifier.isLoading, isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(callsCount, equals(0));
    expect(notifier.isLoading, isFalse);

    await tester.pump(const Duration(seconds: 2));
    expect(callsCount, equals(1));
    expect(notifier.isLoading, isTrue);

    notifier.onLoadingEnd();
    expect(callsCount, equals(2));
    expect(notifier.isLoading, isFalse);
  });

  testWidgets('first notification immediate', (WidgetTester tester) async {
    var callsCount = 0;
    final callback = () {
      callsCount += 1;
    };
    final notifier = DelayedLoadingNotifier(
        firstLoadingInstantNotification: true,
        callback: callback,
        delay: const Duration(seconds: 2));

    notifier.onLoadingStart();
    await tester.pump(const Duration(microseconds: 1));

    expect(callsCount, equals(1));
    expect(notifier.isLoading, isTrue);

    notifier.onLoadingEnd();
    expect(callsCount, equals(2));
    expect(notifier.isLoading, isFalse);
  });

  testWidgets('second notification', (WidgetTester tester) async {
    var callsCount = 0;
    final callback = () {
      callsCount += 1;
    };
    final notifier = DelayedLoadingNotifier(
        firstLoadingInstantNotification: false,
        callback: callback,
        delay: const Duration(seconds: 2));

    // Start #1
    notifier.onLoadingStart();
    await tester.pump(const Duration(seconds: 10));
    expect(notifier.isLoading, isTrue);

    // End #1
    notifier.onLoadingEnd();
    expect(notifier.isLoading, isFalse);
    expect(callsCount, equals(2));

    // Start #2
    notifier.onLoadingStart();
    await tester.pump(const Duration(seconds: 10));
    expect(callsCount, equals(3));
    expect(notifier.isLoading, isTrue);

    // End #2
    notifier.onLoadingEnd();
    expect(notifier.isLoading, isFalse);
    expect(callsCount, equals(4));
  });

  testWidgets('loading end before delay', (WidgetTester tester) async {
    var callsCount = 0;
    final callback = () {
      callsCount += 1;
    };
    final notifier = DelayedLoadingNotifier(
        firstLoadingInstantNotification: false,
        callback: callback,
        delay: const Duration(seconds: 2));

    notifier.onLoadingStart();
    expect(notifier.isLoading, isFalse);

    await tester.pump(const Duration(microseconds: 1));
    notifier.onLoadingEnd();

    await tester.pump(const Duration(seconds: 10));

    expect(notifier.isLoading, isFalse);
    expect(callsCount, equals(0));
  });

  testWidgets('several loading starts', (WidgetTester tester) async {
    final notifier = DelayedLoadingNotifier(
        firstLoadingInstantNotification: true,
        callback: () {},
        delay: const Duration(seconds: 2));

    notifier.onLoadingStart();
    await tester.pump(const Duration(seconds: 10));
    notifier.onLoadingStart();
    await tester.pump(const Duration(seconds: 10));

    expect(notifier.isLoading, isTrue);

    // First loading stop
    notifier.onLoadingEnd();
    expect(notifier.isLoading, isTrue);

    // Second loading stop
    notifier.onLoadingEnd();
    expect(notifier.isLoading, isFalse);
  });

  testWidgets('too many loadings ends', (WidgetTester tester) async {
    final notifier = DelayedLoadingNotifier(
        firstLoadingInstantNotification: true,
        callback: () {},
        delay: const Duration(seconds: 2));

    // First loading
    notifier.onLoadingStart();
    await tester.pump(const Duration(seconds: 10));
    expect(notifier.isLoading, isTrue);

    notifier.onLoadingEnd();
    expect(notifier.isLoading, isFalse);

    // Oh no, extra loading ends
    notifier.onLoadingEnd();
    notifier.onLoadingEnd();
    notifier.onLoadingEnd();

    // Second loading
    notifier.onLoadingStart();
    await tester.pump(const Duration(seconds: 10));
    expect(notifier.isLoading, isTrue);

    notifier.onLoadingEnd();
    expect(notifier.isLoading, isFalse);
  });
}
