import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

/// Default implementation of [LogPrinter].
///
/// Output looks like this:
/// ```
/// 💡 [INFO]    06:46:15.354 demo (file:///your/file/path/roggle/example/main.dart:16:10): Log message
/// ```
class SinglePrettyPrinter extends LogPrinter {
  SinglePrettyPrinter({
    this.loggerName,
    this.colors = true,
    this.printCaller = true,
    this.printEmojis = true,
    this.printLabels = true,
    this.printTime = true,
    this.stackTraceLevel = Level.nothing,
    this.stackTraceMethodCount = defaultStackTraceMethodCount,
    this.stackTracePrefix = defaultStackTracePrefix,
    Map<Level, AnsiColor>? levelColors,
    this.levelEmojis = defaultLevelEmojis,
    this.levelLabels = defaultLevelLabels,
    this.timeFormatter = formatTime,
  }) : _levelColors = levelColors ?? defaultLevelColors;

  /// If specified, it will be output at the beginning of the log.
  final String? loggerName;

  /// If set to true, the log will be colorful.
  final bool colors;

  /// If set to true, caller will be output to the log.
  final bool printCaller;

  /// If set to true, the emoji will be output to the log.
  final bool printEmojis;

  /// If set to true, the log level string will be output to the log.
  final bool printLabels;

  /// If set to true, the time stamp will be output to the log.
  final bool printTime;

  /// The current logging level to display stack trace.
  ///
  /// All stack traces with levels below this level will be omitted.
  final Level stackTraceLevel;

  /// Number of stack trace methods to display.
  final int? stackTraceMethodCount;

  /// Stack trace prefix.
  final String stackTracePrefix;

  /// Color for each log level.
  final Map<Level, AnsiColor> _levelColors;

  /// Emoji for each log level.
  final Map<Level, String> levelEmojis;

  /// String for each log level.
  final Map<Level, String> levelLabels;

  /// Formats the current time.
  final TimeFormatter timeFormatter;

  /// Stack trace method count default.
  static const defaultStackTraceMethodCount = 20;

  /// Path to this file.
  static final selfPath = _getSelfPath();

  /// Stack trace prefix default.
  static const defaultStackTracePrefix = '│ ';

  /// Color default for each log level.
  static final defaultLevelColors = {
    Level.verbose: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: AnsiColor.none(),
    Level.info: AnsiColor.fg(12),
    Level.warning: AnsiColor.fg(208),
    Level.error: AnsiColor.fg(196),
    Level.wtf: AnsiColor.fg(199),
  };

  /// Emoji default for each log level.
  static const defaultLevelEmojis = {
    Level.verbose: '🐱',
    Level.debug: '🐛',
    Level.info: '💡',
    Level.warning: '⚠️',
    Level.error: '⛔',
    Level.wtf: '👾',
  };

  /// String default for each log level.
  static const defaultLevelLabels = {
    Level.verbose: '[VERBOSE]',
    Level.debug: '[DEBUG]  ',
    Level.info: '[INFO]   ',
    Level.warning: '[WARNING]',
    Level.error: '[ERROR]  ',
    Level.wtf: '[WTF]    ',
  };

  /// Matches a stacktrace line as generated on Android/iOS devices.
  /// For example:
  /// #1      Logger.log (package:roggle/src/roggle.dart:115:29)
  static final _deviceStackTraceRegex =
      RegExp(r'#[0-9]+[\s]+(.+) \(([^\s]+)\)');

  /// Matches a stacktrace line as generated by Flutter web.
  /// For example:
  /// packages/roggle/src/printers/single_pretty_printer.dart 91:37
  static final _webStackTraceRegex =
      RegExp(r'^((packages|dart-sdk)\/[^\s]+\/)');

  /// Returns the path to this file.
  static String _getSelfPath() {
    final match = RegExp(r'^(.+.dart)').firstMatch(Frame.caller(0).toString());
    if (match == null) {
      return '';
    }
    return match.group(1)!;
  }

  @override
  List<String> log(LogEvent event) {
    List<String>? stackTraceLines;
    if (event.stackTrace != null) {
      // If stackTrace is not null, it will be displayed with priority.
      stackTraceLines = getStackTrace(stackTrace: event.stackTrace);
    } else if (event.level.index >= stackTraceLevel.index) {
      stackTraceLines = getStackTrace();
    }

    return _formatMessage(
      level: event.level,
      message: stringifyMessage(event.message),
      error: event.error?.toString(),
      stackTrace: stackTraceLines,
    );
  }

