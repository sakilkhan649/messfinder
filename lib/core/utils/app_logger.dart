import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void i(String message, {String tag = 'INFO'}) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$tag] $message');
      _logger.i('[$tag] $message');
    }
  }

  static void s(String message, {String tag = 'SUCCESS'}) {
    if (kDebugMode) {
      debugPrint('✅ [$tag] $message');
      _logger.i('[$tag] ✅ $message');
    }
  }

  static void w(String message, {String tag = 'WARNING'}) {
    if (kDebugMode) {
      debugPrint('⚠️ [$tag] $message');
      _logger.w('[$tag] $message');
    }
  }

  static void e(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    String tag = 'ERROR',
  ]) {
    if (kDebugMode) {
      debugPrint('❌ [$tag] $message');
      if (error != null) {
        debugPrint('   Error details: $error');
      }
      _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
    }
  }
}
