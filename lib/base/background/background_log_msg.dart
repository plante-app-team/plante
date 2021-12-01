import 'package:plante/logging/log_level.dart';

class BackgroundLogMsg {
  final LogLevel logLevel;
  final String msg;
  final String? exceptionMsg;
  BackgroundLogMsg(this.logLevel, this.msg, this.exceptionMsg);
}

typedef BackgroundLog = void Function(LogLevel logLevel, String msg,
    {String? exceptionMsg});
