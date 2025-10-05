import 'package:logger/logger.dart';

class CustomLoggerPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final splited = event.message.split('\n');
    return splited;
  }
}
