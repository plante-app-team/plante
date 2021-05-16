import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/base/box_with_circle_cutout.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/scan/barcode_scan_page_model.dart';
import 'package:plante/ui/settings_page.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;
import 'package:plante/base/log.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/ui_utils.dart';

const _BACKGROUND_COLOR = Color(0xfff5f7fa);

// mutation is used for testing only
// ignore: must_be_immutable
class BarcodeScanPage extends StatefulWidget {
  _BarcodeScanPageState? _lastState;

  BarcodeScanPage({Key? key}) : super(key: key);

  @override
  _BarcodeScanPageState createState() {
    _lastState = _BarcodeScanPageState();
    return _lastState!;
  }

  void newScanDataForTesting(qr.Barcode barcode) {
    assert(isInTests());
    _lastState?._onNewScanData(barcode);
  }
}

class _BarcodeScanPageState extends State<BarcodeScanPage>
    with RouteAware, WidgetsBindingObserver {
  late final BarcodeScanPageModel model;

  String fakeScannedBarcode = '';

  qr.QRViewController? qrController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    updateFakeScannedBarcode();
    WidgetsBinding.instance!.addObserver(this);

    final stateChangeCallback = () {
      if (mounted) {
        setState(() {
          // Update!
        });
      }
    };
    model = BarcodeScanPageModel(
        stateChangeCallback,
        GetIt.I.get<ProductsManager>(),
        GetIt.I.get<LangCodeHolder>(),
        GetIt.I.get<PermissionsManager>(),
        GetIt.I.get<UserParamsController>());
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        await qrController?.resumeCamera();
      }
    } else if (state == AppLifecycleState.paused) {
      await qrController?.pauseCamera();
    }
  }

  void updateFakeScannedBarcode() async {
    final settings = GetIt.I.get<Settings>();
    final result = await settings.fakeScannedProductBarcode();
    setState(() {
      fakeScannedBarcode = result;
    });
  }

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
      qrController?.pauseCamera();
    } else if (Platform.isIOS) {
      qrController?.resumeCamera();
    }
  }

  @override
  void dispose() {
    model.dispose();
    qrController?.dispose();
    GetIt.I.get<RouteObserver<ModalRoute>>().unsubscribe(this);
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (ModalRoute.of(context)?.isCurrent == true) {
      qrController?.resumeCamera();
      updateFakeScannedBarcode();
    }
  }

  @override
  void didPushNext() {
    qrController?.pauseCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: _BACKGROUND_COLOR,
        body: SafeArea(
            child: Stack(children: [
          Column(children: [
            const HeaderPlante(color: _BACKGROUND_COLOR, spacingBottom: 24),
            boxWithCutout(context, color: _BACKGROUND_COLOR),
            Expanded(
                child: Stack(clipBehavior: Clip.none, children: [
              // Top: -2 is a part of a fix for https://github.com/flutter/flutter/issues/14288
              Positioned.fill(
                  top: -2, child: Container(color: _BACKGROUND_COLOR)),
              Container(
                width: double.infinity,
                color: _BACKGROUND_COLOR,
                child: Column(children: [
                  const SizedBox(height: 14), // DANIL
                  Expanded(child: contentWidget()),
                ]),
              ),
            ])),
          ]),
          Row(children: [
            Material(
                color: _BACKGROUND_COLOR,
                child: IconButton(
                    color: Colors.yellow,
                    icon: const Icon(Icons.flash_on),
                    onPressed: _toggleFlash)),
            if (fakeScannedBarcode.isNotEmpty)
              Material(
                  color: _BACKGROUND_COLOR,
                  child: IconButton(
                      color: Colors.grey,
                      icon: const Icon(Icons.tag_faces),
                      onPressed: () {
                        _onNewScanData(qr.Barcode(
                            fakeScannedBarcode, qr.BarcodeFormat.unknown, []));
                      })),
          ]),
          Align(
              alignment: Alignment.topRight,
              child: Material(
                  color: _BACKGROUND_COLOR,
                  child: IconButton(
                      color: Colors.grey,
                      icon: const Icon(Icons.settings),
                      onPressed: _openSettings))),
          SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: model.searching && !isInTests()
                      ? const LinearProgressIndicator()
                      : const SizedBox.shrink())),
        ])));
  }

  Widget qrWidget() {
    if (isInTests()) {
      return const SizedBox.shrink();
    }
    return qr.QRView(key: qrKey, onQRViewCreated: _onQRViewCreated);
  }

  Widget contentWidget() {
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: model.contentState.buildWidget(context));
  }

  Widget boxWithCutout(BuildContext context, {required Color color}) {
    final screenSizeTotal = MediaQuery.of(context).size;
    final screenSize = screenSizeTotal.width < screenSizeTotal.height
        ? screenSizeTotal.width
        : screenSizeTotal.height;
    const circleSizeRation = 0.62;
    final double circleSize;
    if (!isInTests()) {
      circleSize = screenSize * circleSizeRation;
    } else {
      circleSize = 60.0;
    }

    final Widget cameraWidget;
    if (isInTests()) {
      cameraWidget =
          model.cameraAvailable ? qrWidget() : Container(color: Colors.white);
    } else {
      cameraWidget = AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: model.cameraAvailable
              ? qrWidget()
              : Container(color: Colors.white));
    }

    // Magic numbers are a part of a fix for https://github.com/flutter/flutter/issues/14288
    return SizedBox(
        width: double.infinity,
        child: Stack(children: [
          Positioned.fill(top: 1, child: cameraWidget),
          BoxWithCircleCutout(
            width: double.infinity,
            height: circleSize + 4,
            cutoutPadding: 2,
            color: color,
          ),
        ]));
  }

  void _onQRViewCreated(qr.QRViewController controller) {
    setState(() {
      qrController = controller;
    });
    controller.scannedDataStream.listen(_onNewScanData);
  }

  void _onNewScanData(qr.Barcode scanData) async {
    if (model.barcode == scanData.code && scanData.code != fakeScannedBarcode) {
      return;
    }
    if (scanData.code != fakeScannedBarcode) {
      // Note: no await because we don't care about result
      sendProductScan(scanData);
    }

    final searchResult = await model.searchProduct(scanData.code);
    switch (searchResult) {
      case BarcodeScanPageSearchResult.OK:
        // Nice
        break;
      case BarcodeScanPageSearchResult.ERROR_NETWORK:
        showSnackBar(context.strings.global_network_error, context);
        break;
      case BarcodeScanPageSearchResult.ERROR_OTHER:
        showSnackBar(context.strings.global_something_went_wrong, context);
        break;
    }
  }

  void sendProductScan(qr.Barcode scanData) async {
    await GetIt.I.get<Backend>().sendProductScan(scanData.code);
  }

  void _toggleFlash() async {
    try {
      await qrController?.toggleFlash();
    } on qr.CameraException catch (e) {
      Log.w('QrScanPage._toggleFlash error', ex: e);
    }
  }

  void _openSettings() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }
}
