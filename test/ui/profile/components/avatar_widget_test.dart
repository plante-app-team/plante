import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/profile/components/avatar_widget.dart';

import '../../../widget_tester_extension.dart';

void main() {
  final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);

  testWidgets('image shown', (WidgetTester tester) async {
    final headers = () async => {'auth': 'data'};
    await tester
        .superPump(AvatarWidget(uri: imagePath, authHeaders: headers.call()));
    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('image not shown when no image', (WidgetTester tester) async {
    final headers = () async => {'auth': 'data'};
    await tester
        .superPump(AvatarWidget(uri: null, authHeaders: headers.call()));
    expect(find.byType(UriImagePlante), findsNothing);
  });

  testWidgets('change image behaviour', (WidgetTester tester) async {
    final headers = () async => {'auth': 'data'};
    var changeClicks = 0;
    await tester.superPump(AvatarWidget(
        uri: imagePath,
        authHeaders: headers.call(),
        onChangeClick: () {
          changeClicks += 1;
        }));

    expect(changeClicks, equals(0));
    await tester.superTap(find.byKey(const Key('change_avatar_button')));
    expect(changeClicks, equals(1));
  });

  testWidgets('change image callback not provided',
      (WidgetTester tester) async {
    final headers = () async => {'auth': 'data'};
    await tester.superPump(AvatarWidget(
        uri: imagePath, authHeaders: headers.call(), onChangeClick: null));
    expect(find.byKey(const Key('change_avatar_button')), findsNothing);
  });
}
