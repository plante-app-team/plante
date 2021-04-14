import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:fimber_io/fimber_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:untitled_vegan_app/base/pair.dart';

const LOGS_DIR_MAX_SIZE = 1024 * 1024 * 10;

class Log {
  static DebugTree? _debugTree;
  static TimedRollingFileTree? _fileTree;

  static void init({
      Directory? logsDir,
      int maxSizeBytes = LOGS_DIR_MAX_SIZE}) async {
    if (_debugTree != null) {
      Fimber.unplantTree(_debugTree!);
    }
    if (_fileTree != null) {
      Fimber.unplantTree(_fileTree!);
    }

    _debugTree = DebugTree();
    Fimber.plantTree(_debugTree!);

    if (logsDir == null) {
      logsDir = await logsDirectory();
    }
    _fileTree = TimedRollingFileTree(
        filenamePrefix: logsDir.absolute.path + "/log");
    Fimber.plantTree(_fileTree!);

    // NOTE: it's async but we don't wait for it
    maybeCleanUpLogs(logsDir, maxSizeBytes);
  }

  static Future<void> maybeCleanUpLogs(
      Directory logsDir, int maxSizeBytes) async {
    if (!(await logsDir.exists())) {
      return;
    }

    int totalSize = 0;
    final entries = await logsDir
        .list(recursive: true, followLinks: false)
        .toList();
    final files = entries
        .where((element) => element is File)
        .map((e) => e as File)
        .toList();

    final filesModified = <Pair<File, DateTime>>[];
    for (final file in files) {
      filesModified.add(Pair(file, await file.lastModified()));
    }
    // Newest first, oldest last
    filesModified.sort((a, b) =>
      b.second.millisecondsSinceEpoch - a.second.millisecondsSinceEpoch);
    for (final fileModified in filesModified) {
      final file = fileModified.first;
      totalSize += await file.length();
      if (maxSizeBytes < totalSize) {
        try {
          await file.delete();
        } catch (e) {
          Log.e("Couldn't delete file: ${file.path}", ex: e);
        }
      }
    }
  }

  static Future<Directory> logsDirectory() async {
    final internalStorage = await getApplicationDocumentsDirectory();
    return Directory(internalStorage.path + "/logs");
  }

  static void startLogsSending() async {
    final logsDir = await logsDirectory();
    final logsZip = File(logsDir.absolute.path + ".zip");
    if (await logsZip.exists()) {
      await logsZip.delete();
    }
    try {
      await ZipFile.createFromDirectory(
          sourceDir: logsDir, zipFile: logsZip, recurseSubDirs: true);
    } catch (e) {
      Log.e("Couldn't create a zip with logs", ex: e);
    }
    Share.shareFiles([logsZip.path]);
  }

  static void v(String message, {dynamic? ex, StackTrace? stacktrace}) {
    if (ex == null) {
      Fimber.v(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.v("message (ex: $ex)", ex: ex, stacktrace: stacktrace);
    }
  }

  static void d(String message, {dynamic? ex, StackTrace? stacktrace}) {
    if (ex == null) {
      Fimber.d(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.d("message (ex: $ex)", ex: ex, stacktrace: stacktrace);
    }
  }

  static void i(String message, {dynamic? ex, StackTrace? stacktrace}) {
    if (ex == null) {
      Fimber.i(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.i("message (ex: $ex)", ex: ex, stacktrace: stacktrace);
    }
  }

  static void w(String message, {dynamic? ex, StackTrace? stacktrace}) {
    if (ex == null) {
      Fimber.w(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.w("message (ex: $ex)", ex: ex, stacktrace: stacktrace);
    }
  }

  static void e(String message, {dynamic ex, StackTrace? stacktrace, bool crashAllowed = true}) {
    if (ex is FlutterError && ex.message.contains("RenderFlex")) {
      return;
    }
    if (ex == null) {
      Fimber.e(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.e("message (ex: $ex)", ex: ex, stacktrace: stacktrace);
    }
    if (crashAllowed && !kReleaseMode) {
      throw Exception(message);
    }
  }
}
