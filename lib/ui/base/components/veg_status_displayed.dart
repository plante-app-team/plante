import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class VegStatusDisplayed extends StatelessWidget {
  final String? helpText;
  final VoidCallback? onHelpClick;
  final Product product;
  final UserParams user;
  final VoidCallback? onVegStatusClick;

  const VegStatusDisplayed(
      {Key? key,
      required this.product,
      required this.user,
      this.helpText,
      this.onHelpClick,
      this.onVegStatusClick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
          onTap: onVegStatusClick,
          child: Row(children: [
            _vegStatusImage(),
            const SizedBox(width: 6),
            Flexible(
              fit: FlexFit.tight,
              child: Text(_vegStatusText(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.normalSmall.copyWith(
                      color: _vegStatusColor(),
                      decoration: onVegStatusClick != null
                          ? TextDecoration.underline
                          : null)),
            ),
            if (helpText != null)
              Wrap(children: [
                _HelpButton(text: helpText!, onPressed: onHelpClick)
              ])
          ])),
      const SizedBox(height: 6),
      Row(children: [
        _vegStatusSourceImage(),
        const SizedBox(width: 6),
        Flexible(
            child: Text(
          _vegStatusSourceText(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.normalSmall,
        ))
      ])
    ]);
  }

  VegStatus _vegStatus() {
    return product.veganStatus ?? VegStatus.unknown;
  }

  VegStatusSource _vegStatusSource() {
    final result = product.veganStatusSource ?? VegStatusSource.unknown;
    if (result == VegStatusSource.unknown) {
      Log.w(
          'Unknown veg status source for barcode ${product.barcode}, $product');
    }
    return result;
  }

  Widget _vegStatusImage() {
    switch (_vegStatus()) {
      case VegStatus.positive:
        return SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset('assets/veg_status_vegan.svg'));
      case VegStatus.negative:
        return SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset('assets/veg_status_negative.svg'));
      case VegStatus.possible: // Fallthrough
      case VegStatus.unknown:
        return SizedBox(
            width: 18,
            height: 18,
            child: Image.asset('assets/veg_status_unknown.png'));
      default:
        throw Exception('Unknown veg status: ${_vegStatus()}');
    }
  }

  String _vegStatusText(BuildContext context) {
    switch (_vegStatus()) {
      case VegStatus.positive:
        return context.strings.veg_status_displayed_vegan;
      case VegStatus.negative:
        return context.strings.veg_status_displayed_not_vegan;
      case VegStatus.possible:
        return context.strings.veg_status_displayed_vegan_status_possible;
      case VegStatus.unknown:
        return context.strings.veg_status_displayed_vegan_status_unknown;
      default:
        throw Exception('Unknown veg status: ${_vegStatus()}');
    }
  }

  Color _vegStatusColor() {
    switch (_vegStatus()) {
      case VegStatus.positive:
        return ColorsPlante.primary;
      case VegStatus.negative:
        return ColorsPlante.red;
      case VegStatus.possible:
        return ColorsPlante.mainTextBlack;
      case VegStatus.unknown:
        return ColorsPlante.mainTextBlack;
      default:
        throw Exception('Unknown veg status: ${_vegStatus()}');
    }
  }

  Widget _vegStatusSourceImage() {
    switch (_vegStatusSource()) {
      case VegStatusSource.open_food_facts:
        return SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset('assets/veg_status_source_auto.svg'));
      case VegStatusSource.community:
        return SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset('assets/veg_status_source_community.svg'));
      case VegStatusSource.moderator:
        return SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset('assets/veg_status_source_moderator.svg'));
      case VegStatusSource.unknown:
        return SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset('assets/veg_status_source_unknown.svg'));
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

class _HelpButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const _HelpButton({Key? key, required this.text, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 28,
        child: OutlinedButton(
            style: ButtonStyle(
                side: MaterialStateProperty.all<BorderSide>(
                    const BorderSide(style: BorderStyle.none)),
                overlayColor:
                    MaterialStateProperty.all(ColorsPlante.primaryDisabled),
                backgroundColor:
                    MaterialStateProperty.all(const Color(0xFFEBEFEC)),
                padding: MaterialStateProperty.all(
                    const EdgeInsets.only(left: 8, right: 8)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)))),
            onPressed: onPressed,
            child:
                Center(child: Text(text, style: TextStyles.smallBoldGreen))));
  }
}
