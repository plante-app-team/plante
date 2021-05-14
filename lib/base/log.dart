import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:fimber_io/fimber_io.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:plante/base/pair.dart';

const LOGS_DIR_MAX_SIZE = 1024 * 1024 * 10;

class Log {
  static DebugTree? _debugTree;
  static TimedRollingFileTree? _fileTree;
  static _CrashlyticsFimberTree? _crashlyticsTree;

  static void init(
      {Directory? logsDir, int maxSizeBytes = LOGS_DIR_MAX_SIZE}) async {
    if (_debugTree != null) {
      Fimber.unplantTree(_debugTree!);
    }
    if (_fileTree != null) {
      Fimber.unplantTree(_fileTree!);
    }
    if (_crashlyticsTree != null) {
      Fimber.unplantTree(_crashlyticsTree!);
    }

    _debugTree = DebugTree();
    Fimber.plantTree(_debugTree!);

    logsDir ??= await logsDirectory();
    _fileTree =
        TimedRollingFileTree(filenamePrefix: '${logsDir.absolute.path}/log');
    Fimber.plantTree(_fileTree!);

    if (kReleaseMode) {
      _crashlyticsTree = _CrashlyticsFimberTree();
      Fimber.plantTree(_crashlyticsTree!);
    }

    // NOTE: it's async but we don't wait for it
    await maybeCleanUpLogs(logsDir, maxSizeBytes);
  }

  static Future<void> maybeCleanUpLogs(
      Directory logsDir, int maxSizeBytes) async {
    if (!(await logsDir.exists())) {
      return;
    }

    int totalSize = 0;
    final entries =
        await logsDir.list(recursive: true, followLinks: false).toList();
    final files = entries.whereType<File>().toList();

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
    return Directory('${internalStorage.path}/logs');
  }

  static void startLogsSending() async {
    final logsDir = await logsDirectory();
    final logsZip = File('${logsDir.absolute.path}.zip');
    if (await logsZip.exists()) {
      await logsZip.delete();
    }
    try {
      await ZipFile.createFromDirectory(
          sourceDir: logsDir, zipFile: logsZip, recurseSubDirs: true);
    } catch (e) {
      Log.e("Couldn't create a zip with logs", ex: e);
    }
    await Share.shareFiles([logsZip.path]);
  }

  static void v(String message, {dynamic? ex, StackTrace? stacktrace}) {
    if (ex == null) {
      Fimber.v(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.v('message (ex: $ex)', ex: ex, stacktrace: stacktrace);
    }
  }

  static void d(String message, {dynamic? ex, StackTrace? stacktrace}) {
    if (ex == null) {
      Fimber.d(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.d('message (ex: $ex)', ex: ex, stacktrace: stacktrace);
    }
  }

  static void i(String message, {dynamic? ex, StackTrace? stacktrace}) {
    if (ex == null) {
      Fimber.i(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.i('message (ex: $ex)', ex: ex, stacktrace: stacktrace);
    }
  }

  static void w(String message, {dynamic? ex, StackTrace? stacktrace}) {
    if (ex == null) {
      Fimber.w(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.w('message (ex: $ex)', ex: ex, stacktrace: stacktrace);
    }
  }

  static void e(String message,
      {dynamic ex,
      StackTrace? stacktrace,
      bool crashAllowed = true,
      bool crashlyticsAllowed = true}) {
    if (crashAllowed && !kReleaseMode) {
      throw Exception(message);
    }

    if (!crashlyticsAllowed && _crashlyticsTree != null) {
      Fimber.unplantTree(_crashlyticsTree!);
    }
    try {
      if (ex == null) {
        Fimber.e(message, ex: ex, stacktrace: stacktrace);
      } else {
        Fimber.e('message (ex: $ex)', ex: ex, stacktrace: stacktrace);
      }
    } finally {
      if (!crashlyticsAllowed && _crashlyticsTree != null) {
        Fimber.plantTree(_crashlyticsTree!);
      }
    }
  }
}

class _CrashlyticsFimberTree extends LogTree {
  @override
  List<String> getLevels() => ['D', 'I', 'W', 'E', 'V'];

  @override
  void log(String level, String message,
      {String? tag, dynamic ex, StackTrace? stacktrace}) {
    logImpl(level, message, tag: tag, ex: ex, stacktrace: stacktrace);
  }

  Future<void> logImpl(String level, String message,
      {String? tag, dynamic ex, StackTrace? stacktrace}) async {
    if (level == 'E') {
      await FirebaseCrashlytics.instance
          .recordError(ex, stacktrace, reason: message, fatal: false);
    } else {
      await FirebaseCrashlytics.instance.log('Msg: $message, ex: $ex');
    }
  }
}
