import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tradepilotapp/services/adaptive_plan_report.dart';

AdaptivePlanReport _report({int paragraphs = 1}) => AdaptivePlanReport(
  title: 'Understand the details',
  instrument: 'XAU/USD',
  timeframe: '1h',
  analyzedAt: 'Sep 30, 2026 12:00',
  summary: 'Saved analysis summary',
  briefLabel: 'Briefing summary',
  sections: [
    ReportSection('Why this analysis', [
      for (var i = 0; i < paragraphs; i++)
        const ReportBlock.paragraph(
          '**Risk**\nSpreads widen and stops get hunted around releases, '
          'so the plan keeps a wider Stop Loss than the entry zone alone implies.',
        ),
      const ReportBlock.item('First point'),
    ]),
    const ReportSection('Empty section', []),
  ],
  sourcesTitle: 'Data sources',
  sources: const ['Gold rallies again'],
  disclaimer: 'Not financial advice.',
  referenceId: 'Analysis #42',
);

final _fonts = ReportFonts(
  base: pw.Font.helvetica(),
  bold: pw.Font.helveticaBold(),
);

Future<String> _pdfText(AdaptivePlanReport report) async {
  final bytes = await buildAdaptivePlanReportPdf(
    report,
    PdfPageFormat.a4,
    _fonts,
    compress: false,
  );
  return latin1.decode(bytes);
}

int _count(String text, Pattern pattern) => pattern.allMatches(text).length;

void main() {
  test('renders the guide as a PDF document', () async {
    final bytes = await buildAdaptivePlanReportPdf(
      _report(),
      PdfPageFormat.a4,
      _fonts,
    );

    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('prints the watermark on every page, not only the first', () async {
    // Large "TradePilot.id" runs (54/76 pt) are the watermark; the 8/9 pt ones
    // are the brand line and footer.
    final watermark = RegExp(
      r'/F\d+ (?:54|76) Tf[^\]]*\[\(TradePilot\.id\)\]TJ',
    );
    final pageType = RegExp(r'/Type\s*/Page\b');
    final short = await _pdfText(_report());
    final long = await _pdfText(_report(paragraphs: 90));

    expect(_count(short, pageType), 1);
    expect(_count(long, pageType), greaterThan(2));
    for (final pdf in [short, long]) {
      expect(_count(pdf, watermark), _count(pdf, pageType) * 3);
    }
  });

  test('parses the bundled Inter font used in the app', () async {
    final data = File('assets/fonts/Inter-VariableFont_opsz_wght.ttf');
    final inter = pw.Font.ttf(ByteData.sublistView(data.readAsBytesSync()));
    final bytes = await buildAdaptivePlanReportPdf(
      _report(),
      PdfPageFormat.a4,
      ReportFonts(
        base: inter,
        bold: pw.Font.helveticaBold(),
        fallback: [inter],
      ),
    );

    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
