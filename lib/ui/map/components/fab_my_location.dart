import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';

class FabMyLocation extends ConsumerStatefulWidget {
  final ArgCallback<Coord>? onTapResult;
  final ResCallback<Future<Coord?>> userCoord;
  const FabMyLocation(
      {Key? key, required this.onTapResult, required this.userCoord})
      : super(key: key);

  @override
  _FabMyLocationState createState() => _FabMyLocationState();
}

class _FabMyLocationState extends ConsumerState<FabMyLocation> {
  late final _loading = UIValue(false, ref);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'my_location',
      onPressed: widget.onTapResult != null ? _onPressed : null,
      backgroundColor: Colors.white,
      splashColor: ColorsPlante.primaryDisabled,
      child: SizedBox(
          width: 30,
          height: 30,
          child: consumer((ref) => _loading.watch(ref)
              ? const CircularProgressIndicatorPlante()
              : SvgPicture.asset('assets/my_location.svg'))),
    );
  }

  void _onPressed() async {
    _loading.setValue(true);
    try {
      final position = await widget.userCoord.call();
      if (position == null) {
        return;
      }
      widget.onTapResult?.call(position);
    } finally {
      _loading.setValue(false);
    }
  }
}
