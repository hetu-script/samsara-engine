import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

const kConsoleColorBlack = '\x1B[30m';
const kConsoleColorRed = '\x1B[31m';
const kConsoleColorGreen = '\x1B[32m';
const kConsoleColorYellow = '\x1B[33m';
const kConsoleColorBlue = '\x1B[34m';
const kConsoleColorMagenta = '\x1B[35m';
const kConsoleColorCyan = '\x1B[36m';
const kConsoleColorWhite = '\x1B[37m';
const kConsoleColorReset = '\x1B[0m';

class CustomLoggerOutput extends LogOutput {
  final List<(Level, String)> logs = [];

  @override
  void output(OutputEvent event) {
    logs.add((event.level, event.lines.join('\n')));
    // release 模式只保存到内存，不输出到控制台
    if (kDebugMode || kProfileMode) {
      // 开发模式：输出到控制台
      if (event.lines.length > 1) {
        if (event.level == Level.error) {
          stdout.writeln(
              '${kConsoleColorRed}samsara - ${event.level.name}:$kConsoleColorReset');
        } else if (event.level == Level.warning) {
          stdout.writeln(
              '${kConsoleColorYellow}samsara - ${event.level.name}:$kConsoleColorReset');
        } else if (event.level == Level.info) {
          stdout.writeln(
              '${kConsoleColorGreen}samsara - ${event.level.name}:$kConsoleColorReset');
        } else {
          stdout.writeln('samsara - ${event.level.name}:');
        }
        for (final line in event.lines) {
          if (event.level == Level.error) {
            stdout.writeln('$kConsoleColorRed$line$kConsoleColorReset');
          } else if (event.level == Level.warning) {
            stdout.writeln('$kConsoleColorYellow$line$kConsoleColorReset');
          } else if (event.level == Level.info) {
            stdout.writeln('$kConsoleColorGreen$line$kConsoleColorReset');
          } else {
            stdout.writeln(line);
          }
        }
      } else {
        if (event.level == Level.error) {
          stdout.writeln(
              '${kConsoleColorRed}samsara - ${event.level.name}: ${event.lines.first}$kConsoleColorReset');
        } else if (event.level == Level.warning) {
          stdout.writeln(
              '${kConsoleColorYellow}samsara - ${event.level.name}: ${event.lines.first}$kConsoleColorReset');
        } else if (event.level == Level.info) {
          stdout.writeln(
              '${kConsoleColorGreen}samsara - ${event.level.name}: ${event.lines.first}$kConsoleColorReset');
        } else {
          stdout.writeln('samsara - ${event.level.name}: ${event.lines.first}');
        }
      }
    }
  }
}
