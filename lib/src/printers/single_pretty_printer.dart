// ignore_for_file: deprecated_member_use

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
    this.printLocation = true,
    this.printFunctionName = true,
    this.printEmojis = true,
    this.printLabels = true,
    this.printTime = true,
    this.stackTraceLevel = Level.off,
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

  /// If set to true, location of caller will be output to the log.
  ///
  /// Set [printCaller] to true if you want to enable [printLocation].
  final bool printLocation;

  /// If set to true, function name of caller will be output to the log.
  ///
  /// Set [printCaller] to true if you want to enable [printFunctionName].
  final bool printFunctionName;

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

  /// Stack trace prefix default.
  static const defaultStackTracePrefix = '│ ';

  /// Color default for each log level.
  static final defaultLevelColors = {
    Level.verbose: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.wtf: const AnsiColor.fg(199),
    Level.fatal: const AnsiColor.fg(199),
  };

  /// Emoji default for each log level.
  static const defaultLevelEmojis = {
    Level.verbose: '🐱',
    Level.trace: '🐱',
    Level.debug: '🐛',
    Level.info: '👀',
    Level.warning: '❗',
    Level.error: '⛔',
    Level.wtf: '🔥',
    Level.fatal: '🔥',
  };

  /// String default for each log level.
  static const defaultLevelLabels = {
    Level.verbose: '[VERBOSE]',
    Level.trace: '[TRACE]  ',
    Level.debug: '[DEBUG]  ',
    Level.info: '[INFO]   ',
    Level.warning: '[WARNING]',
    Level.error: '[ERROR]  ',
    Level.wtf: '[WTF]    ',
    Level.fatal: '[FATAL]  ',
  };

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
    final trace = stackTrace != null ? Trace.from(stackTrace) : Trace.current();
    final caller = trace.caller;
    if (caller == null) {
      return null;
    }
    return convertToCallerString(
      caller,
      printFunctionName: printFunctionName,
      printLocation: printLocation,
    );
  }

  @protected
  List<String> getStackTrace({
    StackTrace? stackTrace,
  }) {
    final trace = stackTrace != null ? Trace.from(stackTrace) : Trace.current();
    final formatted = <String>[];
    var count = 0;
    for (final frame in trace.frames) {
      if (!frame.isUserFrame) {
        continue;
      }
      if (stackTraceMethodCount != null && count >= stackTraceMethodCount!) {
        break;
      }

      final caller = convertToCallerString(frame) ?? '';
      final countPart = count.toString().padRight(7);
      formatted.add('$stackTracePrefix#$countPart$caller');
      count++;
    }
    return formatted;
  }

  @protected
  String? convertToCallerString(
    Frame frame, {
    bool printFunctionName = true,
    bool printLocation = true,
  }) {
    if (!printFunctionName && !printLocation) {
      return null;
    }

    final parts = <String>[];
    if (printFunctionName) {
      final member = frame.member;
      if (member != null) {
        parts.add(member);
      }
    }
    if (printLocation) {
      parts.add('(${frame.locationEx})');
    }
    return parts.join(' ');
  }

  @visibleForTesting
  static String formatTime(DateTime now) {
    String threeDigits(int n) {
      if (n >= 100) {
        return '$n';
      }
      if (n >= 10) {
        return '0$n';
      }
      return '00$n';
    }

    String twoDigits(int n) {
      if (n >= 10) {
        return '$n';
      }
      return '0$n';
    }

    final h = twoDigits(now.hour);
    final min = twoDigits(now.minute);
    final sec = twoDigits(now.second);
    final ms = threeDigits(now.millisecond);
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
      return const AnsiColor.none();
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
      logs.add(color('$fixed$stackTracePrefix$error'));
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

extension _TraceEx on Trace {
  /// Return first frame in user frames
  Frame? get caller {
    for (final frame in frames) {
      if (frame.isUserFrame) {
        return frame;
      }
    }
    return null;
  }
}

extension _FrameEx on Frame {
  /// If user frame is true, other false
  bool get isUserFrame => !isCoreEx && packageEx != 'roggle';

  /// Whether this stack frame comes from the Web.
  bool get isWeb => uri.scheme == 'http' || uri.scheme == 'https';

  /// Extension of [isCore]
  bool get isCoreEx {
    if (isWeb && packageEx == null) {
      return true;
    }
    return isCore;
  }

  /// Extension of [library]
  String get libraryEx => library
      .replaceAll('\\', '/')
      .replaceFirst(RegExp(r'^packages\/'), 'package:');

  /// Extension of [package]
  String? get packageEx {
    if (isWeb) {
      final paths =
          uri.path.split('/').where((path) => path.isNotEmpty).toList();
      if (paths.length >= 2 && paths[0] == 'packages') {
        return paths[1];
      }
    }
    return package;
  }

  /// Extension of [location]
  String get locationEx {
    if (line == null) {
      return libraryEx;
    }
    if (column == null) {
      return '$libraryEx:$line';
    }
    return '$libraryEx:$line:$column';
  }
}
