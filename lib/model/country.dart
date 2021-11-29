import 'package:flutter/cupertino.dart';

typedef Localize<String> = String? Function(BuildContext context);

@immutable
class Country {
  final String iso2Code;
  final Localize<String> localize;
  final List<String> languages;

  const Country(
      {required this.iso2Code,
      required this.localize,
      required this.languages});
}
