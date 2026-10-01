import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Content of the shareable Adaptive plan summary image (web
/// `AdaptivePlanShareData`). It carries one side only, the original analysis
/// time, the status, the key numbers and a short warning: never the chart or
/// the long explanation.
class AdaptivePlanShareData {
  const AdaptivePlanShareData({
    required this.title,
    required this.instrument,
    required this.timeframe,
    required this.analyzedAt,
    required this.generatedLabel,
    required this.sideLabel,
    required this.status,
    required this.actionable,
    required this.statusDetail,
    required this.account,
    required this.style,
    required this.positionsTitle,
    required this.positions,
    required this.metrics,
    required this.notes,
  });

  final String title;
  final String instrument;
  final String timeframe;
  final String analyzedAt;
  final String generatedLabel;
  final String sideLabel;
  final String status;
  final bool actionable;
  final String statusDetail;
  final String account;
  final String style;
  final String positionsTitle;
  final List<({String label, String value})> positions;
  final List<({String label, String value, String? detail})> metrics;
  final List<String> notes;

  AdaptivePlanShareData withGeneratedLabel(String label) =>
      AdaptivePlanShareData(
        title: title,
        instrument: instrument,
        timeframe: timeframe,
        analyzedAt: analyzedAt,
        generatedLabel: label,
        sideLabel: sideLabel,
        status: status,
        actionable: actionable,
        statusDetail: statusDetail,
        account: account,
        style: style,
        positionsTitle: positionsTitle,
        positions: positions,
        metrics: metrics,
        notes: notes,
      );
}

const _width = 1080.0;
const _pad = 52.0;
const _content = _width - _pad * 2;
const _maxHeight = 12000.0;

ui.Color _c(int argb) => ui.Color(argb);

/// Lays out (and optionally paints) the summary; returns the total height.
class _Sheet {
  _Sheet(this.canvas);
  final ui.Canvas? canvas;

  ui.Paragraph _layout(
    String text,
    double size,
    ui.Color color,
    double width,
    bool bold,
  ) {
    final weight = bold ? ui.FontWeight.w700 : ui.FontWeight.w400;
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontFamily: 'Inter',
              fontSize: size,
              fontWeight: weight,
              height: 29 / size,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: size,
              fontWeight: weight,
              fontFamily: 'Inter',
              height: 29 / size,
            ),
          )
          ..addText(text);
    return builder.build()..layout(ui.ParagraphConstraints(width: width));
  }

  /// Draws [text] wrapped to [width] and returns the y below it.
  double text(
    String value,
    double x,
    double y,
    ui.Color color,
    double size,
    double width, {
    bool bold = false,
  }) {
    final paragraph = _layout(value, size, color, width, bold);
    canvas?.drawParagraph(paragraph, ui.Offset(x, y));
    return y + math.max(29, paragraph.height);
  }

  double measure(
    String value,
    double size,
    double width, {
    bool bold = false,
  }) => math.max(29, _layout(value, size, _c(0xFFFFFFFF), width, bold).height);

  void rect(ui.Rect rect, ui.Color color) =>
      canvas?.drawRect(rect, ui.Paint()..color = color);
}

