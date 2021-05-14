import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/veg_status_source.dart';

class VegStatusDisplayed extends StatelessWidget {
  final Product product;
  final UserParams user;

  const VegStatusDisplayed(
      {Key? key, required this.product, required this.user})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _vegStatusImage(),
        const SizedBox(width: 6),
        Flexible(
            child: Text(_vegStatusText(context),
                maxLines: 1, overflow: TextOverflow.ellipsis))
      ]),
      const SizedBox(height: 4),
      Row(children: [
        _vegStatusSourceImage(),
        const SizedBox(width: 6),
        Flexible(
            child: Text(_vegStatusSourceText(context),
                maxLines: 1, overflow: TextOverflow.ellipsis))
      ])
    ]);
  }

  VegStatus _vegStatus() {
    if (_isUserVegan()) {
      return product.veganStatus ?? VegStatus.unknown;
    } else {
      return product.vegetarianStatus ?? VegStatus.unknown;
    }
  }

  VegStatusSource _vegStatusSource() {
    final VegStatusSource result;
    if (_isUserVegan()) {
      result = product.veganStatusSource ?? VegStatusSource.unknown;
    } else {
      result = product.vegetarianStatusSource ?? VegStatusSource.unknown;
    }
    if (result == VegStatusSource.unknown) {
      Log.e(
          'Unknown veg status source for barcode ${product.barcode}, $product');
    }
    return result;
  }

  Widget _vegStatusImage() {
    switch (_vegStatus()) {
      case VegStatus.positive:
        if (_isUserVegan()) {
          return SvgPicture.asset('assets/veg_status_vegan.svg');
        } else {
          return SvgPicture.asset('assets/veg_status_vegetarian.svg');
        }
      case VegStatus.negative:
        return SvgPicture.asset('assets/veg_status_negative.svg');
      case VegStatus.possible: // Fallthrough
      case VegStatus.unknown:
        return SvgPicture.asset('assets/veg_status_unknown.svg');
      default:
        throw Exception('Unknown veg status: ${_vegStatus()}');
    }
  }

  bool _isUserVegan() => user.eatsVeggiesOnly ?? true;

  String _vegStatusText(BuildContext context) {
    if (_isUserVegan()) {
      switch (_vegStatus()) {
        case VegStatus.positive:
          return context.strings.veg_status_displayed_vegan;
        case VegStatus.negative:
          return context.strings.veg_status_displayed_not_vegan;
        case VegStatus.possible: // Fallthrough
        case VegStatus.unknown:
          return context.strings.veg_status_displayed_vegan_status_unknown;
        default:
          throw Exception('Unknown veg status: ${_vegStatus()}');
      }
    } else {
      switch (_vegStatus()) {
        case VegStatus.positive:
          return context.strings.veg_status_displayed_vegetarian;
        case VegStatus.negative:
          return context.strings.veg_status_displayed_not_vegetarian;
        case VegStatus.possible: // Fallthrough
        case VegStatus.unknown:
          return context.strings.veg_status_displayed_vegetarian_status_unknown;
        default:
          throw Exception('Unknown veg status: ${_vegStatus()}');
      }
    }
  }

  Widget _vegStatusSourceImage() {
    switch (_vegStatusSource()) {
      case VegStatusSource.open_food_facts:
        return SvgPicture.asset('assets/veg_status_source_auto.svg');
      case VegStatusSource.community:
        return SvgPicture.asset('assets/veg_status_source_community.svg');
      case VegStatusSource.moderator:
        return SvgPicture.asset('assets/veg_status_source_moderator.svg');
      case VegStatusSource.unknown:
        return SvgPicture.asset('assets/veg_status_source_unknown.svg');
      default:
        throw Exception('Unknown veg status source: ${_vegStatusSource()}');
    }
  }

  String _vegStatusSourceText(BuildContext context) {
    switch (_vegStatusSource()) {
      case VegStatusSource.open_food_facts:
        return context.strings.veg_status_displayed_veg_status_source_off;
      case VegStatusSource.community:
        return context.strings.veg_status_displayed_veg_status_source_community;
      case VegStatusSource.moderator:
        return context.strings.veg_status_displayed_veg_status_source_moderator;
      case VegStatusSource.unknown:
        return context.strings.veg_status_displayed_veg_status_source_unknown;
      default:
        throw Exception('Unknown veg status source: ${_vegStatusSource()}');
    }
  }
}
