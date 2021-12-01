import 'dart:async';

import 'package:plante/base/background/background_log_msg.dart';
import 'package:plante/base/background/background_worker.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/logging/log_level.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {});

  test('background execution', () async {
    final worker = await _TestedBackgroundWorker.create();
    expect(await worker.addValue(1), equals(1));
    expect(await worker.addValue(10), equals(11));
    expect(await worker.addValue(-20), equals(-9));
    worker.dispose();
  });

  test('background execution throws', () async {
    final worker = await _TestedBackgroundWorker.create();
    expect(await worker.addValue(1), equals(1));
    String? excMsgFromBack;
    try {
      await worker.throwInBackground(Exception('hello there'));
    } catch (e) {
      excMsgFromBack = e.toString();
    }
    expect(excMsgFromBack, contains('hello there'));
    expect(await worker.addValue(-20), equals(-19));
    worker.dispose();
  });

  test('background execution logs', () async {
    final logsInterceptor = _LogsInterceptor();
    Log.addInterceptor(logsInterceptor);
    final worker = await _TestedBackgroundWorker.create();

    expect(await worker.addValue(1), equals(1));
    expect(logsInterceptor.logged, isEmpty);

    await worker.log('hello there');
    expect(logsInterceptor.logged, equals(['hello there']));

    Log.removeInterceptor(logsInterceptor);
    worker.dispose();
  });

  test('background execution after disposing', () async {
    final worker = await _TestedBackgroundWorker.create();
    expect(await worker.addValue(1), equals(1));
    worker.dispose();

    var timeout = false;
    try {
      await worker.addValue(2).timeout(const Duration(milliseconds: 3));
    } on TimeoutException {
      timeout = true;
    }
    expect(timeout, isTrue);
  });
}

class _SomeState {
  var value = 0;
}

class _TestedBackgroundWorker extends BackgroundWorker<_SomeState> {
  _TestedBackgroundWorker._()
      : super('_TestedBackgroundWorker', _backgroundWork);

  static Future<_TestedBackgroundWorker> create() async {
    final result = _TestedBackgroundWorker._();
    await result.init(_SomeState());
    return result;
  }

  Future<int> addValue(int addedValue) async {
    final result = communicate(addedValue);
    return await result.first as int;
  }

  Future<void> throwInBackground(Exception ex) async {
    final result = communicate(ex);
    await result.first;
  }

  Future<void> log(String msg) async {
    final result = communicate(msg);
    await result.first;
  }

  static dynamic _backgroundWork(
      dynamic payload, _SomeState backgroundState, BackgroundLog log) {
    if (payload is Exception) {
      throw payload;
    }
    if (payload is String) {
      log(LogLevel.INFO, payload);
      return;
    }
    final addedValue = payload as int;
    backgroundState.value += addedValue;
    return backgroundState.value;
  }
}

class _LogsInterceptor implements LogsInterceptor {
  final logged = <String>[];
  @override
  void onLog(LogLevel level, String msg, ex, StackTrace? stacktrace) {
    logged.add(msg);
  }
}
