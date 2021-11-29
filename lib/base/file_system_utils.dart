import 'dart:io';

import 'package:plante/base/pair.dart';
import 'package:plante/logging/log.dart';

Future<void> maybeCleanUpOldestFiles(
    {required Directory dir,
    int? maxDirSizeBytes,
    int? maxFileAgeMillis}) async {
  if (!(await dir.exists())) {
    return;
  }

  final entries = await dir.list(recursive: true, followLinks: false).toList();
  final files = entries.whereType<File>().toList();

  final now = DateTime.now();
  final filesModified = <Pair<File, DateTime>>[];
  for (final file in files) {
    final lastModified = await file.lastModified();
    final age =
        now.millisecondsSinceEpoch - lastModified.millisecondsSinceEpoch;
    if (maxFileAgeMillis != null && maxFileAgeMillis < age) {
      await _delete(file);
    } else {
      filesModified.add(Pair(file, lastModified));
    }
  }

  // Newest first, oldest last
  filesModified.sort((a, b) =>
      b.second.millisecondsSinceEpoch - a.second.millisecondsSinceEpoch);
  int totalSize = 0;
  for (final fileModified in filesModified) {
    final file = fileModified.first;
    totalSize += await file.length();
    if (maxDirSizeBytes != null && maxDirSizeBytes < totalSize) {
      await _delete(file);
    }
  }
}

Future<void> _delete(File file) async {
  try {
    await file.delete();
  } catch (e) {
    Log.e("maybeCleanUpOldestFiles: couldn't delete file: ${file.path}", ex: e);
  }
}