  @visibleForTesting
  String? getCaller({
    StackTrace? stackTrace,
  }) {
    final lines = (stackTrace ?? StackTrace.current).toString().split('\n');
    for (final line in lines) {
      if (discardDeviceStackTraceLine(line) ||
          discardWebStackTraceLine(line) ||
          line.isEmpty) {
        continue;
      }

      // Remove unnecessary parts.
      if (_deviceStackTraceRegex.matchAsPrefix(line) != null) {
        return line
            .replaceFirst(RegExp(r'#\d+\s+'), '')
            .replaceFirst(RegExp(r'package:[a-z0-9_]+\/'), '/');
      }
      if (_webStackTraceRegex.matchAsPrefix(line) != null) {
        return line.replaceFirst(RegExp(r'^packages\/[a-z0-9_]+\/'), '/');
      }
    }
    return null;
  }

  @protected
  List<String> getStackTrace({
    StackTrace? stackTrace,
  }) {
    final lines = (stackTrace ?? StackTrace.current).toString().split('\n');
    final formatted = <String>[];
    var count = 0;
    for (final line in lines) {
      if (discardDeviceStackTraceLine(line) ||
          discardWebStackTraceLine(line) ||
          line.isEmpty) {
        continue;
      }
      if (stackTraceMethodCount != null && count >= stackTraceMethodCount!) {
        break;
      }
      final replaced = line.replaceFirst(RegExp(r'#\d+\s+'), '');
      final countPart = count.toString().padRight(7);
      formatted.add('$stackTracePrefix#$countPart$replaced');
      count++;
    }
    return formatted;
  }

  @visibleForTesting
  bool discardDeviceStackTraceLine(String line) {
    final match = _deviceStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    return match.group(2)!.startsWith('package:roggle') ||
        line.contains(selfPath);
  }

  @visibleForTesting
  bool discardWebStackTraceLine(String line) {
    final match = _webStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    return match.group(1)!.startsWith('packages/roggle') ||
        match.group(1)!.startsWith('dart-sdk/lib') ||
        line.startsWith(selfPath);
  }

  @visibleForTesting
  static String formatTime(DateTime now) {
    String _threeDigits(int n) {
      if (n >= 100) {
        return '$n';
      }
      if (n >= 10) {
        return '0$n';
      }
      return '00$n';
    }

    String _twoDigits(int n) {
      if (n >= 10) {
        return '$n';
      }
      return '0$n';
    }

    final h = _twoDigits(now.hour);
    final min = _twoDigits(now.minute);
    final sec = _twoDigits(now.second);
    final ms = _threeDigits(now.millisecond);
    return '$h:$min:$sec.$ms';
  }

  @protected
  String stringifyMessage(dynamic message) {
    if (message is dynamic Function()) {
      return message().toString();
    } else if (message is String) {
      return message;
    }
    return message.toString();
  }

  @protected
  AnsiColor getLevelColor(Level level) {
    if (colors) {
      return _levelColors[level]!;
    } else {
      return AnsiColor.none();
    }
  }

  List<String> _formatMessage({
    required Level level,
    required String message,
    String? error,
    List<String>? stackTrace,
  }) {
    final color = getLevelColor(level);
    final fixed = formatFixed(level: level);
    final logs = <String>[
      color('$fixed$message'),
    ];

    if (error != null) {
      logs.add(color('$fixed$stackTracePrefix $error'));
    }

    if (stackTrace != null && stackTrace.isNotEmpty) {
      for (final line in stackTrace) {
        logs.add(color('$fixed$line'));
      }
    }
    return logs;
  }

  @protected
  String formatFixed({
    required Level level,
  }) {
    final buffer = <String>[];

    if (printEmojis) {
      buffer.add(levelEmojis[level]!);
    }
    if (loggerName != null) {
      buffer.add(loggerName!);
    }
    if (printLabels) {
      buffer.add(levelLabels[level]!);
    }
    if (printTime) {
      buffer.add(timeFormatter(DateTime.now()));
    }
    if (printCaller) {
      final caller = getCaller();
      if (caller != null) {
        buffer.add(caller);
      }
    }
    return buffer.isNotEmpty ? '${buffer.join(' ')}: ' : '';
  }
}

/// Function to format the current time
typedef TimeFormatter = String Function(DateTime now);
