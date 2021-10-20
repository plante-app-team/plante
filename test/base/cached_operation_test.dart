import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/cached_operation.dart';
import 'package:plante/base/result.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {});

  test('operation is delayed', () async {
    var executionsCount = 0;
    final op = () {
      executionsCount += 1;
    };
    final cachedOp = CachedOperation(_convertOkToOp(op));

    await Future.delayed(const Duration(milliseconds: 1));
    expect(executionsCount, equals(0));

    await cachedOp.result;
    expect(executionsCount, equals(1));
  });

  test('operation does not start again if succeeded', () async {
    var executionsCount = 0;
    final op = () {
      return ++executionsCount;
    };
    final cachedOp = CachedOperation(_convertOkToOp(op));

    // Executions count is always 1 because first execution was successful.
    await cachedOp.result;
    expect(executionsCount, equals(1));
    await cachedOp.result;
    expect(executionsCount, equals(1));

    // Even though [executionsCount] should be increasing each time [op]
    // is called, we still expect it to be equal to [1] because the operation is
    // expected to be executed only once
    expect(await cachedOp.result, equals(Ok(1)));
  });

  test('operation can be repeated on failures', () async {
    var executionsCount = 0;
    final op = () {
      return ++executionsCount;
    };
    final cachedOp = CachedOperation(_convertErrToOp(op));

    // Executions count changes each time [result] is called
    // because it always fails.
    await cachedOp.result;
    expect(executionsCount, equals(1));
    await cachedOp.result;
    expect(executionsCount, equals(2));

    // [executionsCount] is increasing each time [op] is called,
    // so we expect the final result to be 3 because [result] is called for
    // the third time.
    expect(await cachedOp.result, equals(Err(3)));
  });

  test('operation does not start again if already being executed', () async {
    var executionsCount = 0;
    final completer = Completer<Result<None, int>>();
    final ResCallback<Future<Result<None, int>>> op = () {
      executionsCount += 1;
      return completer.future;
    };
    final cachedOp = CachedOperation(op);

    // Executions count is always 1 because first execution is still execution
    // (it's in Completer).
    unawaited(cachedOp.result);
    await Future.delayed(const Duration(milliseconds: 1));
    unawaited(cachedOp.result);
    await Future.delayed(const Duration(milliseconds: 1));
    expect(executionsCount, equals(1));

    completer.complete(Err(123));
    await Future.delayed(const Duration(milliseconds: 1));

    // Now we expect executions count to grow since the
    // completer is complete and all further [result] calls are instant.
    unawaited(cachedOp.result);
    await Future.delayed(const Duration(milliseconds: 1));
    unawaited(cachedOp.result);
    await Future.delayed(const Duration(milliseconds: 1));
    expect(executionsCount, equals(3));
  });
}

ResCallback<Future<Result<T, None>>> _convertOkToOp<T>(
    ResCallback<T> callback) {
  return () async {
    return Ok(callback.call());
  };
}

ResCallback<Future<Result<None, E>>> _convertErrToOp<E>(
    ResCallback<E> callback) {
  return () async {
    return Err(callback.call());
  };
}
