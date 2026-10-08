import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fast_noise/fast_noise.dart';

int _floatToInt8(double x) {
  // return (x * 255.0).round() & 0xff;
  return x.round().clamp(0, 255);
}

/// A 32 bit value representing this color.
///
/// The bits are assigned as follows:
///
/// * Bits 24-31 are the red value.
/// * Bits 16-23 are the blue value.
/// * Bits 8-15 are the green value.
/// * Bits 0-7 are the alpha value.
int getABGR(double a, double b, double g, double r) {
  return _floatToInt8(a) << 24 |
      _floatToInt8(b) << 16 |
      _floatToInt8(g) << 8 |
      _floatToInt8(r) << 0;
}

// int ARGBToABGR(int argbColor) {
//   int r = (argbColor >> 16) & 0xFF;
//   int b = argbColor & 0xFF;
//   return (argbColor & 0xFF00FF00) | (b << 16) | r;
// }

Future<ui.Image> makeImage(List<List<double>> noiseData,
    {required threshold, required double threshold2}) async {
  assert(threshold2 < threshold);
  final dimension = noiseData.length;
  final c = Completer<ui.Image>();
  final pixels = Int32List(dimension * dimension);
  for (var x = 0; x < dimension; ++x) {
    for (var y = 0; y < dimension; ++y) {
      final noise = noiseData[x][y];
      final normalize = (noise + 1) / 2;
      int abgr = 0;
      if (normalize > threshold) {
        // 海洋
        abgr = getABGR(255, 128, 0, 0);
      } else if (normalize > threshold2) {
        // 陆地
        abgr = getABGR(255, 0, 128, 0);
      } else {
        // 山地
        abgr = getABGR(255, 128, 128, 128);
      }
      pixels[y * dimension + x] = abgr;
    }
  }
  ui.decodeImageFromPixels(
    pixels.buffer.asUint8List(),
    dimension,
    dimension,
    ui.PixelFormat.rgba8888,
    c.complete,
  );
  return c.future;
}

class NoiseTest extends StatelessWidget {
  const NoiseTest({super.key});

  @override
  Widget build(BuildContext context) {
    const size = Size(512, 512);
    const dimension = 50;
    // 群岛 islands:
    //   normalize > 0.45, threshold2 = 0.32, frequency： 6 /, type: perlinFractal, octaves: 3
    // 滨海 coast:
    //   normalize > 0.55, threshold2 = 0.28, frequency： 3.5 /, type: valueFractal, octaves: 10
    // 内陆 inland:
    //   normalize > 0.65, threshold2 = 0.42, frequency： 10 /, type: cubicFractal, octaves: 3
    final threshold = 0.65;
    final threshold2 = 0.42;
    final noiseData = noise2(
      dimension,
      dimension,
      seed: math.Random().nextInt(1 << 32),
      frequency: 10 / dimension,
      noiseType: NoiseType.cubicFractal,
      octaves: 3,
    );

    return Center(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Noise Test'),
          ),
          body: FutureBuilder<ui.Image>(
            future: makeImage(
              noiseData,
              threshold: threshold,
              threshold2: threshold2,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Center(
                  child: RawImage(
                    width: 400,
                    height: 400,
                    fit: BoxFit.fill,
                    image: snapshot.data,
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),

          //  CustomPaint(
          //   size: size,
          //   painter: NoisePainter(data: noiseData),
          // ),
        ),
      ),
    );
  }
}