double _drawSummary(_Sheet s, AdaptivePlanShareData d) {
  var y = 64.0;
  y =
      s.text(
        'TRADEPILOT.ID',
        _pad,
        y,
        _c(0xFFE8AD2B),
        21,
        _content,
        bold: true,
      ) +
      9;
  y = s.text(d.title, _pad, y, _c(0xFFF7F7F9), 32, _content, bold: true) + 10;
  y =
      s.text(
        '${d.instrument} · ${d.timeframe} · ${d.sideLabel}',
        _pad,
        y,
        _c(0xFFD8DBE0),
        23,
        _content,
        bold: true,
      ) +
      7;
  y = s.text(d.analyzedAt, _pad, y, _c(0xFFAEB1BA), 19, _content) + 26;

  final statusTop = y - 22;
  final statusColor = d.actionable ? _c(0xFF65D9B6) : _c(0xFFF5B441);
  final statusHeight =
      22 +
      s.measure(d.status, 25, _content - 44, bold: true) +
      9 +
      s.measure(d.statusDetail, 19, _content - 44);
  s
    ..rect(
      ui.Rect.fromLTWH(_pad, statusTop, _content, statusHeight),
      _c(0xFF272318),
    )
    ..rect(ui.Rect.fromLTWH(_pad, statusTop, 5, statusHeight), statusColor);
  y =
      s.text(
        d.status,
        _pad + 22,
        y,
        statusColor,
        25,
        _content - 44,
        bold: true,
      ) +
      9;
  y = s.text(d.statusDetail, _pad + 22, y, _c(0xFFE5E7EB), 19, _content - 44);
  y += 24;
  y =
      s.text(
        '${d.account}  ·  ${d.style}',
        _pad,
        y,
        _c(0xFFD6D8DE),
        20,
        _content,
      ) +
      32;

  y =
      s.text(
        d.positionsTitle,
        _pad,
        y,
        _c(0xFFF7F7F9),
        23,
        _content,
        bold: true,
      ) +
      8;
  for (final position in d.positions) {
    final top = y;
    final left = s.text(
      position.label,
      _pad + 18,
      top,
      _c(0xFFD6D8DE),
      20,
      _content * .49,
    );
    final right = s.text(
      position.value,
      _pad + _content * .52,
      top,
      _c(0xFFFFFFFF),
      20,
      _content * .45,
      bold: true,
    );
    y = math.max(left, right) + 14;
    s.rect(ui.Rect.fromLTWH(_pad, y - 6, _content, 1), _c(0xFF303740));
  }
  y += 22;
  const metricWidth = (_content - 22) / 2;
  for (var i = 0; i < d.metrics.length; i += 2) {
    final rowTop = y;
    var bottom = rowTop;
    for (
      var offset = 0;
      offset < 2 && i + offset < d.metrics.length;
      offset++
    ) {
      final metric = d.metrics[i + offset];
      final x = _pad + offset * (metricWidth + 22);
      var row =
          s.text(metric.label, x, rowTop, _c(0xFFAEB1BA), 18, metricWidth) + 7;
      row =
          s.text(
            metric.value,
            x,
            row,
            _c(0xFFF7F7F9),
            26,
            metricWidth,
            bold: true,
          ) +
          3;
      if (metric.detail != null) {
        row = s.text(metric.detail!, x, row, _c(0xFF65D9B6), 18, metricWidth);
      }
      bottom = math.max(bottom, row);
    }
    y = bottom + 44;
    s.rect(ui.Rect.fromLTWH(_pad, y - 24, _content, 1), _c(0xFF303740));
  }
  y += 15;
  for (final entry in d.notes.indexed) {
    y =
        s.text(
          entry.$2,
          _pad,
          y,
          entry.$1 == 0 ? _c(0xFFF5B441) : _c(0xFFC5C9D0),
          19,
          _content,
        ) +
        18;
  }
  y += 10;
  s.text(d.generatedLabel, _pad, y, _c(0xFFAEB1BA), 17, _content);
  return y + 72;
}

/// Renders [data] to a PNG. The caller watermarks it before it leaves the app.
Future<Uint8List> renderAdaptivePlanSharePng(AdaptivePlanShareData data) async {
  final height = _drawSummary(_Sheet(null), data).ceilToDouble();
  if (height > _maxHeight) throw StateError('Adaptive plan too long to export');
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, _width, height));
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, _width, height),
    ui.Paint()..color = _c(0xFF101216),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, _width, 7),
    ui.Paint()..color = _c(0xFFE8AD2B),
  );
  _drawSummary(_Sheet(canvas), data);
  final image = await recorder.endRecording().toImage(
    _width.toInt(),
    height.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) throw StateError('PNG export failed');
  return bytes.buffer.asUint8List();
}
