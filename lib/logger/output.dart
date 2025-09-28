import 'dart:io';

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
  final List<String> logs = [];
  final List<OutputEvent> events = [];
  @override
  void output(OutputEvent event) {
    events.add(event);
    for (final message in event.lines) {
      final splited = message.split('\n');
      logs.addAll(splited);
      if (splited.length > 1) {
        if (event.level == Level.error) {
          stdout.writeln(
              '${kConsoleColorRed}samsara - ${event.level.name}:$kConsoleColorReset');
        } else if (event.level == Level.warning) {
          stdout.writeln(
              '${kConsoleColorYellow}samsara - ${event.level.name}:$kConsoleColorReset');
        } else if (event.level == Level.info) {
          stdout.writeln(
              '${kConsoleColorWhite}samsara - ${event.level.name}:$kConsoleColorReset');
        } else if (event.level == Level.debug) {
          stdout.writeln(
              '${kConsoleColorGreen}samsara - ${event.level.name}:$kConsoleColorReset');
        } else {
          stdout.writeln(
              '${kConsoleColorBlue}samsara - ${event.level.name}:$kConsoleColorReset');
        }
        for (final line in splited) {
          if (event.level == Level.error) {
            stdout.writeln('$kConsoleColorRed$line$kConsoleColorReset');
          } else if (event.level == Level.warning) {
            stdout.writeln('$kConsoleColorYellow$line$kConsoleColorReset');
          } else if (event.level == Level.info) {
            stdout.writeln('$kConsoleColorWhite$line$kConsoleColorReset');
          } else if (event.level == Level.debug) {
            stdout.writeln('$kConsoleColorGreen$line$kConsoleColorReset');
          } else {
            stdout.writeln('$kConsoleColorBlue$line$kConsoleColorReset');
          }
        }
      } else {
        if (event.level == Level.error) {
          stdout.writeln(
              '${kConsoleColorRed}samsara - ${event.level.name}: $message$kConsoleColorReset');
        } else if (event.level == Level.warning) {
          stdout.writeln(
              '${kConsoleColorYellow}samsara - ${event.level.name}: $message$kConsoleColorReset');
        } else if (event.level == Level.info) {
          stdout.writeln(
              '${kConsoleColorWhite}samsara - ${event.level.name}: $message$kConsoleColorReset');
        } else if (event.level == Level.debug) {
          stdout.writeln(
              '${kConsoleColorGreen}samsara - ${event.level.name}: $message$kConsoleColorReset');
        } else {
          stdout.writeln(
              '${kConsoleColorBlue}samsara - ${event.level.name}: $message$kConsoleColorReset');
        }
      }
    }
  }
}
