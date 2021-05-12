import 'dart:io';

import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/base/box_with_circle_cutout.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/settings_page.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;
import 'package:plante/base/log.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/ui_utils.dart';

import 'barcode_scan_page_model.dart';

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

  String fakeScannedBarcode = "";

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
        this.qrController?.resumeCamera();
      }
    } else if (state == AppLifecycleState.paused) {
      qrController?.pauseCamera();
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
      this.qrController?.resumeCamera();
      updateFakeScannedBarcode();
    }
  }

  @override
  void didPushNext() {
    this.qrController?.pauseCamera();
  }

  @override
  Widget build(BuildContext context) {
    GetIt.I.get<LangCodeHolder>().langCode =
        Localizations.localeOf(context).languageCode;
    return Scaffold(
        body: SafeArea(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            child:
                // ColumnSuper is used for innerDistance
                // Inner distance is needed to fix https://github.com/flutter/flutter/issues/14288
                ColumnSuper(innerDistance: -2, children: [
              HeaderPlante(color: _BACKGROUND_COLOR, spacingBottom: 25),
              boxWithCutout(context, color: _BACKGROUND_COLOR),
              Container(
                padding: EdgeInsets.only(left: 24, right: 24),
                width: double.infinity,
                color: _BACKGROUND_COLOR,
                child: Column(children: [
                  SizedBox(height: 18),
                  contentWidget(),
                  // ColumnSuper doesn't support Expanded, but we need white
                  // color to fill everything
                  SizedBox(height: 10000)
                ]),
              )
            ]),
          ),
          Row(children: [
            Material(
                color: _BACKGROUND_COLOR,
                child: IconButton(
                    color: Colors.yellow,
                    icon: Icon(Icons.flash_on),
                    onPressed: _toggleFlash)),
            if (fakeScannedBarcode.isNotEmpty)
              Material(
                  color: _BACKGROUND_COLOR,
                  child: IconButton(
                      color: Colors.grey,
                      icon: Icon(Icons.tag_faces),
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
                      icon: Icon(Icons.settings),
                      onPressed: _openSettings))),
          Container(
              width: double.infinity,
              child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: model.searching && !isInTests()
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

  Widget contentWidget() {
    final state = model.contentState;
    final widget = Container(
        key: Key(state.id),
        height: 1000, // To fix animation jerk
        child: state.buildWidget(context));
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

    final cameraWidget;
    if (isInTests()) {
      cameraWidget =
          model.cameraAvailable ? qrWidget() : Container(color: Colors.white);
    } else {
      cameraWidget = AnimatedSwitcher(
          duration: Duration(milliseconds: 250),
          child: model.cameraAvailable
              ? qrWidget()
              : Container(color: Colors.white));
    }

    return Container(
        width: double.infinity,
        padding: EdgeInsets.only(top: 1, bottom: 1),
        child: ColumnSuper(invert: true, innerDistance: -1, children: [
          Container(color: color, height: 2),
          Stack(children: [
            Positioned.fill(child: cameraWidget),
            BoxWithCircleCutout(
              width: double.infinity,
              // +4 and 2 are to fix https://github.com/flutter/flutter/issues/14288
              height: circleSize + 4,
              cutoutPadding: 2,
              color: color,
            ),
          ]),
        ]));
  }

  void _onQRViewCreated(qr.QRViewController controller) {
    setState(() {
      this.qrController = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      _onNewScanData(scanData);
    });
  }

  void _onNewScanData(qr.Barcode scanData) async {
    if (model.barcode == scanData.code) {
      return;
    }
    if (scanData.code != fakeScannedBarcode) {
      // Note: no await because we don't care about result
      GetIt.I.get<Backend>().sendProductScan(scanData.code);
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

  void _toggleFlash() async {
    try {
      await qrController?.toggleFlash();
    } on qr.CameraException catch (e) {
      Log.w("QrScanPage._toggleFlash error", ex: e);
    }
  }

  void _openSettings() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }
}
