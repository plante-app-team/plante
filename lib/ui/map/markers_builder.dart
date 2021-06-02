import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/model/shop.dart';

typedef MarkerClickCallback = void Function(Iterable<Shop> shops);

class ShopsMarkersExtraData {
  final Set<Shop> selectedShops;
  ShopsMarkersExtraData(this.selectedShops);
}

Future<Marker> markersBuilder(
    Cluster<Shop> cluster,
    ShopsMarkersExtraData extraData,
    BuildContext context,
    MarkerClickCallback callback) async {
  final shops =
      cluster.items.where((element) => element != null).map((e) => e!);
  return Marker(
    markerId: MarkerId(cluster.getId()),
    position: cluster.location,
    onTap: () {
      callback(
          cluster.items.where((shop) => shop != null).map((shop) => shop!));
    },
    icon: await _getMarkerBitmap(shops, extraData, context),
  );
}

Future<BitmapDescriptor> _getMarkerBitmap(Iterable<Shop> shops,
    ShopsMarkersExtraData extraData, BuildContext context) async {
  if (shops.length == 1) {
    if (extraData.selectedShops.contains(shops.first)) {
      return _bitmapDescriptorFromSvgAsset(
          context, 'assets/map_marker_selected.svg');
    } else if (shops.any((e) => e.productsCount > 0)) {
      return _bitmapDescriptorFromSvgAsset(
          context, 'assets/map_marker_filled.svg');
    } else {
      return _bitmapDescriptorFromSvgAsset(
          context, 'assets/map_marker_empty.svg');
    }
  } else {
    if (shops.any((e) => extraData.selectedShops.contains(e))) {
      throw Exception('Not supported yet - we have no image!');
    } else if (shops.any((e) => e.productsCount > 0)) {
      return _bitmapDescriptorFromSvgAsset(
          context, 'assets/map_marker_group_filled.svg');
    } else {
      return _bitmapDescriptorFromSvgAsset(
          context, 'assets/map_marker_group_empty.svg');
    }
  }
}

/// Stolen from https://stackoverflow.com/a/57609840
Future<BitmapDescriptor> _bitmapDescriptorFromSvgAsset(
    BuildContext context, String assetName) async {
  final svgString = await DefaultAssetBundle.of(context).loadString(assetName);
  final svgDrawableRoot = await svg.fromSvgString(svgString, '');

  // toPicture() and toImage() don't seem to be pixel ratio aware,
  // so we calculate the actual sizes here
  final queryData = MediaQuery.of(context);
  final devicePixelRatio = queryData.devicePixelRatio;
  final width = 32 * devicePixelRatio; // where 32 is your SVG's original width
  final height = 40 * devicePixelRatio; // same thing

  final picture = svgDrawableRoot.toPicture(size: Size(width, height));

  final image = await picture.toImage(width.round(), height.round());
  final bytes = await image.toByteData(format: ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}
