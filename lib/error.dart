import 'dart:io';

import 'package:flutter/material.dart';

GlobalKey scafoldKey = GlobalKey();

// 根据自己情况上报异常
void onError(FlutterErrorDetails details) {
  WidgetsBinding.instance.addPostFrameCallback(
    (timeStamp) {
      showDialog(
        context: scafoldKey.currentContext!,
        builder: (b) {
          return Padding(
            padding: const EdgeInsets.all(50.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(b).pop();
                exit(1);
              },
              child: Material(
                child: Container(
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
                  )),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
