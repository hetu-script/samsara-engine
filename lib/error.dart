import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

GlobalKey mainKey = GlobalKey();

int stackTraceDisplayCountLimit = 5;

String trimStackTrace(StackTrace stackTrace) {
  final stack = stackTrace.toString().trim().split('\n');
  final sb = StringBuffer();
  if (stackTraceDisplayCountLimit > 0 &&
      stack.length > stackTraceDisplayCountLimit) {
    for (var i = stack.length - 1;
        i >= stack.length - stackTraceDisplayCountLimit;
        --i) {
      sb.writeln(stack[i]);
    }
    sb.writeln(
        '...(and other ${stack.length - stackTraceDisplayCountLimit} messages)');
  } else {
    for (var i = stack.length - 1; i >= 0; --i) {
      sb.writeln(stack[i]);
    }
  }
  return sb.toString();
}

// 对于Flutter没有捕捉到的错误，弹出系统原生对话框
void alertNativeError(error, stackTrace) {
  final stack = trimStackTrace(stackTrace);
  FlutterPlatformAlert.showAlert(
    windowTitle: 'An unexpected error happened!',
    text: '$error\n$stack',
    alertStyle: AlertButtonStyle.ok,
    iconStyle: IconStyle.error,
  );
}

// 根据自己情况上报异常
void alertFlutterError(FlutterErrorDetails details) {
  String stack = '';
  if (details.stack != null) {
    stack = trimStackTrace(details.stack!);
  }

  WidgetsBinding.instance.addPostFrameCallback(
    (timeStamp) async {
      await showDialog(
        barrierDismissible: false,
        context: mainKey.currentContext!,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Container(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Exception:'),
                    Text('${details.exception}'),
                    const Text('Stack:'),
                    Text(stack),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Okay'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}
