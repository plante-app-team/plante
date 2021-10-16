import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';

/// Wrapper for an operation, which:
/// - Has delayed execution: a [_fn] is passed to the constructor and
///   is called only when the [result] getter is invoked.
/// - Is not eager to start again: if [_fn] execution hasn't finished but
///   [result] is invoked again, [result] will wait for the still-execution
///   operation and will return its result. EVEN if it's
///   a failure.
/// - Must have its result memorized: if the operation is successful,
///   its result is memorized and instantly returned from [result].
/// - Is retryable: if previous execution ended up with a failure, next
///   invocation of [result] will retry the operation.
///
/// This class is good for network operations which you expect to return same
/// result on success (so it can be reused) and want to retry on failures,
/// but not eagerly.
// TODO: test throughout
class RetryableLazyOperation<T, E> {
  final ResCallback<Future<Result<T, E>>> _fn;
  Result<T, E>? _result;
  Completer<Result<T, E>>? _completer;

  RetryableLazyOperation(this._fn);

  Future<Result<T, E>> get result {
    if (_result != null) {
      // Result is already available!
      return Future.value(_result);
    }
    if (_completer != null) {
      // Operation is already being performed -
      // let's return its (future) result.
      return _completer!.future;
    }
    return _executeFn();
  }

  Future<Result<T, E>> _executeFn() {
    _completer = Completer<Result<T, E>>();
    _fn.call().then((result) {
      if (result.isOk) {
        // Success! Let's memorize the result.
        _result = result;
      }
      _completer!.complete(result);
      _completer = null;
    });
    return _completer!.future;
  }
}
