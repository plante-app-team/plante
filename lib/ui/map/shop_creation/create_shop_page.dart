import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/ui/base/components/address_widget.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/dropdown_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/linear_progress_indicator_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';

class CreateShopPage extends PagePlante {
  final Coord shopCoord;
  const CreateShopPage({Key? key, required this.shopCoord}) : super(key: key);
  @override
  _CreateShopPageState createState() => _CreateShopPageState();
}

class _CreateShopPageState extends PageStatePlante<CreateShopPage> {
  final ShopsManager _shopsManager;
  final AddressObtainer _addressObtainer;
  final _textController = TextEditingController();
  late final _shopType = UIValue<ShopType?>(null, ref);
  late final _loading = UIValue(false, ref);

  _CreateShopPageState()
      : _shopsManager = GetIt.I.get<ShopsManager>(),
        _addressObtainer = GetIt.I.get<AddressObtainer>(),
        super('CreateShopPage');

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        // Update!
      });
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 31),
      Padding(
          padding: const EdgeInsets.only(left: 32, right: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              const FabPlante.closeBtnPopOnClick(key: Key('cancel')),
              Expanded(
                  child: Column(
                      textDirection: TextDirection.ltr,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                    const SizedBox(height: 13),
                    SizedBox(
                        width: double.infinity,
                        child: Text(
                            context.strings
                                .create_shop_page_how_new_shop_is_called,
                            style: TextStyles.headline4)),
                    const SizedBox(height: 4),
                    AddressWidget.forFutureCoords(_addressObtainer
                        .shortAddressOfCoords(widget.shopCoord)),
                  ]))
            ],
          )),
      const SizedBox(height: 24),
      Padding(
        padding: const EdgeInsets.only(left: 26, right: 26),
        child: InputFieldPlante(
          key: const Key('new_shop_name_input'),
          label: context.strings.create_shop_page_how_new_shop_is_called_label,
          hint: context.strings.create_shop_page_how_new_shop_is_called_hint,
          controller: _textController,
        ),
      ),
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.only(left: 32, right: 32),
        child: Text(context.strings.create_shop_page_what_type_new_shop_has,
            style: TextStyles.headline4),
      ),
      const SizedBox(height: 24),
      Padding(
          padding: const EdgeInsets.only(left: 26, right: 26),
          child: SizedBox(
              width: double.infinity,
              child: consumer((ref) => DropdownPlante<ShopType>(
                    key: const Key('shop_type_dropdown'),
                    value: _shopType.watch(ref),
                    values: ShopType.valuesOrderedForUI,
                    onChanged: _shopType.setValue,
                    dropdownItemBuilder: (shopType) =>
                        DropdownMenuItem<ShopType>(
                      value: shopType,
                      child: Text(shopType.localize(context)),
                    ),
                  )))),
      Expanded(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, bottom: 24),
                      child: consumer((ref) {
                        final shopType = _shopType.watch(ref);
                        final loading = _loading.watch(ref);
                        return ButtonFilledPlante.withText(
                            context.strings.global_done,
                            onPressed: !loading && _isInputOk(shopType)
                                ? _onAddPressed
                                : null);
                      }))))),
    ]);
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Stack(children: [
          content,
          consumer((ref) => _loading.watch(ref)
              ? const LinearProgressIndicatorPlante()
              : const SizedBox()),
        ])));
  }

  bool _isInputOk(ShopType? shopType) {
    return _textController.text.trim().length >= 3 && shopType != null;
  }

  void _onAddPressed() async {
    try {
      _loading.setValue(true);
      final result = await _shopsManager.createShop(
        name: _textController.text.trim(),
        type: _shopType.cachedVal!,
        coord: widget.shopCoord,
      );
      if (result.isOk) {
        showSnackBar(context.strings.map_page_shop_added_to_map, context,
            SnackBarStyle.MAP_ACTION_DONE);
        Navigator.of(context).pop(result.unwrap());
      } else {
        if (result.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
          showSnackBar(context.strings.global_network_error, context);
        } else {
          showSnackBar(context.strings.global_something_went_wrong, context);
        }
      }
    } finally {
      _loading.setValue(false);
    }
  }
}
