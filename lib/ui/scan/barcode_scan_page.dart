import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/base/box_with_circle_cutout.dart';
import 'package:plante/ui/base/components/animated_cross_fade_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/switch_plante.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/base/text_styles.dart';
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
  late final BarcodeScanPageModel _model;

  qr.QRViewController? _qrController;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  final _manualBarcodeTextController = TextEditingController();

  bool _flashOn = false;
  bool _showCameraInput = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

    final stateChangeCallback = () {
      if (mounted) {
        setState(() {
          // Update!
        });
      }
    };
    _model = BarcodeScanPageModel(
        stateChangeCallback,
        GetIt.I.get<ProductsManager>(),
        GetIt.I.get<LangCodeHolder>(),
        GetIt.I.get<PermissionsManager>(),
        GetIt.I.get<UserParamsController>());
    _manualBarcodeTextController.addListener(() {
      _model.manualBarcodeChanged(_manualBarcodeTextController.text);
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        await _qrController?.resumeCamera();
      }
    } else if (state == AppLifecycleState.paused) {
      await _qrController?.pauseCamera();
    }
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
      _qrController?.pauseCamera();
    } else if (Platform.isIOS) {
      _qrController?.resumeCamera();
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _qrController?.dispose();
    GetIt.I.get<RouteObserver<ModalRoute>>().unsubscribe(this);
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (ModalRoute.of(context)?.isCurrent == true) {
      _qrController?.resumeCamera();
    }
  }

  @override
  void didPushNext() {
    _qrController?.pauseCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: _BACKGROUND_COLOR,
        body: SafeArea(
            child: Stack(children: [
          Column(children: [
            HeaderPlante(
                color: _BACKGROUND_COLOR,
                title: SwitchPlante(
                  key: const Key('input_mode_switch'),
                  leftSelected: _showCameraInput,
                  callback: _switchInputMode,
                  leftSvgAsset: 'assets/barcode_scan_mode.svg',
                  rightSvgAsset: 'assets/barcode_type_mode.svg',
                ),
                spacingBottom: 24,
                leftActionPadding: 12,
                rightActionPadding: 12,
                leftAction: IconButton(
                    onPressed: _toggleFlash,
                    icon: SvgPicture.asset(_flashOn
                        ? 'assets/flash_enabled.svg'
                        : 'assets/flash_disabled.svg')),
                rightAction: IconButton(
                    onPressed: _openSettings,
                    icon: SvgPicture.asset('assets/settings.svg'))),
            AnimatedCrossFadePlante(
                firstChild: _boxWithCutout(context, color: _BACKGROUND_COLOR),
                secondChild: _manualInput(),
                crossFadeState: _showCameraInput
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond),
            Expanded(
                child: Stack(clipBehavior: Clip.none, children: [
              // Top: -2 is a part of a fix for https://github.com/flutter/flutter/issues/14288
              Positioned.fill(
                  top: -2, child: Container(color: _BACKGROUND_COLOR)),
              Container(
                width: double.infinity,
                color: _BACKGROUND_COLOR,
                child: Column(children: [
                  const SizedBox(height: 14),
                  Expanded(child: _contentWidget()),
                ]),
              ),
            ])),
          ]),
          SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                  duration: DURATION_DEFAULT,
                  child: _model.searching && !isInTests()
                      ? const LinearProgressIndicator()
                      : const SizedBox.shrink())),
        ])));
  }

  Widget _qrWidget() {
    if (isInTests()) {
      return const SizedBox.shrink();
    }
    return qr.QRView(key: _qrKey, onQRViewCreated: _onQRViewCreated);
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
                top: -2, child: Container(color: _BACKGROUND_COLOR)),
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
          forceSearch: true);
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
    controller.scannedDataStream.listen(_onNewScanData);
  }

  void _onNewScanData(qr.Barcode scanData, {bool forceSearch = false}) async {
    if (_model.barcode == scanData.code && !forceSearch) {
      return;
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

  void _openSettings() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }

  void _switchInputMode(bool showCameraInput) {
    setState(() {
      _showCameraInput = showCameraInput;
    });
    FocusScope.of(context).unfocus();
  }
}
