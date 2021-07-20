import 'package:flutter/cupertino.dart';

abstract class Result<OK, ERR> {
  bool get isOk => this is Ok;
  bool get isErr => !isOk;

  OK unwrap() {
    if (isOk) {
      return (this as Ok)._value as OK;
    }
    throw AssertionError('Result is not OK: $this');
  }

  ERR unwrapErr() {
    if (isErr) {
      return (this as Err)._value as ERR;
    }
    throw AssertionError('Result is not ERR: $this');
  }

  OK? maybeOk() {
    if (isOk) {
      return (this as Ok)._value as OK?;
    }
    return null;
  }

  ERR? maybeErr() {
    if (isErr) {
      return (this as Err)._value as ERR?;
    }
    return null;
  }
}

@immutable
class Ok<OK, ERR> extends Result<OK, ERR> {
  final OK _value;
  Ok(this._value);

  @override
  bool operator ==(other) => other is Ok && other._value == _value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value.toString();
}

@immutable
class Err<OK, ERR> extends Result<OK, ERR> {
  final ERR _value;
  ERR get value => _value;
  Err(this._value);

  @override
  bool operator ==(other) => other is Err && other._value == _value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => _value.toString();
}

class None {}
