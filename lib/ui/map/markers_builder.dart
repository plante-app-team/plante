import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/model/shop.dart';

Future<Marker> markersBuilder(Cluster<Shop> cluster) async {
  return Marker(
    markerId: MarkerId(cluster.getId()),
    position: cluster.location,
    onTap: () {
      print('---- $cluster');
      cluster.items.forEach(print);
    },
    icon: await _getMarkerBitmap(
        cluster.items.where((element) => element != null).map((e) => e!)),
  );
}

Future<BitmapDescriptor> _getMarkerBitmap(Iterable<Shop> shops) async {
  const size = 125;
  final PictureRecorder pictureRecorder = PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Color paint1Color;
  if (shops.any((e) => e.productsCount > 0)) {
    paint1Color = Colors.orange;
  } else {
    paint1Color = Colors.grey;
  }
  final Paint paint1 = Paint()..color = paint1Color;
  final Paint paint2 = Paint()..color = Colors.white;

  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.0, paint1);
  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint2);
  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.8, paint1);

  if (shops.length > 1) {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: shops.length.toString(),
      style: const TextStyle(
          fontSize: size / 3,
          color: Colors.white,
          fontWeight: FontWeight.normal),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
    );
  }

  final img = await pictureRecorder.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}
