abstract class Result<OK, ERR> {
  bool get isOk => this is Ok;
  bool get isErr => !isOk;

  OK unwrap() {
    if (isOk) {
      return (this as Ok)._value;
    }
    throw AssertionError("Result is not OK: $this");
  }

  ERR unwrapErr() {
    if (isErr) {
      return (this as Err)._value;
    }
    throw AssertionError("Result is not ERR: $this");
  }

  OK? maybeOk() {
    if (isOk) {
      return (this as Ok)._value;
    }
    return null;
  }

  ERR? maybeErr() {
    if (isErr) {
      return (this as Err)._value;
    }
    return null;
  }
}

class Ok<OK, ERR> extends Result<OK, ERR> {
  final OK _value;
  Ok(this._value);

  @override
  bool operator ==(that) => that is Ok && that._value == _value;

  @override
  int get hashCode => _value.hashCode;
}

class Err<OK, ERR> extends Result<OK, ERR> {
  final ERR _value;
  ERR get value => _value;
  Err(this._value);

  @override
  bool operator ==(that) => that is Err && that._value == _value;

  @override
  int get hashCode => _value.hashCode;
}

class None {
}
