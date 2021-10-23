import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:plante/base/background/background_log_msg.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/logging/log_level.dart';

typedef BackgroundWorkerFn<BS> = dynamic Function(
    dynamic payload, BS backgroundState, BackgroundLog log);

/// BS stands for Background State
abstract class BackgroundWorker<BS> {
  final String _name;
  final BackgroundWorkerFn<BS> _backgroundWorkFn;
  late final SendPort _backgroundPort;
  late final Isolate _backgroundIsolate;

  BackgroundWorker(this._name, this._backgroundWorkFn);

  @protected
  Future<void> init(BS initialState) async {
    final initFrontPort = ReceivePort();
    final logsFrontPort = ReceivePort();
    _backgroundIsolate = await Isolate.spawn(
      _spinBackgroundWork,
      _DataFromFront(_name, initFrontPort.sendPort, logsFrontPort.sendPort,
          initialState, _backgroundWorkFn),
    );
    _backgroundPort = await initFrontPort.first as SendPort;
    logsFrontPort.listen((message) {
      try {
        final msgObj = message as BackgroundLogMsg;
        Log.custom(msgObj.logLevel, msgObj.msg, ex: msgObj.exception);
      } catch (e) {
        Log.e('Background $_name sent unacceptable msg: $message', ex: e);
      }
    });
  }

  void dispose() {
    _backgroundIsolate.kill(priority: Isolate.immediate);
  }

  /// Stream will either content either what the [_backgroundWorkFn] function
  /// returns OR what it throws (if it throws).
  @protected
  Stream<dynamic> communicate(dynamic payload) {
    final port = ReceivePort();
    _backgroundPort.send(_CrossIsolatesMessage(
      port.sendPort,
      payload,
    ));
    return port;
  }

  static void _spinBackgroundWork(_DataFromFront dataFromFront) async {
    final port = ReceivePort();
    final name = dataFromFront.name;
    final backgroundState = dataFromFront.initialState;
    final fn = dataFromFront.backgroundWorkFn;
    final log = (LogLevel logLevel, String msg, {dynamic ex}) {
      dataFromFront.logsFrontPort.send(BackgroundLogMsg(logLevel, msg, ex));
    };

    // Let's inform the caller about how to communicate with us...
    dataFromFront.initFrontPort.send(port.sendPort);
    // ...and listen to its messages.
    port.listen((dynamic message) {
      final incomingMsg = message as _CrossIsolatesMessage;
      var exceptionCaught = false;
      dynamic response;
      try {
        response = fn.call(incomingMsg.payload, backgroundState, log);
      } catch (e) {
        exceptionCaught = true;
        log(LogLevel.WARNING, '$name: backgroundWorkFn threw', ex: e);
        incomingMsg.sender.send(e);
      }
      if (!exceptionCaught) {
        incomingMsg.sender.send(response);
      }
    });
  }
}

/// NOTE: the [initialState] and [backgroundWorkFn] should not be
/// dynamic, they should have specific type with a generic type argument,
/// but that cannot be done because [Isolate.spawn] accepts a static
/// function without any generic types attached to it.
/// Because of that, generic types cannot be attached to [initialState] and
/// [backgroundWorkFn], and they have to be dynamic in order for the
/// code to not throw exceptions.
class _DataFromFront {
  final String name;
  final SendPort initFrontPort;
  final SendPort logsFrontPort;
  final dynamic initialState;
  final dynamic backgroundWorkFn;
  _DataFromFront(this.name, this.initFrontPort, this.logsFrontPort,
      this.initialState, this.backgroundWorkFn);
}

class _CrossIsolatesMessage {
  final SendPort sender;
  final dynamic payload;
  _CrossIsolatesMessage(
    this.sender,
    this.payload,
  );
}
