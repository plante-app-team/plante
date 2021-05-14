import 'dart:io';

import 'package:test/test.dart';
import 'package:plante/base/log.dart';

void main() {
  setUp(() {
  });

  test('extra logs files properly deleted', () async {
    final rand = DateTime.now().millisecondsSinceEpoch;
    final logsDir = Directory('/tmp/testinglogs$rand');
    logsDir.createSync();

    final file1 = File('${logsDir.path}/${rand}1');
    final file2 = File('${logsDir.path}/${rand}2');
    final file3 = File('${logsDir.path}/${rand}3');

    file1.writeAsStringSync('0123456789');
    sleep(const Duration(seconds: 1));
    file2.writeAsStringSync('0123456789');
    sleep(const Duration(seconds: 1));
    file3.writeAsStringSync('0123456789');

    await Log.maybeCleanUpLogs(logsDir, 25);

    expect(file3.existsSync(), isTrue);
    expect(file2.existsSync(), isTrue);
    expect(file1.existsSync(), isFalse);
  });
}
