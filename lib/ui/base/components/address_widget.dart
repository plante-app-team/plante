import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm_short_address.dart';
import 'package:plante/ui/base/components/gradient_spinner.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';

class AddressWidgetEntry {
  final FutureShortAddress address;
  final bool precise;
  AddressWidgetEntry({required this.address, required this.precise});
}

class AddressWidget extends StatefulWidget {
  final List<AddressWidgetEntry> prioritizedPossibleAddresses;
  final VoidCallback? loadCompletedCallback;

  const AddressWidget._(this.prioritizedPossibleAddresses,
      {this.loadCompletedCallback});

  factory AddressWidget.forFutureCoords(FutureShortAddress coordinatesAddress,
      {VoidCallback? loadCompletedCallback}) {
    final addresses = <AddressWidgetEntry>[];
    addresses
        .add(AddressWidgetEntry(address: coordinatesAddress, precise: false));
    return AddressWidget._(addresses,
        loadCompletedCallback: loadCompletedCallback);
  }

  factory AddressWidget.forShop(
      Shop shop, FutureShortAddress coordinatesAddress,
      {VoidCallback? loadCompletedCallback}) {
    final addresses = <AddressWidgetEntry>[];
    addresses.add(AddressWidgetEntry(
        address: Future.value(Ok(shop.address)), precise: true));
    addresses
        .add(AddressWidgetEntry(address: coordinatesAddress, precise: false));
    return AddressWidget._(addresses,
        loadCompletedCallback: loadCompletedCallback);
  }

  @override
  _AddressWidgetState createState() => _AddressWidgetState();

  static String? addressString(
      OsmShortAddress osmAddress, bool resultPrecise, BuildContext context) {
    return _AddressWidgetState.addressString(
        osmAddress, resultPrecise, context);
  }
}

class _AddressWidgetState extends State<AddressWidget> {
  late final List<AddressWidgetEntry> _prioritizedPossibleAddresses;
  ShortAddressResult? _loadedResult;
  bool _loadedResultPrecise = false;

  @override
  void initState() {
    super.initState();
    _prioritizedPossibleAddresses =
        widget.prioritizedPossibleAddresses.toList();
    _loadResult();
  }

  void _loadResult() async {
    while (_prioritizedPossibleAddresses.isNotEmpty) {
      final entry = _prioritizedPossibleAddresses.removeAt(0);
      final addressCandidate = await entry.address;
      if (addressCandidate.isOk && _addressNice(addressCandidate.unwrap())) {
        _loadResultCompleted(addressCandidate, entry.precise);
        return;
      }
      if (_prioritizedPossibleAddresses.isEmpty) {
        _loadResultCompleted(addressCandidate, entry.precise);
      }
    }
  }

  void _loadResultCompleted(ShortAddressResult? address, bool precise) {
    if (mounted) {
      setState(() {
        _loadedResult = address;
        _loadedResultPrecise = precise;
        _prioritizedPossibleAddresses.clear();
        widget.loadCompletedCallback?.call();
      });
    }
  }

  bool _addressNice(OsmShortAddress address) {
    return address.road != null;
  }

  @override
  void didUpdateWidget(AddressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadResult();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        duration: DURATION_DEFAULT,
        child: SizedBox(width: double.infinity, child: _buildContent(context)));
  }

  Widget _buildContent(BuildContext context) {
    if (_loadedResult?.isErr ?? false) {
      return const SizedBox.shrink();
    } else if (_loadedResult?.unwrap().isEmpty() ?? false) {
      // No address
      return const SizedBox.shrink();
    }

    final addressStr = _addressString(context);
    return RichText(
      text: TextSpan(
        style: TextStyles.hint,
        children: [
          WidgetSpan(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: SvgPicture.asset('assets/location.svg',
                    key: const Key('location_icon'))),
            const SizedBox(width: 6),
          ])),
          // An empty span in order for the RichText to be of the
          // proper size even before any text is shown.
          const TextSpan(text: ' '),
          if (addressStr != null)
            TextSpan(
              text: addressStr,
            ),
          if (addressStr == null)
            const WidgetSpan(
                child: SizedBox(
                    width: 200,
                    height: 14,
                    child: GradientSpinner(key: Key('address_placeholder'))))
        ],
      ),
    );
  }

  static String? addressString(
      OsmShortAddress osmAddress, bool resultPrecise, BuildContext context) {
    final String result;
    if (osmAddress.road != null) {
      result = [
        osmAddress.road ?? '',
        osmAddress.houseNumber ?? '',
      ].where((e) => e.isNotEmpty).join(', ');
    } else {
      result = [osmAddress.city ?? ''].where((e) => e.isNotEmpty).join(', ');
    }
    if (result.isNotEmpty) {
      if (resultPrecise) {
        return result;
      } else {
        return '${context.strings.shop_address_widget_possible_address}$result';
      }
    }
    return result.isNotEmpty ? result : null;
  }

  String? _addressString(BuildContext context) {
    if (_loadedResult == null) {
      return null;
    } else if (_loadedResult!.isErr) {
      Log.e('Handle outside');
      return null;
    }
    return addressString(
        _loadedResult!.unwrap(), _loadedResultPrecise, context);
  }
}

extension _OsmShortAddressExt on OsmShortAddress {
  bool isEmpty() {
    return (road ?? '').trim().isEmpty && (houseNumber ?? '').trim().isEmpty;
  }
}
