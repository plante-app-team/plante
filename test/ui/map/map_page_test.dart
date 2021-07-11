import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_model.dart';

import '../../fake_analytics.dart';
import '../../widget_tester_extension.dart';
import 'map_page_modes_test_commons.dart';
import 'map_page_modes_test_commons.mocks.dart';

/// NOTE: this file contains tests only for mechanics
/// common for all map page modes
void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late MockPermissionsManager permissionsManager;
  late MockLocationController locationController;
  late MockLatestCameraPosStorage latestCameraPosStorage;
  late FakeAnalytics analytics;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    permissionsManager = commons.permissionsManager;
    locationController = commons.locationController;
    latestCameraPosStorage = commons.latestCameraPosStorage;
    analytics = commons.analytics;
  });

  testWidgets('my location when have permission', (WidgetTester tester) async {
    when(permissionsManager.status(PermissionKind.LOCATION)).thenAnswer(
            (_) async => PermissionState.granted);

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    verifyNever(locationController.currentPosition());
    await tester.tap(find.byKey(const Key('my_location_fab')));
    await tester.pumpAndSettle();
    verify(locationController.currentPosition());

    verifyNever(permissionsManager.request(any));
  });

  testWidgets('my location when no permission', (WidgetTester tester) async {
    when(permissionsManager.status(PermissionKind.LOCATION)).thenAnswer(
            (_) async => PermissionState.denied);

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    // First request will be denied
    when(permissionsManager.request(PermissionKind.LOCATION)).thenAnswer((_) async {
      return PermissionState.denied;
    });

    // First request
    await tester.tap(find.byKey(const Key('my_location_fab')));
    await tester.pumpAndSettle();
    verify(permissionsManager.request(PermissionKind.LOCATION));
    verifyNever(locationController.currentPosition());

    // Second request will be granted
    when(permissionsManager.request(PermissionKind.LOCATION)).thenAnswer((_) async {
      when(permissionsManager.status(PermissionKind.LOCATION)).thenAnswer(
              (_) async => PermissionState.granted);
      return PermissionState.granted;
    });

    // Second request
    await tester.tap(find.byKey(const Key('my_location_fab')));
    await tester.pumpAndSettle();
    verify(permissionsManager.request(PermissionKind.LOCATION));
    verify(locationController.currentPosition());
  });

  testWidgets('my location when permanently no permission', (WidgetTester tester) async {
    when(permissionsManager.status(PermissionKind.LOCATION)).thenAnswer(
            (_) async => PermissionState.denied);

    final widget = MapPage(mapControllerForTesting: mapController);
    final context = await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    // First request will be denied
    when(permissionsManager.request(PermissionKind.LOCATION)).thenAnswer((_) async {
      return PermissionState.permanentlyDenied;
    });

    // First request
    await tester.tap(find.byKey(const Key('my_location_fab')));
    await tester.pumpAndSettle();
    verify(permissionsManager.request(PermissionKind.LOCATION));
    verifyNever(locationController.currentPosition());

    // Verify the user is asked to go to the settings
    expect(
        find.text(
            context.strings.map_page_location_permission_reasoning_settings),
        findsOneWidget);
    verifyNever(permissionsManager.openAppSettings());
    await tester.tap(
        find.text(context.strings.map_page_location_permission_go_to_settings));
    await tester.pumpAndSettle();
    verify(permissionsManager.openAppSettings());

    // Second request will be granted
    when(permissionsManager.request(PermissionKind.LOCATION))
        .thenAnswer((_) async {
      when(permissionsManager.status(PermissionKind.LOCATION))
          .thenAnswer((_) async => PermissionState.granted);
      return PermissionState.granted;
    });

    // Second request
    await tester.tap(find.byKey(const Key('my_location_fab')));
    await tester.pumpAndSettle();
    verify(permissionsManager.request(PermissionKind.LOCATION));
    verify(locationController.currentPosition());
  });

  testWidgets('start camera pos when it is available', (WidgetTester tester) async {
    const initialPos = Point<double>(10, 20);
    const notInitialPos = Point<double>(20, 30);
    when(latestCameraPosStorage.getCached()).thenAnswer((_) => initialPos);
    when(latestCameraPosStorage.get()).thenAnswer((_) async => notInitialPos);
    when(locationController.lastKnownPositionInstant()).thenReturn(notInitialPos);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.currentPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      final callback = invc.positionalArguments[0] as ArgCallback<Point<double>>;
      callback.call(notInitialPos);
    });

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);

    final map = find.byType(GoogleMap).evaluate().first.widget as GoogleMap;
    expect(map.initialCameraPosition.target.longitude, initialPos.x);
    expect(map.initialCameraPosition.target.latitude, initialPos.y);

    // Ensure that instant start pos was enough
    await tester.pumpAndSettle();
    verifyNever(mapController.animateCamera(any));
  });

  testWidgets('start camera pos when it is not available but user pos is cached', (WidgetTester tester) async {
    const initialPos = Point<double>(10, 20);
    const notInitialPos = Point<double>(20, 30);
    when(latestCameraPosStorage.getCached()).thenAnswer((_) => null);
    when(latestCameraPosStorage.get()).thenAnswer((_) async => notInitialPos);
    when(locationController.lastKnownPositionInstant()).thenReturn(initialPos);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.currentPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      final callback = invc.positionalArguments[0] as ArgCallback<Point<double>>;
      callback.call(notInitialPos);
    });

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);

    final map = find.byType(GoogleMap).evaluate().first.widget as GoogleMap;
    expect(map.initialCameraPosition.target.longitude, initialPos.x);
    expect(map.initialCameraPosition.target.latitude, initialPos.y);

    // Ensure that instant start pos was enough
    await tester.pumpAndSettle();
    verifyNever(mapController.animateCamera(any));
  });

  testWidgets('start camera pos when no cache and instant positions are available', (WidgetTester tester) async {
    const notInitialPos = Point<double>(20, 30);
    when(latestCameraPosStorage.getCached()).thenAnswer((_) => null);
    when(latestCameraPosStorage.get()).thenAnswer((_) async => notInitialPos);
    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.currentPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      final callback = invc.positionalArguments[0] as ArgCallback<Point<double>>;
      callback.call(notInitialPos);
    });

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);

    final map = find.byType(GoogleMap).evaluate().first.widget as GoogleMap;
    expect(map.initialCameraPosition.target.longitude,
        MapPageModel.DEFAULT_USER_POS.longitude);
    expect(map.initialCameraPosition.target.latitude,
        MapPageModel.DEFAULT_USER_POS.latitude);

    // Ensure that instant start pos was NOT enough
    await tester.pumpAndSettle();
    verify(mapController.animateCamera(any));
  });

  testWidgets('delayed start camera pos when latest camera pos loaded', (WidgetTester tester) async {
    const initialPos = Point<double>(10, 20);
    const notInitialPos = Point<double>(20, 30);
    final initialPosCompleter = Completer<Point<double>>();
    when(latestCameraPosStorage.getCached()).thenAnswer((_) => null);
    when(latestCameraPosStorage.get()).thenAnswer((_) async => initialPosCompleter.future);
    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.currentPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      final callback = invc.positionalArguments[0] as ArgCallback<Point<double>>;
      callback.call(notInitialPos);
    });

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);

    // Initial pos
    final map = find.byType(GoogleMap).evaluate().first.widget as GoogleMap;
    expect(map.initialCameraPosition.target.longitude,
        MapPageModel.DEFAULT_USER_POS.longitude);
    expect(map.initialCameraPosition.target.latitude,
        MapPageModel.DEFAULT_USER_POS.latitude);

    verifyNever(mapController.animateCamera(any));

    // Real initial pos becomes available
    initialPosCompleter.complete(initialPos);
    await tester.pumpAndSettle();

    final cameraUpdate = verify(mapController.animateCamera(captureAny))
        .captured.first as CameraUpdate;
    expect(_cameraUpdateToPos(cameraUpdate), equals(initialPos));
  });

  testWidgets('delayed start camera pos when latest camera pos NOT loaded but '
              'last known pos is available', (WidgetTester tester) async {
    const initialPos = Point<double>(10, 20);
    const notInitialPos = Point<double>(20, 30);
    final initialPosCompleter = Completer<Point<double>>();
    when(latestCameraPosStorage.getCached()).thenAnswer((_) => null);
    when(latestCameraPosStorage.get()).thenAnswer((_) async => null);
    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => initialPosCompleter.future);
    when(locationController.currentPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      final callback = invc.positionalArguments[0] as ArgCallback<Point<double>>;
      callback.call(notInitialPos);
    });

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);

    // Initial pos
    final map = find.byType(GoogleMap).evaluate().first.widget as GoogleMap;
    expect(map.initialCameraPosition.target.longitude,
        MapPageModel.DEFAULT_USER_POS.longitude);
    expect(map.initialCameraPosition.target.latitude,
        MapPageModel.DEFAULT_USER_POS.latitude);

    verifyNever(mapController.animateCamera(any));

    // Real initial pos becomes available
    initialPosCompleter.complete(initialPos);
    await tester.pumpAndSettle();

    final cameraUpdate = verify(mapController.animateCamera(captureAny))
        .captured.first as CameraUpdate;
    expect(_cameraUpdateToPos(cameraUpdate), equals(initialPos));
  });

  testWidgets('delayed start camera pos when latest camera pos NOT loaded but '
              'latest user pos eventually becomes available', (WidgetTester tester) async {
    const initialPos = Point<double>(10, 20);
    const notInitialPos = Point<double>(20, 30);
    ArgCallback<Point<double>>? initialPosCallback;
    when(latestCameraPosStorage.getCached()).thenAnswer((_) => null);
    when(latestCameraPosStorage.get()).thenAnswer((_) async => null);
    when(locationController.lastKnownPositionInstant()).thenReturn(null);
    when(locationController.lastKnownPosition()).thenAnswer((_) async => null);
    when(locationController.currentPosition()).thenAnswer((_) async => notInitialPos);
    when(locationController.callWhenLastPositionKnown(any)).thenAnswer((invc) {
      initialPosCallback = invc.positionalArguments[0] as ArgCallback<Point<double>>;
    });

    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);

    // Initial pos
    final map = find.byType(GoogleMap).evaluate().first.widget as GoogleMap;
    expect(map.initialCameraPosition.target.longitude,
        MapPageModel.DEFAULT_USER_POS.longitude);
    expect(map.initialCameraPosition.target.latitude,
        MapPageModel.DEFAULT_USER_POS.latitude);

    verifyNever(mapController.animateCamera(any));

    // Real initial pos becomes available
    initialPosCallback!.call(initialPos);
    await tester.pumpAndSettle();

    final cameraUpdate = verify(mapController.animateCamera(captureAny))
        .captured.first as CameraUpdate;
    expect(_cameraUpdateToPos(cameraUpdate), equals(initialPos));
  });

  // Testing workaround for https://trello.com/c/D33qHsGn/
  // (https://github.com/flutter/flutter/issues/40284)
  testWidgets('map style is reset on hide-show events', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);

    clearInteractions(mapController);

    final visibilityDetector = find.byKey(
        const Key('map_page_visibility_detector'))
        .evaluate().first.widget as VisibilityDetectorPlante;

    // First 'show' event is not expected to trigger style setting
    var firstCall = true;
    visibilityDetector.onVisibilityChanged.call(true, firstCall);
    await tester.pumpAndSettle();
    verifyNever(mapController.setMapStyle(any));

    // 'Hide' event is not expected to trigger style setting
    firstCall = false;
    visibilityDetector.onVisibilityChanged.call(false, firstCall);
    await tester.pumpAndSettle();
    verifyNever(mapController.setMapStyle(any));

    // Second 'show' event!
    firstCall = false;
    visibilityDetector.onVisibilityChanged.call(true, firstCall);
    await tester.pumpAndSettle();
    verify(mapController.setMapStyle(any));
  });

  testWidgets('shop click analytics', (WidgetTester tester) async {
    final widget = MapPage(mapControllerForTesting: mapController);
    await tester.superPump(widget);
    widget.onMapIdleForTesting();
    await tester.pumpAndSettle();

    analytics.clearEvents();

    widget.onMarkerClickForTesting(commons.shops);
    await tester.pumpAndSettle();

    expect(analytics.allEvents().length, equals(1));
    expect(analytics.sentEventParams('map_shops_click'), {
      'shops': commons.shops.map((e) => e.osmId).join(', ')
    });
  });
}

Point<double> _cameraUpdateToPos(CameraUpdate cameraUpdate) {
  final json = cameraUpdate.toJson() as dynamic;
  final x = json[1]['target'][1] as double;
  final y = json[1]['target'][0] as double;
  return Point<double>(x, y);
}
