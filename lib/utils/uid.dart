import 'dart:math';

/// get a random id consists by number and letters.
String uid(int length) {
  assert(length >= 1);

  if (length < 15) {
    final id = ((Random().nextDouble() + 1) *
            int.parse('0x1'.padRight(length + 3, '0')))
        .truncate()
        .toRadixString(16)
        .substring(1);
    return id;
  } else {
    final output = StringBuffer();
    final c = (length / 12).floor();
    for (var i = 0; i < c; ++i) {
      output.write(uid(12));
    }
    output.write(uid(length - c * 12));
    return output.toString();
  }
}

/// get a random id consists by number.
String nid(int length) {
  final r = Random(DateTime.now().millisecondsSinceEpoch);
  final output = StringBuffer();
  for (var i = 0; i < length; ++i) {
    if (i == 0) {
      output.write(r.nextInt(9) + 1);
    } else {
      output.write(r.nextInt(10));
    }
  }
  return output.toString();
}
