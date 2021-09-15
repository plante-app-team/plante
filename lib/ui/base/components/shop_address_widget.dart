import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm_short_address.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/l10n/strings.dart';

class ShopAddressWidget extends StatefulWidget {
  final Shop? shop;
  final FutureShortAddress osmAddress;
  const ShopAddressWidget(this.shop, this.osmAddress, {Key? key})
      : super(key: key);

  @override
  _ShopAddressWidgetState createState() => _ShopAddressWidgetState();
}

class _ShopAddressWidgetState extends State<ShopAddressWidget>
    with SingleTickerProviderStateMixin {
  ShortAddressResult? _loadedResult;

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

  String? _addressString(BuildContext context) {
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
        osmAddress.road ?? '',
        osmAddress.houseNumber ?? '',
      ].where((e) => e.isNotEmpty).join(', ');
    } else {
      result = [osmAddress.city ?? ''].where((e) => e.isNotEmpty).join(', ');
    }
    if (result.isNotEmpty) {
      if (osmAddress == widget.shop?.address) {
        // Address is precise because it's a part of the shop
        return result;
      } else {
        return '${context.strings.shop_address_widget_possible_address}$result';
      }
    }
    return result.isNotEmpty ? result : null;
  }
}

extension _OsmShortAddressExt on OsmShortAddress {
  bool isEmpty() {
    return (road ?? '').trim().isEmpty && (houseNumber ?? '').trim().isEmpty;
  }
}
