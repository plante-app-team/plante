import 'dart:io';

import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/box_with_circle_cutout.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/settings_page.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;
import 'package:plante/base/log.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

// mutation is used for testing only
// ignore: must_be_immutable
class QrScanPage extends StatefulWidget {
  _QrScanPageState? _lastState;

  QrScanPage({Key? key}) : super(key: key);

  @override
  _QrScanPageState createState() {
    _lastState = _QrScanPageState();
    return _lastState!;
  }

  void newScanDataForTesting(qr.Barcode barcode) {
    assert(isInTests());
    _lastState?._onNewScanData(barcode);
  }
}

class _QrScanPageState extends State<QrScanPage> with RouteAware {
  qr.Barcode? _barcode;
  bool _searching = false;
  Product? _foundProduct;

  qr.QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    GetIt.I
        .get<RouteObserver<ModalRoute>>()
        .subscribe(this, ModalRoute.of(context)!);
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    GetIt.I.get<RouteObserver<ModalRoute>>().unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (ModalRoute.of(context)?.isActive == true) {
      this.controller?.resumeCamera();
    }
  }

  @override
  void didPushNext() {
    this.controller?.pauseCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Stack(
        children: [
          qrWidget(),
          Container(
            width: double.infinity,
            child:
                // ColumnSuper is used for innerDistance
                // Inner distance is needed to fix https://github.com/flutter/flutter/issues/14288
                ColumnSuper(innerDistance: -1, children: [
              Container(
                padding: EdgeInsets.only(left: 24, right: 24),
                width: double.infinity,
                color: Colors.white,
                child: Column(children: [
                  SizedBox(height: 55),
                  Text(
                    context.strings.global_app_name,
                    style: TextStyles.branding,
                  ),
                  SizedBox(height: 36),
                ]),
              ),
              boxWithCutout(context, color: Colors.white),
              Container(
                padding: EdgeInsets.only(left: 24, right: 24),
                width: double.infinity,
                color: Colors.white,
                child: Column(children: [
                  SizedBox(height: 18),
                  displayedProductWidget(),
                  // ColumnSuper doesn't support Expanded, but we need white
                  // color to fill everything
                  SizedBox(height: 10000)
                ]),
              )
            ]),
          ),
          Material(
              color: Colors.white,
              child: IconButton(
                  color: Colors.yellow,
                  icon: Icon(Icons.flash_on),
                  onPressed: _toggleFlash)),
          Align(
              alignment: Alignment.topRight,
              child: Material(
                  color: Colors.white,
                  child: IconButton(
                      color: Colors.grey,
                      icon: Icon(Icons.settings),
                      onPressed: _openSettings))),
          Container(
              width: double.infinity,
              child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: _searching && !isInTests()
                      ? LinearProgressIndicator()
                      : SizedBox.shrink())),
        ],
      ),
    ));
  }

  Widget qrWidget() {
    if (isInTests()) {
      return SizedBox.shrink();
    }
    return qr.QRView(key: qrKey, onQRViewCreated: _onQRViewCreated);
  }

  Widget displayedProductWidget() {
    final widget;
    if (_barcode == null) {
      widget = Container(
          key: Key("product_description1"),
          height: 1000, // To fix animation jerk
          child: Column(children: [
            Text(context.strings.qr_scan_page_point_camera_at_barcode,
                textAlign: TextAlign.center, style: TextStyles.normal)
          ]));
    } else if (_searching && _barcode != null) {
      widget = Container(
          key: Key("product_description2"),
          height: 1000, // To fix animation jerk
          child: Column(children: [
            Text(
                "${context.strings.qr_scan_page_searching_product} ${_barcode!.code}",
                textAlign: TextAlign.center,
                style: TextStyles.normal)
          ]));
    } else if (_foundProduct != null &&
        ProductPageWrapper.isProductFilledEnoughForDisplay(_foundProduct!)) {
      widget = Container(
          key: Key("product_description3"),
          height: 1000, // To fix animation jerk
          child: Column(children: [
            Text(_foundProduct!.name!,
                textAlign: TextAlign.center, style: TextStyles.headline2),
            SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: ButtonFilledPlante.withText(
                    context.strings.qr_scan_page_show_product,
                    onPressed: _tryOpenProductPage)),
          ]));
    } else {
      widget = Container(
          key: Key("product_description4"),
          height: 1000, // To fix animation jerk
          child: Column(children: [
            Text(context.strings.qr_scan_page_product_not_found,
                textAlign: TextAlign.center, style: TextStyles.headline2),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ButtonFilledPlante.withText(
                  context.strings.qr_scan_page_add_product,
                  onPressed: _tryOpenProductPage),
            ),
          ]));
    }

    return AnimatedContainer(
        duration: Duration(milliseconds: 250),
        child: AnimatedSwitcher(
            duration: Duration(milliseconds: 250), child: widget));
  }

  Widget boxWithCutout(BuildContext context, {required Color color}) {
    final screenSizeTotal = MediaQuery.of(context).size;
    final screenSize = screenSizeTotal.width < screenSizeTotal.height
        ? screenSizeTotal.width
        : screenSizeTotal.height;
    final circleSizeRation = 0.62;
    final circleSize;
    if (!isInTests()) {
      circleSize = screenSize * circleSizeRation;
    } else {
      circleSize = 60.0;
    }

    return Container(
      width: double.infinity,
      child: BoxWithCircleCutout(
        width: double.infinity,
        // +4 and 2 are to fix https://github.com/flutter/flutter/issues/14288
        height: circleSize + 4,
        cutoutPadding: 2,
        color: color,
      ),
    );
  }

  void _onQRViewCreated(qr.QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      _onNewScanData(scanData);
    });
  }

  void _onNewScanData(qr.Barcode scanData) async {
    if (_barcode?.code == scanData.code) {
      return;
    }

    // Note: no await because we don't care about result
    GetIt.I.get<Backend>().sendProductScan(scanData.code);

    setState(() {
      _barcode = scanData;
      _searching = true;
    });

    final foundProductResult = await GetIt.I.get<ProductsManager>().getProduct(
        scanData.code, Localizations.localeOf(context).languageCode);
    if (foundProductResult.isErr) {
      if (foundProductResult.unwrapErr() ==
          ProductsManagerError.NETWORK_ERROR) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
    }
    final foundProduct = foundProductResult.maybeOk();
    setState(() {
      _foundProduct = foundProduct;
      _searching = false;
      _barcode = foundProductResult.isOk ? _barcode : null;
    });
  }

  void _toggleFlash() async {
    try {
      await controller?.toggleFlash();
    } on qr.CameraException catch (e) {
      Log.w("QrScanPage._toggleFlash error", ex: e);
    }
  }

  void _tryOpenProductPage() {
    if (_searching || _barcode == null) {
      return;
    }
    final Product product;
    if (_foundProduct != null) {
      product = _foundProduct!;
    } else {
      product = Product((v) => v.barcode = _barcode!.code);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              ProductPageWrapper(product, productUpdatedCallback: (product) {
                setState(() {
                  _foundProduct = product;
                });
              })),
    );
  }

  void _openSettings() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }
}
