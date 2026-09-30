import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/services/export_watermark.dart';

Future<Uint8List> _solidPng(int width, int height, ui.Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  return (await codec.getNextFrame()).image;
}

void main() {
  test('attribution names the instrument, timeframe and analysis', () {
    expect(
      exportAttribution(instrument: 'XAU/USD', timeframe: '1h', analysisId: 7),
      'TradePilot.id · XAU/USD · 1h · Analysis #7',
    );
  });

  testWidgets('stamps a mark over the picture and adds an attribution strip', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const width = 600;
      const height = 400;
      final source = await _solidPng(width, height, const ui.Color(0xFF101820));
      final marked = await watermarkPng(
        source,
        attribution: 'TradePilot.id · XAU/USD · 1h · Analysis #7',
      );
      final image = await _decode(marked);

      // The strip is added below, so the chart itself is never covered.
      expect(image.width, width);
      expect(image.height, greaterThan(height));

      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      int red(int x, int y) => pixels.getUint8((y * image.width + x) * 4);
      final background = red(2, 2);
      var changed = 0;
      for (var y = 0; y < height; y += 2) {
        for (var x = 0; x < width; x += 2) {
          if ((red(x, y) - background).abs() > 6) changed++;
        }
      }
      expect(changed, greaterThan(150), reason: 'watermark pixels over image');

      // Bottom strip is a different, non-transparent block.
      final stripPixel = red(width - 3, image.height - 3);
      expect(stripPixel, isNot(background));
    });
  });
}
