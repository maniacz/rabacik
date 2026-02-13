import 'logger.dart';
import 'dart:developer' as developer;

class LocalLogger implements Logger {
  @override
  void log(String message, {Object? error, StackTrace? stackTrace}) {
    final logMessage = '[LOG] $message';
    if (error != null) {
      developer.log(logMessage, error: error, stackTrace: stackTrace);
    } else {
      developer.log(logMessage);
    }
  }
}
