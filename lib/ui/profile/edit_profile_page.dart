import 'package:flutter/widgets.dart';
import 'package:plante/ui/base/page_state_plante.dart';

class EditProfilePage extends PagePlante {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends PageStatePlante<EditProfilePage> {
  _EditProfilePageState() : super('EditProfilePage');

  @override
  Widget buildPage(BuildContext context) {
    return Container();
  }
}
