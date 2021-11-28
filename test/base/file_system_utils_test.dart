import 'dart:io';

import 'package:plante/base/base.dart';
import 'package:plante/base/file_system_utils.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {});

  Future<Directory> createDir() async {
    final rand = randInt(0, 999999);
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = Directory('/tmp/file_system_utils_test.$rand.$now');
    return await result.create();
  }

  test('maybeCleanUpOldestFiles: when everything is ok', () async {
    final dir = await createDir();
    final file1 = File('${dir.absolute.path}/file1.txt');
    await file1.writeAsString('hello there');
    final file2 = File('${dir.absolute.path}/file2.txt');
    await file2.writeAsString('general kenobi');

    await maybeCleanUpOldestFiles(
      dir: dir,
      maxDirSizeBytes: 1000,
      maxFileAgeMillis: 1000,
    );

    expect(await file1.exists(), isTrue);
    expect(await file1.readAsString(), equals('hello there'));
    expect(await file2.exists(), isTrue);
    expect(await file2.readAsString(), equals('general kenobi'));
  });

  String createContentForFile() {
    final buffer = StringBuffer();
    for (var index = 0; index < 1000; ++index) {
      buffer.write('a');
    }
    return buffer.toString();
  }

  test('maybeCleanUpOldestFiles: when folder too big', () async {
    final content = createContentForFile();

    final dir = await createDir();
    final file1 = File('${dir.absolute.path}/file1.txt');
    await file1.writeAsString(content);

    // Forcing one file to be older than another
    await Future.delayed(const Duration(seconds: 1));

    final file2 = File('${dir.absolute.path}/file2.txt');
    await file2.writeAsString(content);

    await maybeCleanUpOldestFiles(
      dir: dir,
      maxDirSizeBytes: content.length + 1,
    );

    expect(await file1.exists(), isFalse);
    expect(await file2.exists(), isTrue);
    expect(await file2.readAsString(), equals(content));
  });

  test('maybeCleanUpOldestFiles: when files too old', () async {
    final content = createContentForFile();

    final dir = await createDir();
    final file1 = File('${dir.absolute.path}/file1.txt');
    await file1.writeAsString(content);

    // Forcing one file to be older than another
    await Future.delayed(const Duration(seconds: 1));

    final file2 = File('${dir.absolute.path}/file2.txt');
    await file2.writeAsString(content);

    await maybeCleanUpOldestFiles(
      dir: dir,
      maxFileAgeMillis: 1000,
    );

    expect(await file1.exists(), isFalse);
    expect(await file2.exists(), isTrue);
    expect(await file2.readAsString(), equals(content));
  });
}
