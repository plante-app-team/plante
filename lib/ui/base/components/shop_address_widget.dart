import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/l10n/strings.dart';

class ShopAddressWidget extends StatefulWidget {
  final FutureAddress osmAddress;
  const ShopAddressWidget(this.osmAddress, {Key? key}) : super(key: key);

  @override
  _ShopAddressWidgetState createState() => _ShopAddressWidgetState();
}

class _ShopAddressWidgetState extends State<ShopAddressWidget>
    with SingleTickerProviderStateMixin {
  AddressResult? _loadedResult;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  void _loadResult() async {
    final address = await widget.osmAddress;
    if (mounted) {
      setState(() {
        _loadedResult = address;
      });
    }
  }

  @override
  void didUpdateWidget(ShopAddressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadResult();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        duration: DURATION_DEFAULT,
        vsync: this,
        child: SizedBox(width: double.infinity, child: _buildContent(context)));
  }

  Widget _buildContent(BuildContext context) {
    if (_loadedResult?.isErr ?? false) {
      return const SizedBox.shrink();
    } else if (_loadedResult?.unwrap().isEmpty() ?? false) {
      // No address
      return const SizedBox.shrink();
    }

    final addressStr = _addressString();
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
              text:
                  '${context.strings.shop_address_widget_possible_address}$addressStr',
            ),
          if (addressStr == null)
            WidgetSpan(
              child: Container(
                key: const Key('address_placeholder'),
                width: 100,
                height: 13,
                decoration: const BoxDecoration(
                  color: ColorsPlante.grey,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _addressString() {
    if (_loadedResult == null) {
      return null;
    } else if (_loadedResult!.isErr) {
      Log.e('Handle outside');
      return null;
    }
    final osmAddress = _loadedResult!.unwrap();
    final String result;
    if (osmAddress.road != null) {
      result = [
        osmAddress.cityDistrict ?? '',
        osmAddress.road ?? '',
        osmAddress.houseNumber ?? '',
      ].where((e) => e.isNotEmpty).join(', ');
    } else {
      result =
          [osmAddress.cityDistrict ?? ''].where((e) => e.isNotEmpty).join(', ');
    }
    return result.isNotEmpty ? result : null;
  }
}

extension _OsmAddressExt on OsmAddress {
  bool isEmpty() {
    return (cityDistrict ?? '').trim().isEmpty &&
        (road ?? '').trim().isEmpty &&
        (houseNumber ?? '').trim().isEmpty;
  }
}
