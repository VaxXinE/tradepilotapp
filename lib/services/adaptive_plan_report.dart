import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum ReportBlockKind { subheading, paragraph, item }

class ReportBlock {
  const ReportBlock(this.kind, this.text);
  const ReportBlock.subheading(String text)
    : this(ReportBlockKind.subheading, text);
  const ReportBlock.paragraph(String text)
    : this(ReportBlockKind.paragraph, text);
  const ReportBlock.item(String text) : this(ReportBlockKind.item, text);

  final ReportBlockKind kind;
  final String text;
}

class ReportSection {
  const ReportSection(this.title, this.blocks);

  final String title;
  final List<ReportBlock> blocks;
}

/// Data behind the printable "Understand the details" guide. Mirrors the web's
/// `ConfidenceShareData` (artifacts/ai-trading/src/lib/confidence-share.ts).
class AdaptivePlanReport {
  const AdaptivePlanReport({
    required this.title,
    required this.instrument,
    required this.timeframe,
    required this.analyzedAt,
    required this.summary,
    required this.briefLabel,
    required this.sections,
    required this.sourcesTitle,
    required this.sources,
    required this.disclaimer,
    this.referenceId,
  });

  final String title;
  final String instrument;
  final String timeframe;
  final String analyzedAt;
  final String summary;
  final String briefLabel;
  final List<ReportSection> sections;
  final String sourcesTitle;
  final List<String> sources;
  final String disclaimer;

  /// Analysis id printed in the footer so a copy can be traced back.
  final String? referenceId;
}

class ReportFonts {
  const ReportFonts({
    required this.base,
    required this.bold,
    this.fallback = const [],
  });

  final pw.Font base;
  final pw.Font bold;
  final List<pw.Font> fallback;
}

const _fontAsset = 'assets/fonts/Inter-VariableFont_opsz_wght.ttf';

/// Inter (bundled) covers the symbols AI text uses; Helvetica Bold is used for
/// labels and falls back to Inter for any glyph it lacks.
Future<ReportFonts> loadReportFonts() async {
  final inter = pw.Font.ttf(await rootBundle.load(_fontAsset));
  return ReportFonts(
    base: inter,
    bold: pw.Font.helveticaBold(),
    fallback: [inter],
  );
}

const _brandName = 'TradePilot.id';
const _ink = PdfColor.fromInt(0xFF1D232B);
const _muted = PdfColor.fromInt(0xFF55616D);
const _gold = PdfColor.fromInt(0xFF996409);
const _goldSoft = PdfColor.fromInt(0xFFFAF8F2);
const _rule = PdfColor.fromInt(0xFFD7DCE1);
const _watermark = PdfColor.fromInt(0xFF806A42);

final _boldMarkup = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
final _italicMarkup = RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)');

/// Splits AI text on `**bold**` and drops the lighter `*italic*` markers.
List<pw.InlineSpan> _spans(String text, ReportFonts fonts) {
  final spans = <pw.InlineSpan>[];
  var cursor = 0;
  void plain(String value) {
    final cleaned = value.replaceAllMapped(_italicMarkup, (m) => m[1]!);
    if (cleaned.isNotEmpty) spans.add(pw.TextSpan(text: cleaned));
  }

  for (final match in _boldMarkup.allMatches(text)) {
    plain(text.substring(cursor, match.start));
    spans.add(
      pw.TextSpan(
        text: match[1],
        style: pw.TextStyle(font: fonts.bold, fontFallback: fonts.fallback),
      ),
    );
    cursor = match.end;
  }
  plain(text.substring(cursor));
  return spans;
}

/// The mark is drawn on every page (page background layer), not once at the
/// top, so no page of a printed copy is free of it.
pw.Widget _watermarkLayer(ReportFonts fonts) {
  pw.Widget mark(double size) => pw.Transform.rotate(
    angle: -0.42,
    child: pw.Opacity(
      opacity: 0.12,
      child: pw.Text(
        _brandName,
        style: pw.TextStyle(
          font: fonts.bold,
          fontFallback: fonts.fallback,
          fontSize: size,
          color: _watermark,
          letterSpacing: 2,
        ),
      ),
    ),
  );
  return pw.FullPage(
    ignoreMargins: true,
    child: pw.Stack(
      children: [
        pw.Positioned(
          top: 110,
          left: 0,
          right: 0,
          child: pw.Center(child: mark(54)),
        ),
        pw.Center(child: mark(76)),
        pw.Positioned(
          bottom: 110,
          left: 0,
          right: 0,
          child: pw.Center(child: mark(54)),
        ),
      ],
    ),
  );
}

