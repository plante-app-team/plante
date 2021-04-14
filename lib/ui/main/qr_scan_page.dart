import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;
import 'package:untitled_vegan_app/base/log.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/outside/products/products_manager.dart';
import 'package:untitled_vegan_app/outside/products/products_manager_error.dart';
import 'package:untitled_vegan_app/ui/base/ui_utils.dart';
import 'package:untitled_vegan_app/ui/product/product_page_wrapper.dart';

class QrScanPage extends StatefulWidget {
  @override
  _QrScanPageState createState() => _QrScanPageState();
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
    GetIt.I.get<RouteObserver<ModalRoute>>()
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
    GetIt.I.get<RouteObserver<ModalRoute>>()
        .unsubscribe(this);
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
      body: Stack(
        children: <Widget>[
          _buildQrView(context),
          Container(
            margin: EdgeInsets.only(top: 20),
            child: ElevatedButton(
                onPressed: _toggleFlash,
                child: Text(context.strings.qr_scan_page_btn_flash)),
          ),
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: InkWell(child: AnimatedContainer(
              duration: Duration(milliseconds: 250),
              width: MediaQuery.of(context).size.width,
              height: _barcode != null ? 100 : 0,
              color: Colors.white,
              child:
                Row(children: [
                  SizedBox(width: 10),
                  if (_searching) CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Expanded(child:
                  Text(
                      _productName(),
                      style: TextStyle(fontSize: 20.0)))
                ])
              ),
              onTap: _tryOpenProductPage,
            ),
          )
        ],
      ),
    );
  }

  String _productName() {
    if (_searching && _barcode != null) {
      return _barcode!.code;
    }

    if (_foundProduct != null) {
      if (_foundProduct!.name != null) {
        return _foundProduct!.name!;
      } else {
        return context.strings.qr_scan_page_product_without_name;
      }
    }

    return context.strings.qr_scan_page_product_not_found;
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return qr.QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: qr.QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
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
    setState(() {
      _barcode = scanData;
      _searching = true;
    });

    final foundProductResult = await GetIt.I.get<ProductsManager>().getProduct(
        scanData.code,
        Localizations.localeOf(context).languageCode);
    if (foundProductResult.isErr) {
      if (foundProductResult.unwrapErr() == ProductsManagerError.NETWORK_ERROR) {
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
      MaterialPageRoute(builder: (context) =>
          ProductPageWrapper(product, productUpdatedCallback: (product) {
            setState(() {
              _foundProduct = product;
            });
      })),
    );
  }
}
