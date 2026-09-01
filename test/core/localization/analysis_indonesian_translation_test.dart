import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/l10n/generated/app_localizations_en.dart';
import 'package:tradepilotapp/l10n/generated/app_localizations_id.dart';

void main() {
  test('dashboard and analysis copy is translated to Indonesian', () {
    final en = AppLocalizationsEn();
    final id = AppLocalizationsId();

    expect(id.marketSession, 'Sesi Pasar');
    expect(id.liquidity, 'Likuiditas');
    expect(id.wantMarketAnalysis, 'Ingin analisis pasar?');
    expect(id.latestAnalyses, 'Analisis Terbaru');
    expect(id.understandMarketBeforeEntry, 'Pahami pasar sebelum masuk');
    expect(id.selectMarketDescription, 'Pilih pasar yang ingin kamu pahami.');
    expect(id.candlestickHelp, isNot(en.candlestickHelp));
    expect(id.marketEducationDisclaimer, isNot(en.marketEducationDisclaimer));
    expect(
      id.indicatorEducationDisclaimer,
      isNot(en.indicatorEducationDisclaimer),
    );
    expect(
      id.economicEventRiskDisclaimer,
      isNot(en.economicEventRiskDisclaimer),
    );
  });
}
