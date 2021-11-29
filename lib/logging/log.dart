import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:fimber_io/fimber_io.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/file_system_utils.dart';
import 'package:plante/logging/log_level.dart';
import 'package:share/share.dart';

const LOGS_DIR_MAX_SIZE = 1024 * 1024 * 10;

@visibleForTesting
abstract class LogsInterceptor {
  void onLog(LogLevel level, String msg, dynamic ex, StackTrace? stacktrace);
}

class Log {
  static DebugTree? _debugTree;
  static TimedRollingFileTree? _fileTree;
  static _CrashlyticsFimberTree? _crashlyticsTree;

  static final _interceptors = <LogsInterceptor>[];

  @visibleForTesting
  static void addInterceptor(LogsInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  @visibleForTesting
  static void removeInterceptor(LogsInterceptor interceptor) {
    _interceptors.remove(interceptor);
  }

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

    _crashlyticsTree = _CrashlyticsFimberTree();
    Fimber.plantTree(_crashlyticsTree!);

    await maybeCleanUpLogs(logsDir, maxSizeBytes);
  }

  static Future<void> maybeCleanUpLogs(
      Directory logsDir, int maxSizeBytes) async {
    return await maybeCleanUpOldestFiles(
        dir: logsDir, maxDirSizeBytes: maxSizeBytes);
  }

  static Future<Directory> logsDirectory() async {
    final internalStorage = await getAppDir();
    return Directory('${internalStorage.path}/logs');
  }

  static void startLogsSending() async {
    final logsDir = await logsDirectory();
    if (!(await logsDir.exists())) {
      return;
    }
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

  static void custom(LogLevel level, String message,
      {dynamic ex, StackTrace? stacktrace}) {
    switch (level) {
      case LogLevel.DEBUG:
        d(message, ex: ex, stacktrace: stacktrace);
        break;
      case LogLevel.VERBOSE:
        v(message, ex: ex, stacktrace: stacktrace);
        break;
      case LogLevel.INFO:
        i(message, ex: ex, stacktrace: stacktrace);
        break;
      case LogLevel.WARNING:
        w(message, ex: ex, stacktrace: stacktrace);
        break;
      case LogLevel.ERROR:
        e(message, ex: ex, stacktrace: stacktrace);
        break;
    }
  }

  static void v(String message, {dynamic ex, StackTrace? stacktrace}) {
    _intercept(LogLevel.VERBOSE, message, ex, stacktrace);
    if (ex == null) {
      Fimber.v(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.v('$message (ex: $ex)', ex: ex, stacktrace: stacktrace);
    }
  }

  static void _intercept(
      LogLevel level, String message, dynamic ex, StackTrace? stacktrace) {
    _interceptors.forEach((e) => e.onLog(level, message, ex, stacktrace));
  }

  static void d(String message, {dynamic ex, StackTrace? stacktrace}) {
    _intercept(LogLevel.DEBUG, message, ex, stacktrace);
    if (ex == null) {
      Fimber.d(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.d('$message (ex: $ex)', ex: ex, stacktrace: stacktrace);
    }
  }

  static void i(String message, {dynamic ex, StackTrace? stacktrace}) {
    _intercept(LogLevel.INFO, message, ex, stacktrace);
    if (ex == null) {
      Fimber.i(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.i('$message (ex: $ex)', ex: ex, stacktrace: stacktrace);
    }
  }

  static void w(String message, {dynamic ex, StackTrace? stacktrace}) {
    _intercept(LogLevel.WARNING, message, ex, stacktrace);
    if (ex == null) {
      Fimber.w(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.w('$message (ex: $ex)', ex: ex, stacktrace: stacktrace);
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

    _intercept(LogLevel.ERROR, message, ex, stacktrace);
    if (ex == null) {
      Fimber.e(message, ex: ex, stacktrace: stacktrace);
    } else {
      Fimber.e('$message (ex: $ex)', ex: ex, stacktrace: stacktrace);
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
    tag ??= '??';
    final msg = '$level $tag, msg: $message, ex: $ex, stack: $stacktrace';
    await FirebaseCrashlytics.instance.log(msg);
  }
}
