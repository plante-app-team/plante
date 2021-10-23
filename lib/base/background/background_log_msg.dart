import 'package:plante/logging/log_level.dart';

class BackgroundLogMsg {
  final LogLevel logLevel;
  final String msg;
  final dynamic exception;
  BackgroundLogMsg(this.logLevel, this.msg, this.exception);
}

typedef BackgroundLog = void Function(LogLevel logLevel, String msg,
    {dynamic ex});
