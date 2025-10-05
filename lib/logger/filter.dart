import 'package:logger/logger.dart';

/// 自定义Logger过滤器，在所有模式下都允许日志记录
class CustomLoggerFilter extends LogFilter {
  /// minLevel: 最低日志级别
  CustomLoggerFilter([Level minLevel = Level.trace]) {
    level = minLevel;
  }

  @override
  bool shouldLog(LogEvent event) {
    // 在所有模式（debug, profile, release）下都允许记录日志
    // 只根据日志级别进行过滤
    return event.level.index >= level!.index;
  }
}
