import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';

class AvatarWidget extends ConsumerStatefulWidget {
  final Uri? uri;
  final Future<Map<String, String>> authHeaders;
  final VoidCallback? onChangeClick;
  const AvatarWidget(
      {Key? key,
      required this.uri,
      required this.authHeaders,
      this.onChangeClick})
      : super(key: key);

  @override
  _AvatarWidgetState createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends ConsumerState<AvatarWidget> {
  late final UIValue<Map<String, String>?> _authHeaders;

  @override
  void initState() {
    super.initState();
    _authHeaders = UIValue(null, ref);
    _initAsync();
  }

  void _initAsync() async {
    _authHeaders.setValue(await widget.authHeaders);
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initAsync();
  }

  @override
  Widget build(BuildContext context) {
    final headers = _authHeaders.watch(ref);
    final Widget image;
    if (widget.uri != null) {
      if (headers == null) {
        image = Center(
            child: !isInTests()
                ? const CircularProgressIndicator()
                : const SizedBox.shrink());
      } else {
        image = UriImagePlante(widget.uri!, httpHeaders: headers);
      }
    } else {
      image = Container(color: const Color(0xFFC0C0C0));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Stack(children: [
        AnimatedSwitcher(duration: DURATION_DEFAULT, child: image),
        if (widget.onChangeClick != null)
          Material(
              key: const Key('change_avatar_button'),
              color: const Color(0x4E979A9C),
              child: InkWell(
                  onTap: widget.onChangeClick,
                  splashColor: ColorsPlante.splashColor,
                  borderRadius: BorderRadius.circular(100),
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SvgPicture.asset('assets/add_photo.svg',
                              color: Colors.white))))),
      ]),
    );
  }
}
