import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/barcode_utils.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/base/box_with_circle_cutout.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/animated_cross_fade_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/switch_plante.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/scan/barcode_scan_page_model.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart' as qr;

class BarcodeScanPage extends PagePlante {
  final Shop? addProductToShop;
  final _testingStorage = _TestingStorage();

  BarcodeScanPage({Key? key, this.addProductToShop}) : super(key: key);

  @override
  _BarcodeScanPageState createState() => _BarcodeScanPageState();

  void newScanDataForTesting(qr.Barcode barcode, {bool byCamera = true}) {
    if (!isInTests()) {
      throw Exception('newScanDataForTesting not in tests');
    }
    _testingStorage.newScanDataCallback!.call(Pair(barcode, byCamera));
  }
}

class _TestingStorage {
  ArgCallback<Pair<qr.Barcode, bool>>? newScanDataCallback;
}

class _BarcodeScanPageState extends PageStatePlante<BarcodeScanPage> {
  late final BarcodeScanPageModel _model;

  qr.QRViewController? _qrController;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  final _manualBarcodeTextController = TextEditingController();

  bool _flashOn = false;
  bool _showCameraInput = true;
  bool _wasCameraWidgetEverVisible = false;

  _BarcodeScanPageState() : super('BarcodeScanPage');

  @override
  void initState() {
    super.initState();
    widget._testingStorage.newScanDataCallback = (pair) {
      _onNewScanData(pair.first, byCamera: pair.second);
    };

    final stateChangeCallback = () {
      if (mounted) {
        setState(() {
          // Update!
        });
      }
    };
    _model = BarcodeScanPageModel(
        stateChangeCallback,
        () => widget,
        () => context,
        GetIt.I.get<ProductsObtainer>(),
        GetIt.I.get<ShopsManager>(),
        GetIt.I.get<PermissionsManager>(),
        GetIt.I.get<UserParamsController>(),
        GetIt.I.get<UserLangsManager>(),
        GetIt.I.get<ViewedProductsStorage>(),
        GetIt.I.get<Analytics>());
    _manualBarcodeTextController.addListener(() {
      _model.manualBarcodeChanged(_manualBarcodeTextController.text);
    });
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      _qrController?.pauseCamera();
    } else if (Platform.isIOS) {
      _qrController?.resumeCamera();
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _qrController?.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorsPlante.lightGrey,
        body: SafeArea(
            child: Stack(children: [
          Column(children: [
            HeaderPlante(
              color: ColorsPlante.lightGrey,
              title: SwitchPlante(
                key: const Key('input_mode_switch'),
                leftSelected: _showCameraInput,
                callback: _switchInputMode,
                leftSvgAsset: 'assets/barcode_scan_mode.svg',
                rightSvgAsset: 'assets/barcode_type_mode.svg',
                boxShadow: BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ),
              spacingBottom: 24,
              rightActionPadding: 12,
              rightAction: IconButton(
                  onPressed: _toggleFlash,
                  icon: SvgPicture.asset(_flashOn
                      ? 'assets/flash_enabled.svg'
                      : 'assets/flash_disabled.svg')),
            ),
            AnimatedCrossFadePlante(
                firstChild:
                    _boxWithCutout(context, color: ColorsPlante.lightGrey),
                secondChild: _manualInput(),
                crossFadeState: _showCameraInput
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond),
            Expanded(
                child: Stack(clipBehavior: Clip.none, children: [
              // Top: -2 is a part of a fix for https://github.com/flutter/flutter/issues/14288
              Positioned.fill(
                  top: -2, child: Container(color: ColorsPlante.lightGrey)),
            ])),
          ]),
          Align(alignment: Alignment.bottomCenter, child: _contentWidget()),
        ])));
  }

  Widget _qrWidget() {
    if (isInTests()) {
      return const SizedBox.shrink();
    }
    return VisibilityDetectorPlante(
      keyStr: 'barcode_scan_page_qr_widget_visibility',
      onVisibilityChanged: (visible, firstCall) {
        setState(() {
          // qr.QRView enables device's camera when it's created, and we
          // don't want it to do that, because BarcodeScanPage is more often
          // exists but hidden than exists and shown.
          // Enabling camera while the page is hidden will confuse users,
          // so we have to avoid it.
          _wasCameraWidgetEverVisible |= visible;
        });
        if (visible) {
          _qrController?.resumeCamera();
        } else {
          _qrController?.pauseCamera();
        }
      },
      child: _wasCameraWidgetEverVisible
          ? qr.QRView(key: _qrKey, onQRViewCreated: _onQRViewCreated)
          : const SizedBox(width: 10, height: 10),
    );
  }

  Widget _contentWidget() {
    return AnimatedSwitcher(
        duration: DURATION_DEFAULT,
        child: _model.contentState.buildWidget(context));
  }

  Widget _boxWithCutout(BuildContext context, {required Color color}) {
    final circleSize = _calculateCameraCircleSize();
    final Widget cameraWidget;
    if (isInTests()) {
      cameraWidget =
          _model.cameraAvailable ? _qrWidget() : Container(color: Colors.white);
    } else {
      cameraWidget = AnimatedSwitcher(
          duration: DURATION_DEFAULT,
          child: _model.cameraAvailable
              ? _qrWidget()
              : Container(color: Colors.white));
    }

    // Magic numbers are a part of a fix for https://github.com/flutter/flutter/issues/14288
    return Column(children: [
      SizedBox(
          width: double.infinity,
          child: Stack(children: [
            Positioned.fill(top: 1, child: cameraWidget),
            BoxWithCircleCutout(
              width: double.infinity,
              height: circleSize,
              cutoutPadding: 2,
              color: color,
            ),
          ])),
      SizedBox(
          width: double.infinity,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
                top: -2, child: Container(color: ColorsPlante.lightGrey)),
            Center(
                child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                        context
                            .strings.barcode_scan_page_point_camera_at_barcode,
                        textAlign: TextAlign.center,
                        style: TextStyles.normal))),
          ]))
    ]);
  }

  double _calculateCameraCircleSize() {
    final screenSizeTotal = MediaQuery.of(context).size;
    final screenSize = screenSizeTotal.width < screenSizeTotal.height
        ? screenSizeTotal.width
        : screenSizeTotal.height;
    const circleSizeRation = 0.62;
    final double circleSize;
    if (!isInTests()) {
      circleSize = screenSize * circleSizeRation;
    } else {
      circleSize = 120.0;
    }
    // Magic number is a part of a fix for https://github.com/flutter/flutter/issues/14288
    return circleSize + 4;
  }

  Widget _manualInput() {
    final onPressed = () {
      _onNewScanData(
          qr.Barcode(
              _manualBarcodeTextController.text, qr.BarcodeFormat.unknown, []),
          byCamera: false,
          forceSearch: true);
      FocusScope.of(context).unfocus();
    };
    final onDisabledPressed = () {
      if (!_model.searching) {
        showSnackBar(
            context.strings.barcode_scan_page_invalid_barcode, context);
      }
    };
    return SizedBox(
        height: _calculateCameraCircleSize(),
        child: Center(
            child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InputFieldPlante(
                          key: const Key('manual_barcode_input'),
                          controller: _manualBarcodeTextController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                          ],
                          label: context.strings.global_barcode,
                          hint: '4000417025005'),
                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          child: ButtonFilledPlante.withText(
                              context.strings.global_send,
                              onPressed: _model.isManualBarcodeValid() &&
                                      !_model.searching
                                  ? onPressed
                                  : null,
                              onDisabledPressed: onDisabledPressed)),
                      const SizedBox(height: 2),
                    ]))));
  }

  void _onQRViewCreated(qr.QRViewController controller) {
    setState(() {
      _qrController = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      _onNewScanData(scanData, byCamera: true);
    });
  }

  void _onNewScanData(qr.Barcode scanData,
      {required bool byCamera, bool forceSearch = false}) async {
    if (_model.barcode == scanData.code || !isBarcodeValid(scanData.code)) {
      if (!forceSearch) {
        return;
      }
    }
    if (byCamera) {
      analytics.sendEvent('barcode_scan', {'barcode': scanData.code});
    } else {
      analytics.sendEvent('barcode_manual', {'barcode': scanData.code});
    }
    // Note: no await because we don't care about result
    _sendProductScan(scanData);

    final searchResult = await _model.searchProduct(scanData.code);
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

  void _sendProductScan(qr.Barcode scanData) async {
    await GetIt.I.get<Backend>().sendProductScan(scanData.code);
  }

  void _toggleFlash() async {
    try {
      await _qrController?.toggleFlash();
      setState(() {
        _flashOn = !_flashOn;
      });
    } on qr.CameraException catch (e) {
      Log.w('QrScanPage._toggleFlash error', ex: e);
    }
  }

  void _switchInputMode(bool showCameraInput) {
    setState(() {
      _showCameraInput = showCameraInput;
    });
    _model.manualBarcodeInputShown = !_showCameraInput;
    FocusScope.of(context).unfocus();
  }
}