Future<Uint8List> buildAdaptivePlanReportPdf(
  AdaptivePlanReport report,
  PdfPageFormat format,
  ReportFonts fonts, {
  bool compress = true,
}) async {
  final document = pw.Document(
    title: '${report.title} — $_brandName',
    author: _brandName,
    creator: _brandName,
    compress: compress,
  );
  pw.TextStyle style({
    double size = 10.5,
    pw.Font? font,
    PdfColor color = _ink,
    double height = 1.4,
  }) => pw.TextStyle(
    font: font ?? fonts.base,
    fontFallback: fonts.fallback,
    fontSize: size,
    color: color,
    lineSpacing: (height - 1) * size,
  );

  pw.Widget block(ReportBlock item) => switch (item.kind) {
    ReportBlockKind.subheading => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 2),
      child: pw.Text(item.text, style: style(size: 11, font: fonts.bold)),
    ),
    ReportBlockKind.item => pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, bottom: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          style: style(),
          children: [
            pw.TextSpan(text: '• '),
            ..._spans(item.text, fonts),
          ],
        ),
      ),
    ),
    ReportBlockKind.paragraph => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.RichText(
        text: pw.TextSpan(style: style(), children: _spans(item.text, fonts)),
      ),
    ),
  };

  pw.Widget heading(String title) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(top: 18, bottom: 8),
    padding: const pw.EdgeInsets.only(bottom: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.8)),
    ),
    child: pw.Text(title, style: style(size: 14, font: fonts.bold)),
  );

  document.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: format,
        margin: const pw.EdgeInsets.fromLTRB(46, 44, 46, 44),
        buildBackground: (_) => _watermarkLayer(fonts),
      ),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              [
                _brandName,
                report.instrument,
                report.analyzedAt,
                ?report.referenceId,
              ].join(' · '),
              style: style(size: 8, color: _muted),
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: style(size: 8, color: _muted),
            ),
          ],
        ),
      ),
      build: (context) => [
        pw.Text(
          _brandName.toUpperCase(),
          style: style(size: 9, font: fonts.bold, color: _gold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(report.title, style: style(size: 24, font: fonts.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          '${report.instrument} · ${report.timeframe} · ${report.analyzedAt}',
          style: style(size: 10, color: _muted),
        ),
        pw.SizedBox(height: 18),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const pw.BoxDecoration(
            color: _goldSoft,
            border: pw.Border(left: pw.BorderSide(color: _gold, width: 3)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                report.briefLabel.toUpperCase(),
                style: style(size: 8, font: fonts.bold, color: _gold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(report.summary, style: style(size: 11.5)),
            ],
          ),
        ),
        for (final section in report.sections)
          if (section.blocks.isNotEmpty) ...[
            heading(section.title),
            ...section.blocks.map(block),
          ],
        if (report.sources.isNotEmpty) ...[
          heading(report.sourcesTitle),
          for (final source in report.sources) block(ReportBlock.item(source)),
        ],
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 22),
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _gold, width: 1.5)),
          ),
          child: pw.Text(
            report.disclaimer,
            style: style(size: 9.5, color: _muted),
          ),
        ),
      ],
    ),
  );
  return document.save();
}

/// Opens the system print sheet (iOS/Android), which also offers "Save as PDF".
Future<void> printAdaptivePlanReport(
  AdaptivePlanReport report, {
  String? jobName,
}) async {
  final fonts = await loadReportFonts();
  await Printing.layoutPdf(
    name: jobName ?? '${report.title} - ${report.instrument}',
    onLayout: (format) => buildAdaptivePlanReportPdf(report, format, fonts),
  );
}
