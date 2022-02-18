import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';

class AppVersionWidget extends StatefulWidget {
  const AppVersionWidget({Key? key}) : super(key: key);

  @override
  _AppVersionWidgetState createState() => _AppVersionWidgetState();
}

class _AppVersionWidgetState extends State<AppVersionWidget> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  void _initAsync() async {
    final packageInfo = await getPackageInfo();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final packageInfo = _packageInfo;
    if (packageInfo == null) {
      return const SizedBox();
    }
    return Center(
        child: Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: InkWell(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: packageInfo.asString()));
                  showSnackBar(
                      context.strings.global_copied_to_clipboard, context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(packageInfo.asString(),
                        style: TextStyles.hint)))));
  }
}

extension on PackageInfo {
  String asString() {
    return '$appName $version $buildNumber';
  }
}
