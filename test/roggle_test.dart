// ignore: lines_longer_than_80_chars
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'dart:math';

import 'package:roggle/roggle.dart';
import 'package:test/test.dart';

import 'test_utils/utils.dart';

typedef PrinterCallback = List<String> Function(
  Level level,
  dynamic message,
  dynamic error,
  StackTrace? stackTrace,
);

class _AlwaysFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _NeverFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

class _CallbackPrinter extends LogPrinter {
  _CallbackPrinter(this.callback);

  final PrinterCallback callback;

  @override
  List<String> log(LogEvent event) {
    return callback(
      event.level,
      event.message,
      event.error,
      event.stackTrace,
    );
  }
}

void main() {
  Level? printedLevel;
  dynamic printedMessage;
  dynamic printedError;
  StackTrace? printedStackTrace;
  final callbackPrinter = _CallbackPrinter((l, dynamic m, dynamic e, s) {
    printedLevel = l;
    printedMessage = m;
    printedError = e;
    printedStackTrace = s;
    return [];
  });

  setUp(() {
    printedLevel = null;
    printedMessage = null;
    printedError = null;
    printedStackTrace = null;
  });

  group('Constructor', () {
    test('default', () {
      Roggle().d('some message');
    });
    test('filter', () {
      Roggle(filter: _NeverFilter(), printer: callbackPrinter)
          .log(Level.debug, 'Some message');

      expect(printedMessage, null);
    });
  });

  group('factory Roggle.crashlytics()', () {
    test('default', () {
      Roggle.crashlytics(
        printer: CrashlyticsPrinter(
          errorLevel: Level.off,
          onError: (_) {},
        ),
      ).d('some message');
    });
  });

  test('Roggle.log', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);

    final levels = getAvailableLogLevel();
    for (final level in levels) {
      var message = Random().nextInt(999999999).toString();
      logger.log(level, message);
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, null);
      expect(printedStackTrace, null);

      logger.log(level, null);
      expect(printedLevel, level);
      expect(printedMessage, null);
      expect(printedError, null);
      expect(printedStackTrace, null);

      message = Random().nextInt(999999999).toString();
      logger.log(level, message, 'MyError');
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, 'MyError');
      expect(printedStackTrace, null);

      message = Random().nextInt(999999999).toString();
      final stackTrace = StackTrace.current;
      logger.log(level, message, 'MyError', stackTrace);
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, 'MyError');
      expect(printedStackTrace, stackTrace);
    }

    expect(
      () => logger.log(Level.trace, 'Test', StackTrace.current),
      throwsArgumentError,
    );
    expect(() => logger.log(Level.off, 'Test'), throwsArgumentError);
    expect(() => logger.log(Level.all, 'Test'), throwsArgumentError);

    logger.close();
    expect(() => logger.log(Level.trace, 'Test'), throwsArgumentError);

    // Execute close() twice
    logger.close();
    expect(() => logger.log(Level.trace, 'Test'), throwsArgumentError);
  });

  test('Roggle.v', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);
    final stackTrace = StackTrace.current;
    logger.v('Test', 'Error', stackTrace);
    expect(printedLevel, Level.verbose);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);

    logger.v(null);
    expect(printedLevel, Level.verbose);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Roggle.t', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);
    final stackTrace = StackTrace.current;
    logger.t('Test', 'Error', stackTrace);
    expect(printedLevel, Level.trace);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);

    logger.t(null);
    expect(printedLevel, Level.trace);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Roggle.d', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);
    final stackTrace = StackTrace.current;
    logger.d('Test', 'Error', stackTrace);
    expect(printedLevel, Level.debug);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);

    logger.d(null);
    expect(printedLevel, Level.debug);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Roggle.i', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);
    final stackTrace = StackTrace.current;
    logger.i('Test', 'Error', stackTrace);
    expect(printedLevel, Level.info);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);

    logger.i(null);
    expect(printedLevel, Level.info);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Roggle.w', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);
    final stackTrace = StackTrace.current;
    logger.w('Test', 'Error', stackTrace);
    expect(printedLevel, Level.warning);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);

    logger.w(null);
    expect(printedLevel, Level.warning);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Roggle.e', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);
    final stackTrace = StackTrace.current;
    logger.e('Test', 'Error', stackTrace);
    expect(printedLevel, Level.error);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);

    logger.e(null);
    expect(printedLevel, Level.error);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Roggle.wtf', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);
    final stackTrace = StackTrace.current;
    logger.wtf('Test', 'Error', stackTrace);
    expect(printedLevel, Level.wtf);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);

    logger.wtf(null);
    expect(printedLevel, Level.wtf);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Roggle.f', () {
    final logger = Roggle(filter: _AlwaysFilter(), printer: callbackPrinter);
    final stackTrace = StackTrace.current;
    logger.f('Test', 'Error', stackTrace);
    expect(printedLevel, Level.fatal);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);

    logger.f(null);
    expect(printedLevel, Level.fatal);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('setting log level above log level of message', () {
    printedMessage = null;
    final logger = Roggle(
      filter: ProductionFilter(),
      printer: callbackPrinter,
      level: Level.warning,
    )..d('This isn\'t logged');
    expect(printedMessage, isNull);

    logger.w('This is');
    expect(printedMessage, 'This is');
  });

  test('setting static log level above log level of message', () {
    printedMessage = null;
    Roggle.level = Level.warning;
    final logger = Roggle(
      filter: ProductionFilter(),
      printer: callbackPrinter,
    )..d('This isn\'t logged');
    expect(printedMessage, isNull);

    logger.w('This is');
    expect(printedMessage, 'This is');

    Roggle.level = Level.trace;
  });

  test('get filter', () {
    final filter = ProductionFilter();
    final logger = Roggle(
      filter: filter,
    );
    expect(logger.filter.hashCode, filter.hashCode);
  });

  test('get printer', () {
    final printer = SinglePrettyPrinter();
    final logger = Roggle(
      printer: printer,
    );
    expect(logger.printer.hashCode, printer.hashCode);
  });

  test('get output', () {
    final output = ConsoleOutput();
    final logger = Roggle(
      output: output,
    );
    expect(logger.output.hashCode, output.hashCode);
  });

  test('get active', () {
    final logger = Roggle();
    expect(logger.active, true);

    logger.close();
    expect(logger.active, false);
  });
}
