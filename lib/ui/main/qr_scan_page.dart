import 'dart:io';

import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

class QrScanPage extends StatefulWidget {
  @override
  _QrScanPageState createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

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
    super.dispose();
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
            child:  AnimatedContainer(
              duration: Duration(milliseconds: 250),
              width: MediaQuery.of(context).size.width,
              height: result != null ? 100 : 0,
              color: Colors.white,
              child: Center(
                child: Text(
                    context.strings.qr_scan_page_product_not_found,
                    style: TextStyle(fontSize: 20.0)),
              )
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  void _toggleFlash() async {
    try {
      await controller?.toggleFlash();
    } on CameraException {
      // TODO(https://trello.com/c/XWAE5UVB/): log warning
    }
  }
}
