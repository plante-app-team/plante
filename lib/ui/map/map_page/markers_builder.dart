import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/products/suggestions/suggested_barcodes_map_full.dart';
import 'package:plante/ui/base/text_styles.dart';

typedef MarkerClickCallback = void Function(Iterable<Shop> shops);

class ShopsMarkersExtraData {
  final Set<Shop> selectedShops;
  final Set<Shop> accentedShops;
  final SuggestedBarcodesMapFull barcodesSuggestions;
  ShopsMarkersExtraData(
      this.selectedShops, this.accentedShops, this.barcodesSuggestions);
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
  final hasSuggestions = (Shop shop) {
    return extraData.barcodesSuggestions.suggestionsCountFor(shop.osmUID) > 0;
  };
  if (shops.length == 1) {
    if (extraData.accentedShops.contains(shops.first)) {
      return _bitmapDescriptorFromSvgAsset(context,
          'assets/map_marker_accented.svg', 1, TextStyles.markerAccented);
    } else if (extraData.selectedShops.contains(shops.first)) {
      return _bitmapDescriptorFromSvgAsset(context,
          'assets/map_marker_selected.svg', 1, TextStyles.markerFilled);
    } else if (shops.any((e) => e.productsCount > 0)) {
      return _bitmapDescriptorFromSvgAsset(
          context, 'assets/map_marker_filled.svg', 1, TextStyles.markerFilled);
    } else if (shops.any(hasSuggestions)) {
      return _bitmapDescriptorFromSvgAsset(context,
          'assets/map_marker_suggestions.svg', 1, TextStyles.markerSuggestion);
    } else {
      return _bitmapDescriptorFromSvgAsset(
          context, 'assets/map_marker_empty.svg', 1, TextStyles.markerEmpty);
    }
  } else {
    if (shops.any((e) => extraData.accentedShops.contains(e))) {
      return _bitmapDescriptorFromSvgAsset(
          context,
          'assets/map_marker_group_accented.svg',
          shops.length,
          TextStyles.markerAccented);
    } else if (shops.any((e) => extraData.selectedShops.contains(e))) {
      return _bitmapDescriptorFromSvgAsset(
          context,
          'assets/map_marker_group_selected.svg',
          // The icon has a checkmark where the
          // shops number would be, so we want to draw no number,
          // and to do that we act as if there's just 1 shop at the marker.
          1,
          TextStyles.markerFilled);
    } else if (shops.any((e) => e.productsCount > 0)) {
      return _bitmapDescriptorFromSvgAsset(
          context,
          'assets/map_marker_group_filled.svg',
          shops.length,
          TextStyles.markerFilled);
    } else if (shops.any(hasSuggestions)) {
      return _bitmapDescriptorFromSvgAsset(
          context,
          'assets/map_marker_group_suggestions.svg',
          shops.length,
          TextStyles.markerSuggestion);
    } else {
      return _bitmapDescriptorFromSvgAsset(
          context,
          'assets/map_marker_group_empty.svg',
          shops.length,
          TextStyles.markerEmpty);
    }
  }
}

final _imagePaint = Paint();
final _textPainter = TextPainter(textDirection: TextDirection.ltr);
final _assetsCache = <String, ui.Picture>{};
final _markersCache = <String, Map<int, BitmapDescriptor>>{};

/// Stolen from https://stackoverflow.com/a/57609840
Future<BitmapDescriptor> _bitmapDescriptorFromSvgAsset(BuildContext context,
    String assetName, int shops, TextStyle textStyle) async {
  if (shops > 99) {
    shops = 10; // In order for cache to work better
  }

  if (_markersCache[assetName]?[shops] != null) {
    return _markersCache[assetName]![shops]!;
  }

  final pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  // Marker image
  var size = 45.0; // SVG original size
  final queryData = MediaQuery.of(context);
  // toPicture() and toImage() don't seem to be pixel ratio aware,
  // so we calculate the actual sizes here
  final devicePixelRatio = queryData.devicePixelRatio;
  size = size * devicePixelRatio;
  final ui.Picture picture;
  if (_assetsCache.containsKey(assetName)) {
    picture = _assetsCache[assetName]!;
  } else {
    final svgString =
        await DefaultAssetBundle.of(context).loadString(assetName);
    final svgDrawableRoot = await svg.fromSvgString(svgString, '');

    picture = svgDrawableRoot.toPicture(size: Size(size, size));
    _assetsCache[assetName] = picture;
  }

  final image = await picture.toImage(size.round(), size.round());
  canvas.drawImage(image, Offset.zero, _imagePaint);

  // Text
  if (shops != 1) {
    final text = shops <= 9 ? '$shops' : '9+';
    _textPainter.text = TextSpan(
        text: text,
        style: textStyle.copyWith(
            fontSize: textStyle.fontSize! * devicePixelRatio));
    _textPainter.layout();
    // Magic numbers! Figured out manually, might be wrong
    final double xOffset;
    if (shops == 2) {
      xOffset = 21 * devicePixelRatio;
    } else if (shops == 4) {
      xOffset = 20.5 * devicePixelRatio;
    } else if (shops == 6) {
      xOffset = 20.75 * devicePixelRatio;
    } else if (shops == 8) {
      xOffset = 21 * devicePixelRatio;
    } else if (shops > 9) {
      xOffset = 21 * devicePixelRatio;
    } else {
      xOffset = 21.5 * devicePixelRatio;
    }

    final yOffset = 11.5 * devicePixelRatio;
    _textPainter.paint(
        canvas, Offset(xOffset - _textPainter.width / 2, yOffset));
  }

  final img =
      await pictureRecorder.endRecording().toImage(size.round(), size.round());
  final markerData = await img.toByteData(format: ui.ImageByteFormat.png);
  final result = BitmapDescriptor.fromBytes(markerData!.buffer.asUint8List());

  if (_markersCache[assetName] == null) {
    _markersCache[assetName] = {};
  }
  _markersCache[assetName]![shops] = result;
  return result;
}
