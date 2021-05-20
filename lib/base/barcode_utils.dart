final _notDigit = RegExp('[^0-9]');

// Stolen from https://stackoverflow.com/a/10143593
bool isBarcodeValid(String code) {
  if (code.contains(_notDigit)) {
    return false;
  }
  switch (code.length) {
    case 8:
      code = '000000$code';
      break;
    case 12:
      code = '00$code';
      break;
    case 13:
      code = '0$code';
      break;
    case 14:
      break;
    default:
      return false;
  }
  final a = List.generate(13, (index) => 0);
  a[0] = int.parse(code[0]) * 3;
  a[1] = int.parse(code[1]);
  a[2] = int.parse(code[2]) * 3;
  a[3] = int.parse(code[3]);
  a[4] = int.parse(code[4]) * 3;
  a[5] = int.parse(code[5]);
  a[6] = int.parse(code[6]) * 3;
  a[7] = int.parse(code[7]);
  a[8] = int.parse(code[8]) * 3;
  a[9] = int.parse(code[9]);
  a[10] = int.parse(code[10]) * 3;
  a[11] = int.parse(code[11]);
  a[12] = int.parse(code[12]) * 3;
  final sum = a.fold(0, (p, c) => (p! as int) + c);
  final check = (10 - (sum % 10)) % 10;
  final last = int.parse(code[13]);
  return check == last;
}
