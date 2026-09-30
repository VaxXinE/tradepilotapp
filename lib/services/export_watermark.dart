import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Marks everything that leaves the app (copied/saved/shared images, copied
/// text, printed PDFs) as TradePilot.id output so a copy is attributable.
const exportBrand = 'TradePilot.id';

/// One-line attribution appended to exported text and stamped under images:
/// `TradePilot.id · XAU/USD · 1h · Analysis #123`.
String exportAttribution({
  required String instrument,
  required String timeframe,
  required int analysisId,
}) => '$exportBrand · $instrument · $timeframe · Analysis #$analysisId';

const _markColor = ui.Color(0xFFB68118);
const _stripColor = ui.Color(0xFF0F1115);
const _stripText = ui.Color(0xFFE8C46A);

ui.Paragraph _paragraph(
  String text, {
  required double fontSize,
  required ui.Color color,
  ui.FontWeight weight = ui.FontWeight.w800,
  double letterSpacing = 0,
  double maxWidth = 100000,
}) {
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            fontWeight: weight,
            maxLines: 1,
          ),
        )
        ..pushStyle(
          ui.TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            fontFamily: 'Inter',
            letterSpacing: letterSpacing,
          ),
        )
        ..addText(text);
  return builder.build()..layout(ui.ParagraphConstraints(width: maxWidth));
}

/// Draws the diagonal, repeating brand mark over [area]. Tiled rather than a
/// single centred mark so cropping a corner still leaves the mark in view.
void _paintWatermark(ui.Canvas canvas, ui.Rect area) {
  final fontSize = (area.width * 0.055).clamp(20.0, 84.0);
  final mark = _paragraph(
    exportBrand,
    fontSize: fontSize,
    color: _markColor.withValues(alpha: 0.2),
    letterSpacing: fontSize * 0.04,
  );
  final stepX = mark.longestLine * 1.7;
  final stepY = fontSize * 4.2;
  final reach = math.sqrt(area.width * area.width + area.height * area.height);

  canvas
    ..save()
    ..clipRect(area)
    ..translate(area.center.dx, area.center.dy)
    ..rotate(-0.42);
  var row = 0;
  for (var y = -reach; y <= reach; y += stepY, row++) {
    final shift = row.isEven ? 0.0 : stepX / 2;
    for (var x = -reach + shift; x <= reach; x += stepX) {
      canvas.drawParagraph(mark, ui.Offset(x - mark.longestLine / 2, y));
    }
  }
  canvas.restore();
}

/// Returns [png] with the tiled mark over it and an attribution strip below.
/// The strip is added under the picture, so no chart content is covered.
Future<Uint8List> watermarkPng(
  Uint8List png, {
  required String attribution,
}) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  codec.dispose();

  final width = image.width.toDouble();
  final height = image.height.toDouble();
  final stripHeight = math.max(30.0, width * 0.055);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawImage(image, ui.Offset.zero, ui.Paint());
  _paintWatermark(canvas, ui.Rect.fromLTWH(0, 0, width, height));

  canvas.drawRect(
    ui.Rect.fromLTWH(0, height, width, stripHeight),
    ui.Paint()..color = _stripColor,
  );
  final fontSize = stripHeight * 0.42;
  final label = _paragraph(
    attribution,
    fontSize: fontSize,
    color: _stripText,
    weight: ui.FontWeight.w700,
    maxWidth: width - fontSize * 2,
  );
  canvas.drawParagraph(
    label,
    ui.Offset(fontSize, height + (stripHeight - label.height) / 2),
  );

  final output = await recorder.endRecording().toImage(
    image.width,
    (height + stripHeight).round(),
  );
  final data = await output.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  output.dispose();
  if (data == null) throw StateError('Watermarked image encoding failed');
  return data.buffer.asUint8List();
}
