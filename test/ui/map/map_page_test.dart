import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/l10n/strings.dart';

import '../../widget_tester_extension.dart';
import 'map_page_modes_test_commons.dart';
import 'map_page_modes_test_commons.mocks.dart';

/// NOTE: this file contains tests only for mechanics
/// common for all map page modes
void main() {
  late MapPageModesTestCommons commons;
  late MockGoogleMapController mapController;
  late MockPermissionsManager permissionsManager;
  late LocationController locationController;

  setUp(() async {
    commons = MapPageModesTestCommons();
    await commons.setUp();
    mapController = commons.mapController;
    permissionsManager = commons.permissionsManager;
    locationController = commons.locationController;
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
    expect(find.text(
        context.strings.map_page_location_permission_reasoning_settings),
        findsOneWidget);
    verifyNever(permissionsManager.openAppSettings());
    await tester.tap(find.text(context.strings.global_open_app_settings));
    await tester.pumpAndSettle();
    verify(permissionsManager.openAppSettings());

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
}
