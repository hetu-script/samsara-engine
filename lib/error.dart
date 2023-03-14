import 'package:flutter/material.dart';

GlobalKey mainKey = GlobalKey();

// 根据自己情况上报异常
void onError(FlutterErrorDetails details, [BuildContext? context]) {
  WidgetsBinding.instance.addPostFrameCallback(
    (timeStamp) {
      showDialog(
        context: context ?? mainKey.currentContext!,
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
                    Text('${details.stack}'),
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
