import 'dart:io';

bool isInTests() {
  return Platform.environment.containsKey('FLUTTER_TEST');
}
