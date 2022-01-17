import 'package:flutter/material.dart';
import 'package:plante/ui/base/page_state_plante.dart';

class ProfilePage extends PagePlante {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends PageStatePlante<ProfilePage> {
  _ProfilePageState() : super('ProfilePage');

  @override
  Widget buildPage(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Hello there')),
    );
  }
}
