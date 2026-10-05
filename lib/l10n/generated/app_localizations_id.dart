// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'TradePilot.id';

  @override
  String get tradePilotLogo => 'Logo TradePilot.id';

  @override
  String get aiTradingAssistant => 'Analisis trading bertenaga AI';

  @override
  String get dashboard => 'Beranda';

  @override
  String get dashboardDescription =>
      'Ringkasan market, watchlist, dan analisis terbaru';

  @override
  String get analysis => 'Analisis';

  @override
  String get analysisNotFound => 'Analisis tidak ditemukan';

  @override
  String get analysisCreateFailed => 'Analisis baru gagal dibuat.';

  @override
  String get analysisFeedbackTitle => 'Feedback analisis';

  @override
  String get analysisFeedbackQuestion => 'Bagaimana hasil analisis ini?';

  @override
  String get feedbackCorrect => 'Benar';

  @override
  String get feedbackWrong => 'Salah';

  @override
  String get feedbackUnknown => 'Belum tahu';

  @override
  String get feedbackNoteOptional => 'Catatan feedback (opsional)';

  @override
  String get send => 'Kirim';

  @override
  String get feedbackThanks => 'Terima kasih atas feedback kamu!';

  @override
  String get feedbackSendFailed => 'Gagal mengirim feedback.';

  @override
  String get noteSaved => 'Catatan tersimpan.';

  @override
  String get noteDeleted => 'Catatan dihapus.';

  @override
  String get noteSaveFailed => 'Catatan gagal disimpan.';

  @override
  String get tradingPlanTitle => 'Suggested Levels';

  @override
  String get tradingPlanDisclaimer =>
      'Harga entry / stop / target konkret untuk skenario buy dan sell — berdasarkan harga saat analisis dibuat.';

  @override
  String suggestedSide(String side) {
    return 'Sisi yang disarankan: $side';
  }

  @override
  String get buyScenario => 'Skenario Buy';

  @override
  String get sellScenario => 'Skenario Sell';

  @override
  String get waitLabel => 'Tunggu';

  @override
  String get takeProfit1 => 'Take Profit 1';

  @override
  String get takeProfit2 => 'Take Profit 2';

  @override
  String get riskReward => 'Risiko : Imbalan';

  @override
  String get rationale => 'Alasan';

  @override
  String get copyLevels => 'Salin level';

  @override
  String get levelsCopied => 'Level disalin';

  @override
  String get levelsCopyFailed => 'Level gagal disalin.';

  @override
  String get marketEvidence => 'Bukti pasar';

  @override
  String get marketEvidenceDescription =>
      'Snapshot market dan konteks fundamental.';

  @override
  String get supportingData => 'Konteks fundamental';

  @override
  String fundamentalEvidenceSummary(int news, int events) {
    return '$news berita · $events event ekonomi';
  }

  @override
  String get notesAndJournal => 'Catatan & jurnal';

  @override
  String get notesAndJournalDescription =>
      'Gunakan jurnal untuk keputusan dan hasil trade; gunakan catatan pribadi untuk pengingat khusus analisis ini.';

  @override
  String get learnAnalysisBasics => 'Pelajari dasar analisis';

  @override
  String get learnBiasConfidence => 'Bias, keyakinan, dan masa berlaku';

  @override
  String get learnTechnicalFundamental => 'Bukti teknikal dan fundamental';

  @override
  String get technicalDetails => 'Indikator teknikal';

  @override
  String get technicalDetailsDescription =>
      'Ringkasan sinyal live dan indikator mentah.';

  @override
  String get providedContext => 'Konteks yang kamu berikan';

  @override
  String get analysisInvalidationTitle => 'Analisis ini batal jika';

  @override
  String get mainScenario => 'Skenario A — Utama';

  @override
  String get alternativeScenario => 'Skenario B — Alternatif';

  @override
  String get waitScenario => 'Skenario C — Tunggu / Tanpa Posisi';

  @override
  String get scenariosTitle => 'Skenario';

  @override
  String get waitScenarioBody =>
      'Jika konfirmasi belum kuat atau kondisi pembatal mendekat, menunggu setup yang lebih bersih adalah pilihan paling konservatif.';

  @override
  String get technicalDrivers => 'Penggerak Teknikal';

  @override
  String get fundamentalDrivers => 'Penggerak Fundamental';

  @override
  String get proAnalysisDetailsTitle => 'Kenapa analisis ini?';

  @override
  String get proAnalysisDetailsDescription =>
      'Buka untuk melihat faktor di balik kesimpulan AI.';

  @override
  String get analysisRationaleContext => 'Alasan & konteks AI';

  @override
  String get analysisHelpfulQuestion => 'Apakah analisis ini membantu?';

  @override
  String get helpful => 'Membantu';

  @override
  String get notHelpful => 'Kurang Membantu';

  @override
  String get analysisSafetyDisclaimerTitle =>
      'Bukan rekomendasi investasi. Trading mengandung risiko.';

  @override
  String get analysisSafetyDisclaimer =>
      'TradePilot adalah alat pendukung keputusan, bukan saran keuangan atau jaminan profit. Selalu kelola risiko dan jangan membuka posisi hanya berdasarkan satu indikator.';

  @override
  String get journalCreateForTrade => 'Catat trade ini';

  @override
  String get journalEntryForTrade => 'Catatan trade saya';

  @override
  String get journalReflectionHint =>
      'Simpan keputusan dan hasil trade untuk refleksi.';

  @override
  String get priceLevelAlerts => 'Alert harga';

  @override
  String get priceLevelAlertsDescription =>
      'Dapatkan notifikasi saat harga menyentuh level Entry, Stop Loss, atau Take Profit dari AI.';

  @override
  String priceLevelAlertsOn(int count) {
    return 'Alert: AKTIF · $count level dipantau';
  }

  @override
  String get priceLevelAlertsOff => 'Alert: NONAKTIF';

  @override
  String get changeTimeframe => 'Ganti Timeframe';

  @override
  String get changeTimeframeDescription =>
      'Memilih timeframe lain langsung memulai analisis baru untuk instrumen ini.';

  @override
  String get analysisUsesFreeQuota => 'Sumber: kuota analisis gratis';

  @override
  String get analysisUsesOneCredit => 'Sumber: 1 credit (kuota gratis habis)';

  @override
  String get analysisUsageUnavailable =>
      'Sumber pemakaian akan dipastikan sebelum permintaan diproses';

  @override
  String get selectedAnalysisMarket => 'Pasar yang dianalisis';

  @override
  String get changeSelection => 'Ubah';

  @override
  String get priceChart => 'Grafik Harga';

  @override
  String get openFullChart => 'Lihat chart lengkap di TradingView';

  @override
  String get fundamentalContext => 'Konteks Fundamental';

  @override
  String get refreshFundamentals => 'Refresh fundamental';

  @override
  String get fundamentalContextDescription =>
      'Berita dan event ekonomi yang dilihat AI saat membuat analisis ini.';

  @override
  String get liveTechnicalIndicators => 'Indikator Teknikal Live';

  @override
  String get liveTechnicalDisclaimer =>
      'Data terbaru; dapat berbeda dari snapshot saat analisis dibuat.';

  @override
  String get lastBar => 'Bar terakhir';

  @override
  String get twentyBars => '20 bar';

  @override
  String get signalSummary => 'Ringkasan sinyal';

  @override
  String technicalDataPoints(String timeframe, int count) {
    return 'Data $timeframe · $count candle';
  }

  @override
  String get beginnerBullish => 'Cenderung Naik';

  @override
  String get beginnerBearish => 'Cenderung Turun';

  @override
  String get beginnerWait => 'Tunggu Dulu';

  @override
  String biasMeaning(String bias, String direction) {
    return 'Bias $bias berarti AI melihat kecenderungan market yang $direction.';
  }

  @override
  String get directionUp => 'lebih condong naik';

  @override
  String get directionDown => 'lebih condong turun';

  @override
  String get directionNeutral => 'belum mempunyai arah dominan';

  @override
  String get beginnerBuyAction =>
      'Struktur analisis lebih mendukung skenario Buy, tetapi entry tetap harus menunggu area dan kondisi yang dijelaskan di rencana trading.';

  @override
  String get beginnerSellAction =>
      'Struktur analisis lebih mendukung skenario Sell, tetapi entry tetap harus mengikuti area dan batas risiko yang sudah ditentukan.';

  @override
  String get beginnerWaitAction =>
      'AI belum melihat entry yang cukup kuat. Untuk pemula, menunggu konfirmasi adalah keputusan yang valid.';

  @override
  String get marketContextSummaryTitle => 'RINGKASAN KONTEKS PASAR';

  @override
  String get marketContextLeaningBullish => 'Cenderung Bullish';

  @override
  String get marketContextLeaningBearish => 'Cenderung Bearish';

  @override
  String get marketContextLeaningNeutral => 'Netral / Campuran';

  @override
  String marketContextIndicatorSummaryBullish(
    int bullish,
    int total,
    int bearish,
    int neutral,
  ) {
    return '$bullish dari $total indikator cenderung bullish, sementara $bearish cenderung bearish dan $neutral netral. Data saat ini condong ke skenario kenaikan — konfirmasi dengan price action sebelum mengambil keputusan.';
  }

  @override
  String marketContextIndicatorSummaryBearish(
    int bearish,
    int total,
    int bullish,
    int neutral,
  ) {
    return '$bearish dari $total indikator cenderung bearish, sementara $bullish cenderung bullish dan $neutral netral. Data saat ini condong ke skenario penurunan — konfirmasi dengan price action sebelum mengambil keputusan.';
  }

  @override
  String marketContextIndicatorSummaryNeutral(
    int total,
    int bullish,
    int bearish,
    int neutral,
  ) {
    return 'Dari $total indikator, $bullish cenderung bullish, $bearish cenderung bearish, dan $neutral netral. Buktinya masih campuran — tunggu price action yang lebih jelas sebelum mengambil keputusan.';
  }

  @override
  String get analysisSnapshotTitle => 'Konteks Saat Analisis Dibuat';

  @override
  String get analysisSnapshotDescription =>
      'Bagian ini adalah snapshot data yang AI gunakan saat membuat analisis.';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String get chartScenarioBoth => 'Keduanya';

  @override
  String get opportunity => 'Peluang';

  @override
  String get executionInsight => 'Bagaimana trader biasanya merespons';

  @override
  String get executionInsightDescription =>
      'Gambaran cara trader biasanya menyikapi tiap skenario, tanpa level Entry, Stop Loss, atau Take Profit spesifik.';

  @override
  String get executionScenarioALabel => 'Jika Skenario A berlanjut';

  @override
  String get executionScenarioABullish =>
      'Trader biasanya mencari peluang Buy di support terdekat, lalu keluar jika harga break ke bawah area tersebut.';

  @override
  String get executionScenarioABearish =>
      'Trader biasanya mencari peluang Sell di resistance terdekat, lalu keluar jika harga break ke atas area tersebut.';

  @override
  String get executionScenarioANeutral =>
      'Karena bias netral, banyak trader memilih menunggu sampai ada break yang jelas dari range saat ini.';

  @override
  String get executionScenarioBLabel => 'Jika Skenario B yang terjadi';

  @override
  String get executionScenarioBBody =>
      'Jika asumsi utama salah dan skenario alternatif yang berjalan, biasanya trader mengevaluasi ulang tesis dari awal — bukan langsung membalik posisi.';

  @override
  String get executionScenarioCLabel => 'Jika lebih baik menunggu';

  @override
  String get executionScenarioCBody =>
      'Tunggu sampai kondisi pembatal di atas tidak lagi berisiko, atau sampai muncul konfluensi sinyal yang lebih kuat.';

  @override
  String get riskHighLabel => 'High Risk';

  @override
  String get riskLowLabel => 'Low Risk';

  @override
  String get riskModerateLabel => 'Medium Risk';

  @override
  String get riskHighProGuidance =>
      'Volatilitas tinggi. Batasi eksposur dan gunakan level invalidasi sebagai batas risiko.';

  @override
  String get riskHighBeginnerGuidance =>
      'Pergerakan dapat lebih agresif. Hindari ukuran posisi besar dan jangan mengabaikan Stop Loss.';

  @override
  String get riskLowGuidance =>
      'Kondisi terlihat lebih stabil, tetapi risiko tetap ada. Tetap gunakan batas kerugian.';

  @override
  String get riskModerateGuidance =>
      'Ada peluang sekaligus ketidakpastian. Tunggu setup yang jelas dan gunakan ukuran posisi yang terukur.';

  @override
  String get reanalyze => 'Analisis ulang';

  @override
  String get useForNewAnalysis => 'Gunakan untuk analisis baru';

  @override
  String get basicFilters => 'Filter dasar';

  @override
  String get saveBasicFilter => 'Simpan filter dasar';

  @override
  String get basicFilterExplanation =>
      'Menyimpan pencarian, mode, instrumen, timeframe, dan rentang tanggal. Status evaluasi belum didukung oleh preset backend.';

  @override
  String get history => 'Riwayat';

  @override
  String get historyPageTitle => 'Riwayat & Performa Analisis';

  @override
  String historyTotalAnalyses(int count) {
    return '$count analisis total';
  }

  @override
  String get profile => 'Profil';

  @override
  String get profilePrivacySecurity => 'Privasi & Keamanan';

  @override
  String get profilePrivacySecuritySubtitle =>
      'Kelola privasi dan penghapusan akun';

  @override
  String get profileMyAlerts => 'Alert Saya';

  @override
  String get profileMyAlertsSubtitle => 'Lihat dan kelola alert harga kamu.';

  @override
  String get profileNotificationSettings => 'Pengaturan Notifikasi';

  @override
  String get profileNotificationSettingsSubtitle =>
      'Pilih push notification, jenis notifikasi, dan ringkasan harian.';

  @override
  String get profileAnalysisCredits => 'Kredit Analisis';

  @override
  String get account => 'Akun';

  @override
  String get profileInformation => 'Informasi Profil';

  @override
  String get changeDisplayName => 'Ubah nama tampilan';

  @override
  String get preferences => 'Preferensi';

  @override
  String get language => 'Bahasa';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get darkTheme => 'Tema gelap';

  @override
  String get appearance => 'Tema Tampilan';

  @override
  String get lightMode => 'Terang';

  @override
  String get darkMode => 'Gelap';

  @override
  String get roleUser => 'Pengguna';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleSuperAdmin => 'Super Admin';

  @override
  String get darkThemeEnabled => 'Aktif • nyaman saat cahaya redup';

  @override
  String get darkThemeDisabled => 'Nonaktif • menggunakan tampilan terang';

  @override
  String get analysisMode => 'Mode analisis';

  @override
  String get proModeDescription => 'Saat ini: Pro • detail teknikal lengkap';

  @override
  String get beginnerModeDescription =>
      'Saat ini: Pemula • penjelasan lebih sederhana';

  @override
  String get security => 'Keamanan';

  @override
  String get changePassword => 'Ganti Password';

  @override
  String get securityQuestion => 'Pertanyaan Keamanan';

  @override
  String get changeSecurityQuestion => 'Ubah Pertanyaan Keamanan';

  @override
  String get newSecurityAnswer => 'Jawaban keamanan baru';

  @override
  String get securityQuestionUpdated => 'Pertanyaan keamanan berhasil diubah.';

  @override
  String get notAvailable => 'Tidak tersedia';

  @override
  String get legalAndHelp => 'Legal & Bantuan';

  @override
  String get privacyPolicy => 'Kebijakan Privasi';

  @override
  String get appFooterDisclaimer =>
      'TradePilot adalah alat pendukung keputusan, bukan saran keuangan atau layanan trading.';

  @override
  String get sponsoredBy => 'Disponsori oleh';

  @override
  String get newsDataVia => 'Data berita via newsmaker.id';

  @override
  String get marketNews => 'Berita pasar';

  @override
  String get recentNews => 'Berita Terkini';

  @override
  String get publishedJustNow => 'Baru saja';

  @override
  String publishedMinutesAgo(int count) {
    return '$count menit lalu';
  }

  @override
  String publishedHoursAgo(int count) {
    return '$count jam lalu';
  }

  @override
  String publishedDaysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String get pauseTicker => 'Jeda ticker';

  @override
  String get resumeTicker => 'Lanjutkan ticker';

  @override
  String get hideTicker => 'Sembunyikan ticker';

  @override
  String get showTicker => 'Tampilkan ticker';

  @override
  String get termsOfService => 'Syarat Layanan';

  @override
  String get support => 'Bantuan';

  @override
  String get deleteAccount => 'Hapus Akun';

  @override
  String get linkOpenFailed => 'Tautan tidak dapat dibuka.';

  @override
  String get insightsAndJournal => 'Insight & Jurnal';

  @override
  String get tradeJournal => 'Jurnal Trading';

  @override
  String get journalLoadFailed => 'Jurnal belum dapat dimuat. Coba lagi.';

  @override
  String get journalSaveFailed => 'Entri jurnal gagal disimpan.';

  @override
  String get journalDeleteTitle => 'Hapus entri jurnal?';

  @override
  String get journalDeleteWarning => 'Tindakan ini tidak dapat dibatalkan.';

  @override
  String get journalDeleteFailed => 'Entri jurnal gagal dihapus.';

  @override
  String get journalSessionChanged => 'Sesi berubah. Buka kembali halaman ini.';

  @override
  String get add => 'Tambah';

  @override
  String get noJournalEntries => 'Belum ada entri jurnal.';

  @override
  String get journalOutcomeFilter => 'Filter outcome';

  @override
  String get open => 'Terbuka';

  @override
  String get breakeven => 'Impas';

  @override
  String get skippedTrade => 'Tidak diambil';

  @override
  String get journalPrivateLimit =>
      'Maksimum 100 entri terbaru dari server. Data ini bersifat pribadi.';

  @override
  String get edit => 'Edit';

  @override
  String get addJournal => 'Tambah jurnal';

  @override
  String get editJournal => 'Edit jurnal';

  @override
  String get instrumentRequired => 'Instrumen wajib diisi.';

  @override
  String get side => 'Sisi';

  @override
  String get buyJournalSide => 'Buy (catatan transaksi)';

  @override
  String get sellJournalSide => 'Sell (catatan transaksi)';

  @override
  String get retrospectiveStatus => 'Status retrospektif';

  @override
  String get tradeTime => 'Waktu transaksi';

  @override
  String get moodOptional => 'Kondisi diri (opsional)';

  @override
  String get reflectionOptional => 'Refleksi (opsional)';

  @override
  String get enterValidNumber => 'Masukkan angka yang valid.';

  @override
  String get entries => 'Entri';

  @override
  String get wins => 'Menang';

  @override
  String get losses => 'Kalah';

  @override
  String get averageProfitLoss => 'Rata-rata P/L';

  @override
  String get quantity => 'Jumlah';

  @override
  String get tradeJournalDescription => 'Catatan dan refleksi trading pribadi';

  @override
  String get analytics => 'Analitik';

  @override
  String get publicAiPerformance => 'Kinerja AI Publik';

  @override
  String get performanceMethodology => 'Metodologi';

  @override
  String get performanceDescription =>
      'Rekam jejak anonim seluruh analisis AI TradePilot. Ini bukan statistik akun pribadi.';

  @override
  String performanceDays(int count) {
    return '$count hari';
  }

  @override
  String performanceInsufficient(int need, int have) {
    return 'Data belum cukup untuk ditampilkan secara bertanggung jawab. Butuh $need hasil; saat ini $have.';
  }

  @override
  String performanceSampleProgress(int have, int need) {
    return '$have dari $need sampel terkumpul';
  }

  @override
  String get otherInstruments => 'Instrumen Lainnya';

  @override
  String get performanceByInstrument => 'Performa berdasarkan instrumen';

  @override
  String get performanceBySession => 'Per sesi pasar';

  @override
  String get performanceByCondition => 'Per kondisi pasar';

  @override
  String get performanceByVolatility => 'Per volatilitas';

  @override
  String get performanceNewsActivity => 'Aktivitas berita';

  @override
  String get performanceMethodologyTitle => 'Metodologi kinerja';

  @override
  String get performanceMethodWhatTitle => 'Apa yang dihitung';

  @override
  String get performanceMethodWhatBody =>
      'Hanya analisis yang hasilnya sudah terselesaikan. Data pengguna dianonimkan dan digabung.';

  @override
  String get performanceMethodRatesTitle => 'Win rate dan hit rate';

  @override
  String get performanceMethodRatesBody =>
      'Win rate membandingkan menang dengan kalah pada trade yang terpicu. Hit rate juga memasukkan analisis kedaluwarsa.';

  @override
  String get performanceMethodSampleTitle => 'Batas sampel';

  @override
  String get performanceMethodSampleBody =>
      'Segmen dengan sampel kecil disembunyikan agar tidak menyesatkan atau membocorkan aktivitas kelompok kecil.';

  @override
  String get performanceMethodExcludedTitle => 'Yang tidak termasuk';

  @override
  String get performanceMethodExcludedBody =>
      'Angka tidak memperhitungkan ukuran posisi, spread, slippage, biaya, pajak, atau keputusan eksekusi pengguna.';

  @override
  String get performancePastDisclaimer =>
      'Kinerja masa lalu tidak menjamin hasil berikutnya.';

  @override
  String get performanceDeclining => 'Kinerja terbaru menurun';

  @override
  String get performanceWatch => 'Kinerja terbaru perlu dipantau';

  @override
  String get performanceStable => 'Kinerja terbaru stabil';

  @override
  String performanceRecentBaseline(int days, String recent, String baseline) {
    return '$days hari terbaru: $recent · baseline: $baseline.';
  }

  @override
  String performanceSummary(int days) {
    return 'Ringkasan $days hari';
  }

  @override
  String get winRate => 'Win rate';

  @override
  String get hitRate => 'Hit rate';

  @override
  String performanceTotals(int wins, int losses, int expired, int total) {
    return '$wins menang · $losses kalah · $expired kedaluwarsa · $total sampel';
  }

  @override
  String sinceDate(String date) {
    return 'Sejak $date';
  }

  @override
  String performanceSegmentInsufficient(int have, int need) {
    return 'Data belum cukup: $have/$need sampel.';
  }

  @override
  String performanceBucketTotals(int wins, int losses, int expired) {
    return '$wins menang · $losses kalah · $expired kedaluwarsa';
  }

  @override
  String get performanceLoadFailed => 'Data kinerja belum dapat dimuat.';

  @override
  String get offMainSession => 'Di luar sesi utama';

  @override
  String get uptrend => 'Tren naik';

  @override
  String get downtrend => 'Tren turun';

  @override
  String get activeNewsWeek => 'Minggu aktif berita';

  @override
  String get quietWeek => 'Minggu tenang';

  @override
  String get rangingMarket => 'Ranging';

  @override
  String get volatileMarket => 'Volatil';

  @override
  String get choppyMarket => 'Choppy';

  @override
  String get analyticsDescription => 'Pola aktivitas dan hasil evaluasi';

  @override
  String get dailySummary => 'Ringkasan Harian';

  @override
  String get traderMirror => 'Cermin Trader';

  @override
  String get traderMirrorDescription => 'Refleksi kebiasaan berbasis data';

  @override
  String get traderMindset => 'Mindset Trader';

  @override
  String get traderMindsetDescription =>
      'Pelajaran singkat untuk keputusan disiplin';

  @override
  String get guide => 'Pusat Panduan';

  @override
  String get guideNavLabel => 'Panduan';

  @override
  String get back => 'Kembali';

  @override
  String get guideDescription =>
      'Panduan fitur, analisis, risiko, dan disiplin trading';

  @override
  String get mentalChecklistPreference => 'Checklist mental pra-analisis';

  @override
  String get mentalChecklistPreferenceHint =>
      'Tampilkan empat pengingat disiplin sebelum membuat analisis';

  @override
  String get mentalChecklistTitle => 'Cek mental sebelum trade';

  @override
  String get mentalChecklistRisk =>
      'Gw tau persis berapa loss kalau trade ini gagal';

  @override
  String get mentalChecklistPlan =>
      'Gw punya entry, stop-loss, dan target — tertulis, bukan di kepala doang';

  @override
  String get mentalChecklistChase =>
      'Gw nggak ngejar pergerakan yang sudah jalan (bukan FOMO)';

  @override
  String get mentalChecklistCalm =>
      'Gw nggak trade buat balas dendam loss sebelumnya';

  @override
  String get mentalChecklistHint =>
      'Centang keempatnya sebelum klik Analisis. Cuma reminder, bukan blocker — tapi yang nggak dicentang biasanya jadi awal loss.';

  @override
  String get safeWait => 'Tahan Diri (Wait)';

  @override
  String get safeWaitHint =>
      'Pahami risikonya dan menepi sejenak. Disiplin yang bagus.';

  @override
  String get safeWaitRecorded => 'Keputusan menunggu berhasil dicatat.';

  @override
  String get safeWaitFailed =>
      'Keputusan menunggu tidak dapat disimpan. Coba lagi.';

  @override
  String get coolingOffBreathingTitle => 'Tarik napas dulu';

  @override
  String coolingOffBreathingBody(String loss) {
    return 'Kamu baru loss $loss%. Ikuti pola napas ini sebelum memilih. Setup-nya tidak ke mana-mana.';
  }

  @override
  String get coolingOffBreathingBodyGeneric =>
      'Ikuti pola napas ini sebelum memilih. Setup-nya tidak ke mana-mana.';

  @override
  String get coolingOffBreathingInhale => 'Tarik napas';

  @override
  String get coolingOffBreathingHold => 'Tahan';

  @override
  String get coolingOffBreathingExhale => 'Buang napas';

  @override
  String get coolingOffBreathingWait => 'Tunggu dulu';

  @override
  String get coolingOffBreathingContinue => 'Lanjut saja';

  @override
  String xpAwarded(int xp, String activity) {
    return '+$xp XP untuk $activity';
  }

  @override
  String get checklistActivity => 'menyelesaikan checklist pra-analisis';

  @override
  String get guideComplete => 'Tandai selesai';

  @override
  String get guideReading => 'Baca materi sampai tombol selesai aktif.';

  @override
  String get guideProgressFailed => 'Progres panduan tidak dapat disimpan.';

  @override
  String get openFullExplanation => 'Buka penjelasan lengkap';

  @override
  String get learnAdaptivePosition => 'Pelajari Rekomendasi Ukuran Posisi';

  @override
  String get sponsoredBySolidPrime => 'Disponsori oleh SOLID PRIME';

  @override
  String get sponsorDisclosure =>
      'Tautan sponsor tidak memengaruhi independensi analisis dan bukan rekomendasi untuk membuka akun atau bertransaksi.';

  @override
  String get openSponsorWebsite => 'Buka situs sponsor';

  @override
  String get liveAnalysisTitle => 'Live Analisa';

  @override
  String get liveAnalysisSponsorSubtitle =>
      'Setiap hari kerja pukul 09.00 WIB di TikTok @solid.prime';

  @override
  String get progressionTitle => 'Progression';

  @override
  String get progressionSubtitle =>
      'Rekam jejak pribadi untuk persiapan, refleksi, dan disiplin.';

  @override
  String get progressionLoading => 'Memuat data kedisiplinan...';

  @override
  String get progressionLoadFailed => 'Gagal memuat data kedisiplinan.';

  @override
  String get progressionOverview => 'Ringkasan';

  @override
  String get progressionAchievements => 'Pencapaian';

  @override
  String get progressionHistory => 'Riwayat XP';

  @override
  String get progressionCurrentStreak => 'Streak aktif';

  @override
  String get progressionLongestStreak => 'Streak terpanjang';

  @override
  String progressionLevel(int level) {
    return 'Level $level';
  }

  @override
  String progressionMastery(int level) {
    return 'Mastery $level';
  }

  @override
  String progressionRank(String rank) {
    return 'Rank: $rank';
  }

  @override
  String progressionXpToNext(int xp) {
    return '$xp XP menuju level berikutnya';
  }

  @override
  String progressionUnlocked(String date) {
    return 'Terbuka $date';
  }

  @override
  String get progressionLocked => 'Terkunci';

  @override
  String get progressionNoAchievements =>
      'Selesaikan aktivitas untuk membuka pencapaian.';

  @override
  String get progressionNoHistory =>
      'Belum ada aktivitas. Mulai bangun rutinitas kedisiplinanmu.';

  @override
  String get progressionPrivate =>
      'Progress ini privat. XP menghargai proses, bukan profit, win rate, atau besar modal.';

  @override
  String progressionActivity(int xp, String reason) {
    return '+$xp XP karena $reason';
  }

  @override
  String get mindsetDisclaimer =>
      'Materi edukasi saja. Bukan nasihat finansial atau psikologis.';

  @override
  String get signOut => 'Keluar';

  @override
  String get signOutConfirmation => 'Yakin ingin keluar dari akun ini?';

  @override
  String get cancel => 'Batal';

  @override
  String get permanentAction => 'Tindakan ini bersifat permanen';

  @override
  String get deleteAccountWarning =>
      'Profil, analisis, jurnal, watchlist, dan data akunmu akan dihapus dan tidak dapat dipulihkan.';

  @override
  String get currentPassword => 'Password Saat Ini';

  @override
  String get showPassword => 'Tampilkan password';

  @override
  String get hidePassword => 'Sembunyikan password';

  @override
  String get deleteAccountAcknowledgement =>
      'Saya memahami bahwa akun dan data saya akan dihapus secara permanen.';

  @override
  String get deleteAccountPermanently => 'Hapus Akun Permanen';

  @override
  String get editProfile => 'Edit Profil';

  @override
  String get displayName => 'Nama Tampilan';

  @override
  String get nameMinimumCharacters => 'Nama minimal 2 karakter';

  @override
  String get nameTooLong => 'Nama terlalu panjang';

  @override
  String get email => 'Email';

  @override
  String get emailChangeUnsupported => 'Perubahan email belum didukung.';

  @override
  String get save => 'Simpan';

  @override
  String get profileUpdated => 'Profil berhasil diperbarui.';

  @override
  String get changePhoto => 'Ganti foto';

  @override
  String get avatarRequirements =>
      'Gunakan gambar JPG, PNG, WebP, atau GIF maksimal 5 MB.';

  @override
  String get avatarUploadFailed => 'Foto profil gagal diunggah.';

  @override
  String get passwordChanged => 'Password berhasil diubah.';

  @override
  String get newPassword => 'Password Baru';

  @override
  String get confirmNewPassword => 'Konfirmasi Password Baru';

  @override
  String get currentPasswordRequired => 'Password saat ini wajib diisi';

  @override
  String get passwordMinimumCharacters => 'Password minimal 8 karakter';

  @override
  String get passwordConfirmationMismatch => 'Konfirmasi password tidak cocok';

  @override
  String get welcomeBack => 'Selamat Datang';

  @override
  String get loginDescription => 'Masuk untuk melanjutkan analisis';

  @override
  String get onboardingEyebrow => 'Universe comes to us';

  @override
  String get onboardingTitle => 'Insight pasar, bukan sinyal buta.';

  @override
  String get onboardingDescription =>
      'Asisten trading berbasis AI untuk membantu kamu membaca bias, risiko, serta konteks teknikal dan fundamental dengan lebih terstruktur.';

  @override
  String get onboardingStructuredAnalysis =>
      'Analisis teknikal dan fundamental dalam satu alur';

  @override
  String get onboardingPrimaryAction => 'Mulai analisis pertamamu';

  @override
  String get onboardingSecondaryAction => 'Sudah punya akun? Masuk';

  @override
  String get usernameEmail => 'Username / Email';

  @override
  String get usernameEmailHint => 'Username atau email kamu';

  @override
  String get emailHint => 'kamu@email.com';

  @override
  String get invalidEmail => 'Masukkan alamat email yang valid';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password wajib diisi';

  @override
  String get rememberMe => 'Selalu Ingat Saya';

  @override
  String get forgotPassword => 'Lupa password?';

  @override
  String get signIn => 'Masuk ke Dashboard';

  @override
  String get or => 'atau';

  @override
  String get orSignInWithEmail => 'atau masuk dengan email';

  @override
  String get secureSignIn => 'Login aman';

  @override
  String get continueWithGoogle => 'Lanjutkan dengan Google';

  @override
  String get continueWithApple => 'Lanjutkan dengan Apple';

  @override
  String get continueWithFacebook => 'Lanjutkan dengan Facebook';

  @override
  String get continueWithTikTok => 'Lanjutkan dengan TikTok';

  @override
  String socialSignInUnavailable(String provider) {
    return 'Login dengan $provider sedang tidak tersedia. Coba metode lain.';
  }

  @override
  String socialSignInFailed(String provider) {
    return 'Tidak dapat melanjutkan dengan $provider. Silakan coba lagi.';
  }

  @override
  String get socialEmailAlreadyRegistered =>
      'Email ini sudah terdaftar. Masuklah dengan metode yang sudah terhubung.';

  @override
  String get socialFacebookNoEmail =>
      'Akun Facebook kamu tidak punya email terdaftar. Coba metode login lain.';

  @override
  String get socialSignupExpired =>
      'Sesi pendaftaran TikTok kamu sudah kedaluwarsa. Silakan coba login TikTok lagi.';

  @override
  String get googleDeleteReauthDescription =>
      'Untuk melindungi akunmu, verifikasi identitas dengan Google sebelum penghapusan.';

  @override
  String get federatedDeleteReauthDescription =>
      'Untuk melindungi akunmu, verifikasi dengan metode masuk yang terhubung ke akun ini sebelum penghapusan.';

  @override
  String get verifyGoogleAndDelete => 'Verifikasi dengan Google dan hapus';

  @override
  String get verifyAppleAndDelete => 'Verifikasi dengan Apple dan hapus';

  @override
  String get errGoogleTokenInvalid =>
      'Google tidak dapat memverifikasi proses masuk ini. Pilih akun yang sama lalu coba lagi.';

  @override
  String get errGoogleAccountConflict =>
      'Email ini terhubung ke metode masuk lain. Masuklah dengan metode tersebut terlebih dahulu.';

  @override
  String get errGoogleUnavailable =>
      'Google Sign-In sedang tidak tersedia. Silakan coba lagi nanti.';

  @override
  String get errGoogleConfiguration =>
      'Google Sign-In belum dikonfigurasi untuk build aplikasi ini. Hubungi tim dukungan.';

  @override
  String get errGoogleSignInFailed =>
      'Gagal masuk dengan Google. Silakan coba lagi.';

  @override
  String get errAppleTokenInvalid =>
      'Apple tidak dapat memverifikasi proses masuk ini. Silakan coba lagi.';

  @override
  String get errAppleAccountConflict =>
      'Email ini terhubung ke metode masuk lain. Masuklah dengan metode tersebut terlebih dahulu.';

  @override
  String get errAppleUnavailable =>
      'Sign in with Apple belum tersedia. Silakan coba lagi nanti.';

  @override
  String get errAppleSignInFailed =>
      'Gagal masuk dengan Apple. Silakan coba lagi.';

  @override
  String get verifying => 'Memverifikasi...';

  @override
  String get signInWithBiometrics => 'Masuk dengan sidik jari / wajah';

  @override
  String get noAccount => 'Belum punya akun? ';

  @override
  String get register => 'Daftar gratis';

  @override
  String get biometricReason =>
      'Verifikasi identitasmu untuk masuk ke TradePilot';

  @override
  String get biometricUnavailable =>
      'Biometrik tidak tersedia. Gunakan email dan password.';

  @override
  String get createAccount => 'Buat Akun';

  @override
  String get startTradingJourney => 'Mulai perjalanan tradingmu';

  @override
  String get registerDescription => 'Daftar gratis dan mulai analisis';

  @override
  String get registerValueInsight => 'Insight pasar, bukan sinyal buta';

  @override
  String get registerValueFast =>
      'Mulai analisis pertama dalam beberapa langkah';

  @override
  String get registerValueRisk => 'Tahu persis kapan kamu salah';

  @override
  String get fullName => 'Nama Lengkap';

  @override
  String get nameRequired => 'Nama wajib diisi';

  @override
  String get minimumEightCharacters => 'Minimal 8 karakter';

  @override
  String get experienceLevel => 'Tingkat Pengalaman';

  @override
  String get beginner => 'Pemula';

  @override
  String get pro => 'Pro';

  @override
  String get beginnerModeHelp => 'Penjelasan lebih sederhana dan bertahap.';

  @override
  String get proModeHelp => 'Informasi pasar lebih ringkas dan teknis.';

  @override
  String get firstPetQuestion => 'Apa nama hewan peliharaan pertamamu?';

  @override
  String get answer => 'Jawaban';

  @override
  String get answerRequired => 'Jawaban wajib diisi';

  @override
  String get registerConsent => 'Dengan mendaftar, kamu menyetujui:';

  @override
  String get andLabel => 'dan';

  @override
  String get passwordResetSuccess => 'Password berhasil diubah. Silakan masuk.';

  @override
  String get forgotPasswordTitle => 'Lupa Password';

  @override
  String stepOfThree(int step) {
    return 'Langkah $step dari 3';
  }

  @override
  String get findYourAccount => 'Temukan akunmu';

  @override
  String get findAccountDescription =>
      'Masukkan email akun untuk memulai pemulihan password.';

  @override
  String get continueLabel => 'Lanjutkan';

  @override
  String get verifyIdentity => 'Verifikasi identitas';

  @override
  String get securityAnswerDescription =>
      'Jawab pertanyaan keamanan yang kamu buat saat mendaftar.';

  @override
  String get verify => 'Verifikasi';

  @override
  String get changeEmail => 'Ganti email';

  @override
  String get createNewPassword => 'Buat password baru';

  @override
  String get newPasswordDescription =>
      'Gunakan minimal 8 karakter dan jangan gunakan kembali password lama.';

  @override
  String get savePassword => 'Simpan Password';

  @override
  String get myPriceAlerts => 'Price Alert Saya';

  @override
  String get priceAlertsSubtitle => 'Alert harga yang sudah kamu pasang';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get markAllRead => 'Baca semua';

  @override
  String get realtimeActive => 'Realtime terhubung';

  @override
  String get realtimeConnecting => 'Menghubungkan realtime…';

  @override
  String get notificationInbox => 'Kotak Masuk';

  @override
  String get notificationSettingsTab => 'Pengaturan';

  @override
  String notificationUnreadCount(int count) {
    return '$count belum dibaca';
  }

  @override
  String get notificationAnalysisUnavailable =>
      'Analisis tidak tersedia atau kamu tidak memiliki akses.';

  @override
  String get mobilePush => 'Push Mobile';

  @override
  String get pushUpdatingDevice => 'Memperbarui pengaturan perangkat…';

  @override
  String get pushDeviceRegistered => 'Perangkat terdaftar untuk push.';

  @override
  String pushDeviceRegisteredLastReceived(String date) {
    return 'Perangkat terdaftar untuk push. Terakhir diterima $date.';
  }

  @override
  String get pushPermissionDenied =>
      'Izin ditolak. Aktifkan kembali melalui pengaturan perangkat.';

  @override
  String get pushReceiveWhenInactive =>
      'Terima push saat aplikasi tidak aktif.';

  @override
  String get sendTestPush => 'Kirim notifikasi tes';

  @override
  String pushTestConfirmed(int count) {
    return 'Notifikasi tes diterima di perangkat ini. FCM menerima $count pesan dari server.';
  }

  @override
  String get notificationPreferences => 'Preferensi Notifikasi';

  @override
  String get notificationPreferencesDescription =>
      'Pilih jenis pemberitahuan yang ingin kamu terima.';

  @override
  String get notificationPreferencesLoadFailed =>
      'Preferensi notifikasi belum dapat dimuat.';

  @override
  String get notificationExpiryTitle => 'Analisis kedaluwarsa';

  @override
  String get notificationExpiryDescription =>
      'Peringatan ketika masa berlaku analisis hampir selesai.';

  @override
  String get notificationBroadcastTitle => 'Pengumuman';

  @override
  String get notificationBroadcastDescription =>
      'Informasi dan broadcast penting dari TradePilot.';

  @override
  String get notificationDailyTitle => 'Ringkasan harian';

  @override
  String get notificationDailyDescription =>
      'Ringkasan aktivitas dan market harian.';

  @override
  String get notificationNewsTitle => 'Berita market';

  @override
  String get notificationNewsDescription =>
      'Berita penting yang relevan dengan market.';

  @override
  String get notificationCalendarTitle => 'Kalender ekonomi';

  @override
  String get notificationCalendarDescription =>
      'Pengingat event ekonomi berdampak tinggi.';

  @override
  String get notificationPriceTitle => 'Pergerakan harga';

  @override
  String get notificationPriceDescription =>
      'Anomali dan perubahan harga yang signifikan.';

  @override
  String get notificationSignalTitle => 'Perubahan sinyal';

  @override
  String get notificationSignalDescription =>
      'Ketika bias AI berubah secara bermakna.';

  @override
  String get notificationWeeklyTitle => 'Rekap mingguan';

  @override
  String get notificationWeeklyDescription =>
      'Ringkasan aktivitas trading setiap minggu.';

  @override
  String get notificationGuardrails => 'Guardrail keputusan';

  @override
  String get notificationRevengeTitle => 'Peringatan revenge trading';

  @override
  String get notificationRevengeDescription =>
      'Peringatan lunak setelah kerugian terbaru.';

  @override
  String get notificationOvertradingTitle => 'Peringatan overtrading';

  @override
  String get notificationOvertradingDescription =>
      'Peringatan saat jumlah analisis terlalu rapat.';

  @override
  String get notificationHighRiskTitle => 'Peringatan risiko tinggi';

  @override
  String get notificationHighRiskDescription =>
      'Peringatan event high-impact dalam 30 menit.';

  @override
  String get notificationCoolingOffTitle => 'Cooling-off 30 menit';

  @override
  String get notificationCoolingOffDescription =>
      'Jeda opsional setelah kerugian signifikan.';

  @override
  String get notificationSessionReminders => 'Pengingat Sesi Market';

  @override
  String get quietHours => 'Waktu tenang';

  @override
  String get quietHoursDescription =>
      'Tahan notifikasi non-darurat selama jam istirahat.';

  @override
  String get quietHoursStart => 'Mulai';

  @override
  String get quietHoursEnd => 'Selesai';

  @override
  String get notificationTimezone => 'Zona waktu';

  @override
  String get quietHoursSecurityNotice =>
      'Notifikasi keamanan tetap dapat dikirim selama waktu tenang.';

  @override
  String notificationAutoPaused(String category) {
    return 'Sebagian notifikasi ‘$category’ otomatis dijeda karena lama tidak dibuka.';
  }

  @override
  String get noNotifications => 'Belum ada notifikasi';

  @override
  String get trader => 'Trader';

  @override
  String get latestAnalyses => 'Analisis Terbaru';

  @override
  String get viewAll => 'Lihat semua';

  @override
  String get decisionDisclaimer =>
      'TradePilot membantu kamu memahami kondisi pasar, tetapi semua keputusan dan pengelolaan risiko tetap menjadi tanggung jawabmu.';

  @override
  String get wantMarketAnalysis => 'Ingin analisis pasar?';

  @override
  String get getStarted => 'Mulai menggunakan TradePilot';

  @override
  String get onboardingSteps =>
      'Pilih pasar, periksa konteks live, lalu buat analisis pertama. Hasil adalah alat bantu keputusan—bukan instruksi trading.';

  @override
  String get chooseMarketAndStartAnalysis => 'Pilih pasar dan mulai analisis';

  @override
  String get gotIt => 'Mengerti';

  @override
  String get liveMarkets => 'Pasar Live';

  @override
  String get analysisPreparation =>
      'Tinjau harga, sesi pasar, grafik, indikator, dan kalender ekonomi sebelum meminta analisis AI.';

  @override
  String get startAnalysis => 'Mulai Analisis';

  @override
  String get marketWatchlist => 'Watchlist Pasar';

  @override
  String get manageWatchlist => 'Kelola watchlist';

  @override
  String get watchlistDescription =>
      'Pantau pasar favoritmu tanpa membuka halaman lain.';

  @override
  String pricesUpdatedAt(String time) {
    return 'Harga diperbarui pukul $time';
  }

  @override
  String get livePriceUnavailable => 'Harga live tidak tersedia';

  @override
  String get createPriceAlert => 'Buat price alert';

  @override
  String get openAnalysis => 'Buka analisis';

  @override
  String get watchlistEmpty => 'Watchlist kamu masih kosong';

  @override
  String get addSymbol => 'Tambah simbol';

  @override
  String get totalAnalyses => 'Total Analisis';

  @override
  String get beginnerMode => 'Mode Pemula';

  @override
  String get proMode => 'Mode Pro';

  @override
  String get aiConfidence => 'Keyakinan AI';

  @override
  String get unlimitedAnalysisQuota => 'Kuota analisis tanpa batas';

  @override
  String get analysisQuota => 'Kuota Analisis';

  @override
  String get analysisQuotaLoadFailed => 'Kuota analisis belum dapat dimuat.';

  @override
  String get perDay => 'Per hari';

  @override
  String get noAnalyses => 'Belum ada analisis';

  @override
  String get createFirstAnalysis => 'Buat analisis pertamamu';

  @override
  String priceAlertCreated(String instrument) {
    return 'Price alert untuk $instrument berhasil dibuat.';
  }

  @override
  String instrumentAddedToWatchlist(String instrument) {
    return '$instrument ditambahkan ke watchlist.';
  }

  @override
  String instrumentAlreadyInWatchlist(String instrument) {
    return '$instrument sudah ada di watchlist.';
  }

  @override
  String get removeFromWatchlist => 'Hapus dari watchlist?';

  @override
  String removeInstrumentConfirmation(String instrument) {
    return 'Hapus $instrument dari watchlist?';
  }

  @override
  String get remove => 'Hapus';

  @override
  String instrumentRemovedFromWatchlist(String instrument) {
    return '$instrument dihapus dari watchlist.';
  }

  @override
  String removeInstrumentFailed(String instrument) {
    return 'Gagal menghapus $instrument.';
  }

  @override
  String get selectMarketsForDashboard =>
      'Pilih pasar yang ingin kamu pantau di Beranda.';

  @override
  String get close => 'Tutup';

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get watchlistUpdateFailed => 'Gagal memperbarui watchlist.';

  @override
  String watchlistUpdated(String instrument) {
    return 'Watchlist diperbarui untuk $instrument.';
  }

  @override
  String get alertNeedsLivePrice =>
      'Price alert memerlukan harga live. Harga live tidak tersedia untuk instrumen ini.';

  @override
  String get aiAnalysis => 'Analisis AI';

  @override
  String get analyzeTitle => 'Analisis Baru';

  @override
  String get otherInstrument => 'Instrumen lain…';

  @override
  String get quotaDay => 'Sisa kuota gratis';

  @override
  String get quotaDayShort => ' gratis';

  @override
  String get selectInstrument => 'Pilih Instrumen';

  @override
  String get instrumentCategoryCommoditiesIndices => 'Komoditas & Indeks';

  @override
  String get instrumentCategoryForex => 'Valas';

  @override
  String get instrumentCategoryCrypto => 'Kripto';

  @override
  String get assetTypeGold => 'Emas';

  @override
  String get assetTypeOil => 'Minyak';

  @override
  String get assetTypeIndex => 'Indeks';

  @override
  String get selectMarketDescription => 'Pilih pasar yang ingin kamu pahami.';

  @override
  String get tapToChangeInstrument => 'Ketuk untuk mengganti instrumen';

  @override
  String get timeframe => 'Timeframe';

  @override
  String get timeframeDescription =>
      'Timeframe menentukan sudut pandang analisis pasar.';

  @override
  String get priceAlertUnavailable => 'Price Alert Tidak Tersedia';

  @override
  String get instrumentHasNoLiveFeed =>
      'Instrumen ini tidak memiliki feed harga live yang dapat digunakan untuk alert.';

  @override
  String get additionalNotes => 'Catatan Tambahan';

  @override
  String get decisionGuardrails => 'Guardrail keputusan';

  @override
  String get guardrailHint =>
      'Ini peringatan lunak. Jeda dan evaluasi ulang sebelum lanjut.';

  @override
  String guardrailRevenge(String minutes) {
    return 'Kerugian terjadi $minutes menit lalu. Hindari revenge trading.';
  }

  @override
  String guardrailOvertrading(String count, String limit) {
    return 'Kamu membuat $count analisis; batas saat ini $limit.';
  }

  @override
  String guardrailHighRisk(String event, String minutes) {
    return '$event diperkirakan berlangsung sekitar $minutes menit lagi.';
  }

  @override
  String guardrailUnusualHour(String hour) {
    return 'Jam trading ini ($hour:00 UTC) tidak biasa dalam riwayat kamu.';
  }

  @override
  String guardrailCoolingOff(String minutes) {
    return 'Masa cooling-off tersisa sekitar $minutes menit.';
  }

  @override
  String get guardrailGeneric => 'Pola risiko terdeteksi.';

  @override
  String get additionalNotesDescription =>
      'Opsional. Jelaskan posisi atau kondisi yang ingin dipertimbangkan AI.';

  @override
  String get additionalNotesHint =>
      'Contoh: Saya belum memiliki posisi dan ingin menunggu entry yang lebih aman...';

  @override
  String get analyzingMarket => 'Menganalisis pasar...';

  @override
  String get getAiAnalysis => 'Dapatkan Analisis AI';

  @override
  String analysesRemainingToday(int count) {
    return 'Sisa $count analisis hari ini';
  }

  @override
  String get aiAnalysisDisclaimer =>
      'Analisis AI adalah alat bantu pengambilan keputusan, bukan jaminan profit. Selalu pertimbangkan risiko sebelum membuka posisi.';

  @override
  String get understandMarketBeforeEntry => 'Pahami pasar sebelum masuk';

  @override
  String get beginnerAnalysisIntro =>
      'TradePilot membantu menjelaskan harga, momentum, sesi pasar, dan peristiwa penting dengan bahasa yang lebih sederhana.';

  @override
  String get livePrice => 'Harga live';

  @override
  String get referencePrice => 'Harga referensi';

  @override
  String get addToWatchlist => 'Tambah ke watchlist';

  @override
  String get partialChartUnavailable => 'Sebagian data grafik tidak tersedia.';

  @override
  String get cryptoMarketAlwaysOpen => 'Pasar Kripto 24/7';

  @override
  String get cryptoNoForexSessions => 'Kripto tidak mengikuti sesi forex.';

  @override
  String get marketClosedWeekend => 'Pasar tutup pada akhir pekan';

  @override
  String get noMainSessionActive => 'Tidak ada sesi utama yang aktif';

  @override
  String get sessionOverlap =>
      'Sesi tumpang tindih • likuiditas biasanya lebih tinggi';

  @override
  String get marketSessionActive => 'Sesi pasar aktif';

  @override
  String sessionOpensIn(String session, String duration) {
    return '$session dibuka dalam $duration';
  }

  @override
  String sessionClosesIn(String session, String duration) {
    return '$session ditutup dalam $duration';
  }

  @override
  String get highImpactEventSoon =>
      'Peristiwa berdampak tinggi akan segera berlangsung';

  @override
  String get highImpactRisk =>
      'Harga dapat bergerak cepat dan spread dapat melebar.';

  @override
  String eventStartsInMinutes(int minutes) {
    return ' • sekitar $minutes menit lagi';
  }

  @override
  String get searchInstrumentOrNote => 'Cari catatan, instrumen, analisis AI…';

  @override
  String get clearSearch => 'Hapus pencarian';

  @override
  String get filter => 'Filter';

  @override
  String get noMatchingAnalyses => 'Tidak ada analisis yang cocok';

  @override
  String get changeSearchOrFilter => 'Coba ubah kata pencarian atau filter.';

  @override
  String get analysesAppearHere => 'Analisis AI kamu akan muncul di sini.';

  @override
  String get resetFilter => 'Atur ulang filter';

  @override
  String get modeBeginner => 'Mode: Pemula';

  @override
  String get modePro => 'Mode: Pro';

  @override
  String outcomeLabel(String outcome) {
    return 'Outcome: $outcome';
  }

  @override
  String confidenceAtLeast(int confidence) {
    return 'Keyakinan ≥ $confidence%';
  }

  @override
  String resultCount(int count) {
    return '$count hasil';
  }

  @override
  String get reset => 'Atur ulang';

  @override
  String get positive => 'Positif';

  @override
  String get negative => 'Negatif';

  @override
  String get pending => 'Menunggu';

  @override
  String get valid => 'Berlaku';

  @override
  String get expired => 'Kedaluwarsa';

  @override
  String analysisWindowActiveUntil(String date) {
    return 'Jendela analisis aktif hingga $date';
  }

  @override
  String analysisWindowExpiredAt(String date) {
    return 'Jendela analisis berakhir pada $date';
  }

  @override
  String analysisCreatedAt(String date) {
    return 'Dibuat $date';
  }

  @override
  String get historySummary => 'Ringkasan';

  @override
  String get historyListTab => 'Riwayat';

  @override
  String get historyFiltersButton => 'Filter';

  @override
  String get historyMetricTotal => 'Total analisis';

  @override
  String get historyMetricValid => 'Masih valid';

  @override
  String get historyMetricInvalid => 'Invalid';

  @override
  String get historyInsightConsistent => 'Timeframe paling konsisten';

  @override
  String get historyInsightExpired => 'Paling sering expired';

  @override
  String get historyInsightSl => 'Paling sering kena SL';

  @override
  String get historyNeedMoreSamples => 'Sampel belum cukup';

  @override
  String get historyInstrumentHint =>
      'Pilih instrumen untuk memfokuskan performa timeframe.';

  @override
  String get historyOtherInstrumentsHint =>
      'Gabungan riwayat instrumen di luar empat produk utama.';

  @override
  String get historyViewHistory => 'Lihat riwayat';

  @override
  String get historyTimeframePerformance => 'Performa per timeframe';

  @override
  String get historyRateExplainer =>
      'Win rate membandingkan TP dengan TP + SL. Setup expired hanya masuk ke completion rate.';

  @override
  String get historySampleShort => 'sampel';

  @override
  String historySampleCount(int count) {
    return '$count sampel';
  }

  @override
  String historySamplesNeeded(int remaining, int have, int need) {
    return 'Butuh $remaining lagi ($have/$need)';
  }

  @override
  String historyPageStatus(int page, int pages) {
    return 'Halaman $page dari $pages';
  }

  @override
  String historyRangeStatus(int start, int end, int total) {
    return 'Menampilkan $start–$end dari $total';
  }

  @override
  String get historyPrevious => 'Sebelumnya';

  @override
  String get historyNext => 'Selanjutnya';

  @override
  String get historyReanalyze => 'Analisis ulang';

  @override
  String get historyOutcomePending => 'Menunggu';

  @override
  String get historyOutcomeTp1 => 'TP1 Kena';

  @override
  String get historyOutcomeTp2 => 'TP2 Kena';

  @override
  String get historyOutcomeSl => 'SL Kena';

  @override
  String get historyMarketRanging => 'Ranging';

  @override
  String get timeframePerformance => 'Per timeframe';

  @override
  String get allTime => 'Semua waktu';

  @override
  String daysShort(int count) {
    return '${count}h';
  }

  @override
  String get partialSummary => 'Ringkasan sementara';

  @override
  String get visible => 'Terlihat';

  @override
  String get evaluated => 'Dievaluasi';

  @override
  String get averageConfidence => 'Keyakinan rata-rata';

  @override
  String positiveEvaluatedSummary(int rate) {
    return 'Target tercapai pada $rate% analisis yang sudah dievaluasi.';
  }

  @override
  String get hasJournalNote => 'Memiliki catatan jurnal';

  @override
  String confidenceValue(String value) {
    return 'Keyakinan $value';
  }

  @override
  String riskValue(String value) {
    return 'Risiko $value';
  }

  @override
  String get strongBullish => 'Bullish kuat';

  @override
  String get strongBearish => 'Bearish kuat';

  @override
  String get biasUnavailable => 'Bias belum tersedia';

  @override
  String get trendingUp => 'Tren naik';

  @override
  String get trendingDown => 'Tren turun';

  @override
  String get movingSideways => 'Bergerak sideways';

  @override
  String get trendingMarket => 'Sedang trending';

  @override
  String get evaluationPending => 'Menunggu evaluasi';

  @override
  String get referenceTargetOneHit => 'Target referensi 1 tercapai';

  @override
  String get referenceTargetTwoHit => 'Target referensi 2 tercapai';

  @override
  String get riskLimitHit => 'Batas risiko tersentuh';

  @override
  String get analysisPeriodEnded => 'Masa analisis berakhir';

  @override
  String get analysisCannotBeEvaluated => 'Analisis tidak dapat dievaluasi';

  @override
  String get notYetEvaluated => 'Belum dievaluasi';

  @override
  String get all => 'Semua';

  @override
  String get historyFilters => 'Filter Riwayat';

  @override
  String get mode => 'Mode';

  @override
  String get evaluationStatus => 'Status evaluasi';

  @override
  String get minimumConfidence => 'Keyakinan minimum';

  @override
  String get sortOrder => 'Urutan';

  @override
  String get instrument => 'Instrumen';

  @override
  String get dateRange => 'Rentang Tanggal';

  @override
  String get selectDate => 'Pilih tanggal';

  @override
  String get clearDateRange => 'Hapus rentang tanggal';

  @override
  String get applyFilters => 'Terapkan Filter';

  @override
  String get positiveOutcome => 'Outcome positif';

  @override
  String get negativeOutcome => 'Outcome negatif';

  @override
  String get newest => 'Terbaru';

  @override
  String get oldest => 'Terlama';

  @override
  String get highestConfidence => 'Keyakinan tertinggi';

  @override
  String get marketSession => 'Sesi Pasar';

  @override
  String get cryptoMarket247 => 'Pasar Kripto 24/7';

  @override
  String get marketClosed => 'Pasar tutup';

  @override
  String get activeUppercase => 'AKTIF';

  @override
  String get closedUppercase => 'TUTUP';

  @override
  String get liquidity => 'Likuiditas';

  @override
  String get next => 'Berikutnya';

  @override
  String get variesUppercase => 'BERVARIASI';

  @override
  String get highUppercase => 'TINGGI';

  @override
  String get mediumUppercase => 'SEDANG';

  @override
  String get lowUppercase => 'RENDAH';

  @override
  String get sessionOverlapActivity =>
      'Sesi yang tumpang tindih biasanya memiliki aktivitas pasar lebih tinggi.';

  @override
  String sessionTransition(String session, String action, String duration) {
    return '$session $action dalam $duration';
  }

  @override
  String get opens => 'dibuka';

  @override
  String get closes => 'ditutup';

  @override
  String get technicalSummary => 'Ringkasan Teknikal';

  @override
  String get indicatorEducationDisclaimer =>
      'Kami menyederhanakan indikator agar lebih mudah dipahami. Ini bukan sinyal atau rekomendasi trading.';

  @override
  String get technicalSummaryLoadFailed =>
      'Ringkasan teknikal tidak dapat dimuat.';

  @override
  String get technicalSummaryUnavailable =>
      'Ringkasan teknikal belum tersedia untuk pasar ini.';

  @override
  String get trend => 'Tren';

  @override
  String get momentum => 'Momentum';

  @override
  String get risk => 'Risiko';

  @override
  String get whatDoesItMean => 'Apa artinya?';

  @override
  String get marketContext => 'Konteks Pasar';

  @override
  String get marketEducationDisclaimer =>
      'Ringkasan edukatif tentang kondisi pasar saat ini. Ini bukan sinyal atau rekomendasi trading.';

  @override
  String get marketContextLoadFailed => 'Konteks pasar tidak dapat dimuat.';

  @override
  String get insufficientMarketData =>
      'Data belum cukup untuk menilai kondisi pasar.';

  @override
  String get why => 'Mengapa?';

  @override
  String get riskLevel => 'Tingkat risiko';

  @override
  String get economicCalendar => 'Kalender Ekonomi';

  @override
  String get economicEventRiskDisclaimer =>
      'Peristiwa ekonomi dapat membuat harga bergerak lebih cepat. Ini adalah informasi risiko, bukan sinyal trading.';

  @override
  String get economicCalendarLoadFailed =>
      'Kalender ekonomi tidak dapat dimuat.';

  @override
  String get noUpcomingEconomicEvents =>
      'Tidak ada peristiwa ekonomi relevan yang akan datang.';

  @override
  String get marketOverview => 'Ringkasan Pasar';

  @override
  String get priceDataUnavailable => 'Data harga tidak tersedia.';

  @override
  String get latestDataUnavailable => 'Data terbaru tidak tersedia.';

  @override
  String get waitingForUpdate => 'Menunggu pembaruan...';

  @override
  String get updatedJustNow => 'Baru saja diperbarui';

  @override
  String updatedSecondsAgo(int seconds) {
    return 'Diperbarui $seconds detik lalu';
  }

  @override
  String updatedAt(String time) {
    return 'Diperbarui pukul $time';
  }

  @override
  String get chartDataUnavailable => 'Data grafik tidak tersedia.';

  @override
  String get high => 'Tinggi';

  @override
  String get medium => 'Sedang';

  @override
  String get low => 'Rendah';

  @override
  String get bullishBias => 'Bias bullish';

  @override
  String get bearishBias => 'Bias bearish';

  @override
  String get neutral => 'Netral';

  @override
  String get historicalLevelsDisclaimer =>
      'Level grafik adalah referensi historis, bukan rekomendasi transaksi.';

  @override
  String get candlestickHelp =>
      'Candlestick: hijau = harga naik, merah = harga turun.';

  @override
  String movementRisk(String risk) {
    return 'Risiko pergerakan: $risk. Support dan resistance adalah level referensi dari data yang terlihat.';
  }

  @override
  String currentPrice(String price) {
    return 'Harga saat ini $price';
  }

  @override
  String get addInstrument => 'Tambah instrumen';

  @override
  String get searchInstrument => 'Cari instrumen';

  @override
  String get delete => 'Hapus';

  @override
  String addedOn(String date) {
    return 'Ditambahkan: $date';
  }

  @override
  String get noPreviousAnalysis => 'Belum ada analisis sebelumnya';

  @override
  String lastAnalysis(String date) {
    return 'Analisis terakhir: $date';
  }

  @override
  String get invalidTargetPrice => 'Masukkan harga target yang valid.';

  @override
  String get noteMaximumCharacters => 'Catatan maksimal 200 karakter.';

  @override
  String get priceAlertCreateFailed => 'Gagal membuat price alert.';

  @override
  String priceAlertTitle(String instrument) {
    return 'Price Alert $instrument';
  }

  @override
  String currentMarketPrice(String price) {
    return 'Harga pasar saat ini $price';
  }

  @override
  String get notifyWhenPrice => 'Beri tahu saya ketika harga...';

  @override
  String get risesAbove => 'Naik di atas';

  @override
  String get fallsBelow => 'Turun di bawah';

  @override
  String get targetPrice => 'Harga Target';

  @override
  String get optionalNote => 'Catatan (opsional)';

  @override
  String get priceAlertNoteHint => 'Contoh: tinjau kondisi pasar saat ini';

  @override
  String get saving => 'Menyimpan...';

  @override
  String get createPriceAlertButton => 'Buat Price Alert';

  @override
  String get myPriceAlertsTitle => 'Price Alert Saya';

  @override
  String get priceAlertDisclaimer =>
      'Price alert memberi tahu ketika kondisi tercapai. Ini bukan sinyal atau rekomendasi trading.';

  @override
  String get priceAlertsLoadFailed => 'Price alert tidak dapat dimuat.';

  @override
  String get noPriceAlerts =>
      'Belum ada price alert. Buat alert untuk menerima pemberitahuan saat harga mencapai level tertentu.';

  @override
  String get triggered => 'Terpicu';

  @override
  String get cancelled => 'Dibatalkan';

  @override
  String get monitored => 'Dipantau';

  @override
  String get active => 'Aktif';

  @override
  String get deleteAlert => 'Hapus alert';

  @override
  String get actual => 'Aktual';

  @override
  String get forecast => 'Perkiraan';

  @override
  String get previous => 'Sebelumnya';

  @override
  String get goldEventExplanation =>
      'Mengapa penting: data USD sering memengaruhi Emas dan dapat meningkatkan volatilitas XAU/USD.';

  @override
  String currencyEventExplanation(String currency, String instrument) {
    return 'Mengapa penting: peristiwa $currency berkaitan langsung dengan $instrument dan dapat meningkatkan volatilitas.';
  }

  @override
  String genericEventExplanation(String instrument) {
    return 'Mengapa penting: peristiwa ini dapat memengaruhi sentimen dan volatilitas $instrument.';
  }

  @override
  String get savedFilters => 'Filter tersimpan';

  @override
  String get saveCurrentFilter => 'Simpan filter saat ini';

  @override
  String get presetName => 'Nama filter';

  @override
  String get noSavedFilters => 'Belum ada filter tersimpan.';

  @override
  String get filterPresetSaved => 'Filter berhasil disimpan.';

  @override
  String get filterPresetFailed => 'Filter tersimpan tidak dapat diperbarui.';

  @override
  String get recentMarkets => 'Terakhir dianalisis';

  @override
  String get favoriteMarkets => 'Market favorit';

  @override
  String get outcomeSummary => 'Ringkasan outcome 30 hari';

  @override
  String get allHistorySummary => 'Ringkasan seluruh analisis';

  @override
  String get targetReached => 'Target tercapai';

  @override
  String get riskLimitTouched => 'Batas risiko tersentuh';

  @override
  String get periodEnded => 'Periode berakhir';

  @override
  String get cannotBeEvaluated => 'Tidak dapat dievaluasi';

  @override
  String get outcomeSummaryLoadFailed =>
      'Ringkasan outcome belum dapat dimuat.';

  @override
  String get targetHitRate => 'Target tercapai';

  @override
  String get stopHitRate => 'Batas risiko tersentuh';

  @override
  String resolvedSample(int count) {
    return '$count analisis terselesaikan';
  }

  @override
  String get appLocked => 'TradePilot terkunci';

  @override
  String get appLockedDescription =>
      'Sesimu masih aktif. Verifikasi identitasmu untuk melanjutkan.';

  @override
  String get unlock => 'Buka Kunci';

  @override
  String get biometricUnlockReason =>
      'Verifikasi identitasmu untuk membuka TradePilot';

  @override
  String get unlockFailed =>
      'Identitasmu tidak bisa diverifikasi. Coba lagi atau keluar.';

  @override
  String get biometricLock => 'Kunci biometrik';

  @override
  String get biometricLockOn =>
      'Minta sidik jari atau wajah saat app dibuka atau kembali setelah beberapa saat';

  @override
  String get biometricLockOff => 'Langsung terbuka ke dashboard';

  @override
  String get biometricLockUnavailable =>
      'Belum ada sidik jari atau face unlock di perangkat ini.';

  @override
  String get riskMapTitle => 'Peta Risiko Timeframe';

  @override
  String get riskMapButton => 'Compare Risk';

  @override
  String get riskMapDescription =>
      'Perbandingan ini menilai risiko teknikal saja. Risiko hasil analisis dapat berbeda karena faktor lain.';

  @override
  String get riskMapLoading => 'Memindai timeframe...';

  @override
  String get riskMapError => 'Gagal memuat peta risiko.';

  @override
  String get riskMapOverallWait => 'Secara keseluruhan: tunggu';

  @override
  String get riskMapOverallCompare => 'Bandingkan pilihan timeframe';

  @override
  String get riskMapRelativeNote =>
      'Peta ini menunjukkan risiko relatif, bukan jaminan profit.';

  @override
  String get riskLow => 'Risiko rendah';

  @override
  String get riskModerate => 'Risiko sedang';

  @override
  String get riskHigh => 'Risiko tinggi';

  @override
  String get riskUnavailable => 'Tidak tersedia';

  @override
  String get riskEligible => 'Layak';

  @override
  String get riskCaution => 'Hati-hati';

  @override
  String get riskWait => 'Tunggu';

  @override
  String get riskSelected => 'Terpilih';

  @override
  String useTimeframe(String timeframe) {
    return 'Gunakan & Analisis $timeframe';
  }

  @override
  String get standardRulesTitle => 'TP Standard Trading Rules';

  @override
  String get standardRulesDescription =>
      'Aturan broker-neutral yang menjadi dasar estimasi TradePilot.';

  @override
  String get standardRulesLoading => 'Memuat aturan trading standar...';

  @override
  String get standardRulesError =>
      'Aturan trading standar sedang tidak tersedia.';

  @override
  String get ruleVersion => 'Versi';

  @override
  String get fixedConversionRate => 'Kurs konversi tetap';

  @override
  String get contractSize => 'Ukuran kontrak';

  @override
  String get tradingSession => 'Sesi trading';

  @override
  String get initialMargin => 'Margin awal';

  @override
  String get facilityFee => 'Facility fee';

  @override
  String get rollover => 'Rollover';

  @override
  String get spread => 'Spread';

  @override
  String get hecticSpread => 'Spread saat pasar hectic';

  @override
  String get minimumMovement => 'Pergerakan minimum';

  @override
  String get limitStopRange => 'Rentang limit/stop';

  @override
  String get priceSource => 'Sumber / panduan harga';

  @override
  String get settlement => 'Penyelesaian';

  @override
  String get allowedLotRange => 'Posisi terbuka yang diizinkan';

  @override
  String get minimumDeposit => 'Deposit minimum';

  @override
  String get marginControls => 'Kontrol margin';

  @override
  String get profitLossFormula => 'Formula P/L';

  @override
  String get sourceDocument => 'Dokumen sumber';

  @override
  String get topUpCredit => 'Top Up Credit';

  @override
  String get analysisTopUpInfo =>
      'Ingin lanjut analisis? Lihat pilihan yang tersedia';

  @override
  String get analysisQuotaDayTitle => 'Kuota Analisis Gratis Habis';

  @override
  String get analysisQuotaDayMessage =>
      'Kuota analisis gratis kamu sudah habis terpakai.';

  @override
  String get analysisQuotaConcurrentTitle => 'Analisis masih diproses';

  @override
  String get analysisQuotaConcurrentMessage =>
      'Tunggu analisis sebelumnya selesai sebelum membuat analisis baru.';

  @override
  String get analysisQuotaUnknownTitle => 'Analisis belum dapat dibuat';

  @override
  String get analysisQuotaUnknownMessage =>
      'Batas analisis sedang berlaku. Silakan coba lagi nanti.';

  @override
  String analysisQuotaUsage(int used, int limit) {
    return 'Terpakai $used dari $limit';
  }

  @override
  String analysisRetryAfter(String duration) {
    return 'Coba lagi dalam $duration';
  }

  @override
  String analysisSeconds(int count) {
    return '$count detik';
  }

  @override
  String analysisMinutes(int count) {
    return '$count menit';
  }

  @override
  String analysisCreditConsumed(int balance) {
    return '1 credit dipakai. Sisa saldo: $balance credit.';
  }

  @override
  String get analysisCreditConsumedUnknownBalance =>
      '1 credit dipakai. Saldo sedang diperbarui.';

  @override
  String get creditBalance => 'Saldo credit';

  @override
  String get analysisCreditsDescription =>
      'Credit digunakan otomatis ketika kuota analisis gratis kamu sudah habis.';

  @override
  String get mobileCreditPurchaseUnavailable =>
      'Pembelian credit saat ini tidak tersedia di aplikasi mobile.';

  @override
  String get creditBalanceFailed => 'Saldo gagal dimuat.';

  @override
  String get topUpScanQris =>
      'Pindai QRIS ini lewat aplikasi bank atau e-wallet kamu, lalu kirim permintaan di bawah.';

  @override
  String get topUpQrisUnavailable => 'Kode QRIS gagal dimuat.';

  @override
  String topUpRatePerCredit(String amount) {
    return '$amount per credit';
  }

  @override
  String get topUpAmountLabel => 'Nominal (Rupiah)';

  @override
  String get topUpAmountHint => 'mis. 50000';

  @override
  String get topUpChooseAmount => 'Pilih nominal top-up';

  @override
  String get topUpChoosePackageFirst =>
      'Pilih salah satu paket top up terlebih dahulu.';

  @override
  String get topUpPayNow => 'Bayar sekarang';

  @override
  String get topUpPaymentMethod => 'Pilih metode pembayaran';

  @override
  String get topUpVirtualAccount => 'Virtual Account (Otomatis)';

  @override
  String get topUpVirtualAccountDescription =>
      'Transfer bank. Kredit masuk otomatis setelah pembayaran dikonfirmasi.';

  @override
  String topUpVirtualAccountFee(String fee, String total) {
    return 'Biaya admin $fee. Total dibayar $total.';
  }

  @override
  String get topUpQrisDescription =>
      'Pindai dengan e-wallet atau mobile banking. Kredit masuk otomatis setelah konfirmasi.';

  @override
  String get topUpNoAdminFee => 'Tanpa biaya admin';

  @override
  String get topUpCheckoutFailed => 'Gagal membuat sesi pembayaran. Coba lagi.';

  @override
  String get topUpResumePayment => 'Lanjutkan pembayaran';

  @override
  String get topUpContinuePayment => 'Lanjut ke pembayaran';

  @override
  String get topUpPayment => 'Detail pembayaran';

  @override
  String get topUpChangeAmount => 'Ganti nominal';

  @override
  String topUpPaymentSummary(String amount, int credits) {
    return 'Bayar $amount untuk menerima $credits credit';
  }

  @override
  String topUpCreditsPreview(int credits) {
    return 'Kamu akan menerima $credits credit';
  }

  @override
  String get topUpAmountRequired => 'Masukkan nominal yang kamu bayar.';

  @override
  String topUpAmountTooSmall(String amount) {
    return 'Top-up minimal $amount.';
  }

  @override
  String get topUpReferenceLabel => 'Referensi pembayaran (opsional)';

  @override
  String get topUpReferenceHint =>
      'mis. nama pengirim atau nomor referensi transfer';

  @override
  String get topUpProofLabel => 'Bukti pembayaran (wajib)';

  @override
  String get topUpAddProof => 'Lampirkan bukti';

  @override
  String get topUpChangeProof => 'Ganti bukti';

  @override
  String get topUpProofAttached => 'Bukti terlampir';

  @override
  String get topUpSubmit => 'Kirim permintaan top-up';

  @override
  String get topUpSubmitted => 'Permintaan top-up terkirim.';

  @override
  String topUpApprovedInstantly(int credits) {
    return 'Top-up disetujui. $credits credit sudah ditambahkan ke saldo kamu.';
  }

  @override
  String get topUpProofRequiredHint =>
      'Wajib — upload bukti transfer sebelum mengirim.';

  @override
  String get topUpProofNoticeTitle => 'Bukti Transfer Wajib Diupload';

  @override
  String get topUpProofNoticeBody =>
      'Sebelum mengirim, upload bukti transfer di halaman ini. Permintaan tanpa bukti tidak dapat dikirim.';

  @override
  String get topUpProofNoticeAcknowledge => 'Oke, mengerti';

  @override
  String get topUpWhatsAppSupport => 'Ada kendala? Hubungi CS via WhatsApp';

  @override
  String get topUpWhatsAppMessage =>
      'Halo, saya butuh bantuan terkait top up kredit TradePilot.id';

  @override
  String get topUpProofFailed =>
      'Bukti pembayaran gagal diunggah. Permintaan tidak dikirim.';

  @override
  String get topUpConfigFailed => 'Konfigurasi top-up gagal dimuat.';

  @override
  String get topUpHistory => 'Riwayat top-up';

  @override
  String get topUpHistoryEmpty => 'Kamu belum pernah mengajukan top-up.';

  @override
  String get topUpLoadMore => 'Muat lebih banyak';

  @override
  String get topUpApproved => 'Disetujui';

  @override
  String get topUpRejected => 'Ditolak';

  @override
  String topUpCreditsGranted(int credits) {
    return '$credits credit ditambahkan';
  }

  @override
  String topUpReviewNote(String note) {
    return 'Catatan admin: $note';
  }

  @override
  String topUpRequestedCredits(int credits) {
    return '$credits credit';
  }

  @override
  String get errSessionExpiredRelogin =>
      'Sesi berakhir atau akun masuk di perangkat lain. Silakan login kembali.';

  @override
  String get errSessionExpired => 'Sesi login sudah berakhir.';

  @override
  String get errSignInAgain => 'Silakan login kembali.';

  @override
  String get errNoConnection =>
      'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.';

  @override
  String get errServerUnreachable => 'Tidak dapat terhubung ke server.';

  @override
  String get errGeneric => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String get errServerProblem =>
      'Server sedang bermasalah. Coba lagi sebentar lagi.';

  @override
  String get errConnectionTimeout => 'Koneksi timeout. Silakan coba lagi.';

  @override
  String get errRequestCancelled => 'Permintaan dibatalkan.';

  @override
  String get errInstrumentRequired => 'Instrumen tidak boleh kosong.';

  @override
  String get errInstrumentUnsupported => 'Instrumen tidak didukung.';

  @override
  String get errTimeframeUnsupported => 'Timeframe tidak didukung.';

  @override
  String get errInvalidServerResponse => 'Respons server tidak valid.';

  @override
  String get errInvalidProfileResponse =>
      'Respons profil dari server tidak valid.';

  @override
  String errDisplayNameLength(int max) {
    return 'Nama harus terdiri dari 2–$max karakter.';
  }

  @override
  String get errCurrentPasswordWrong => 'Password saat ini tidak sesuai.';

  @override
  String get errPasswordTooWeak =>
      'Password belum memenuhi persyaratan keamanan.';

  @override
  String get errProfileInvalid =>
      'Data profil belum valid. Periksa kembali isian kamu.';

  @override
  String get errChangePasswordFailed =>
      'Gagal mengubah password. Silakan coba lagi.';

  @override
  String get errUpdateProfileFailed =>
      'Gagal memperbarui profil. Silakan coba lagi.';

  @override
  String get errTooManyAttempts =>
      'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';

  @override
  String get errDeleteAccountFailed =>
      'Gagal menghapus akun. Silakan coba lagi.';

  @override
  String get errSecurityAnswerWrong => 'Jawaban keamanan tidak sesuai.';

  @override
  String get errCredentialsWrong => 'Email atau password tidak sesuai.';

  @override
  String get errQuotaReached =>
      'Batas kuota analisis tercapai. Coba lagi nanti.';

  @override
  String get errAiTimeout =>
      'AI butuh waktu lebih lama dari biasanya untuk menganalisis. Silakan coba lagi.';

  @override
  String get errAnalysisFailed => 'Analisis gagal. Silakan coba lagi.';

  @override
  String get errAnalysisSlowSync =>
      'Koneksi ke AI lama meresponsnya. Analisis mungkin tetap berhasil dibuat — data akan disinkronkan otomatis.';

  @override
  String get errDateRangeInvalid =>
      'Tanggal awal tidak boleh melewati tanggal akhir.';

  @override
  String get errNoteTooLong5000 => 'Catatan maksimal 5.000 karakter.';

  @override
  String get errNoteNotSaved =>
      'Catatan belum tersimpan. Periksa koneksi lalu coba lagi.';

  @override
  String get errNoteSaveFailed =>
      'Catatan belum dapat disimpan. Silakan coba lagi.';

  @override
  String get errBalanceLoadFailed => 'Saldo credit gagal dimuat.';

  @override
  String get errTopupConfigLoadFailed => 'Konfigurasi top-up gagal dimuat.';

  @override
  String get errTopupHistoryLoadFailed =>
      'Riwayat top-up gagal dimuat. Tarik untuk mencoba lagi.';

  @override
  String get errTopupSubmitFailed => 'Permintaan top-up gagal dikirim.';

  @override
  String get errTopupAmountPositive =>
      'Nominal top-up harus lebih besar dari 0.';

  @override
  String get errTopupProofRequired => 'Upload bukti transfer sebelum mengirim.';

  @override
  String get errLivePricesFailed => 'Gagal memuat harga live.';

  @override
  String get errMarketDataPartial => 'Sebagian data pasar belum tersedia.';

  @override
  String get errTechnicalDataFailed => 'Gagal memuat data teknikal.';

  @override
  String get errPriceAlertsLoadFailed => 'Gagal memuat price alert.';

  @override
  String get errPriceAlertCreateFailed => 'Gagal membuat price alert.';

  @override
  String get errPriceAlertDeleteFailed => 'Gagal menghapus price alert.';

  @override
  String get errTargetPricePositive => 'Target harga harus lebih besar dari 0.';

  @override
  String get errNoteTooLong200 => 'Catatan maksimal 200 karakter.';

  @override
  String get errWatchlistLoadFailed => 'Gagal memuat watchlist.';

  @override
  String get errWatchlistUpdateFailed => 'Gagal memperbarui watchlist.';

  @override
  String get errNotificationsLoadFailed =>
      'Notifikasi belum dapat dimuat. Tarik untuk mencoba lagi.';

  @override
  String get errNotificationPrefsLoadFailed =>
      'Gagal memuat preferensi notifikasi.';

  @override
  String get errNotificationPrefsSaveFailed =>
      'Gagal menyimpan preferensi notifikasi.';

  @override
  String get errMarketSessionReminderSaveFailed =>
      'Gagal menyimpan pengingat sesi market.';

  @override
  String get errQuietHoursSaveFailed =>
      'Gagal menyimpan waktu tenang notifikasi.';

  @override
  String get errPushPermissionSystem =>
      'Izin notifikasi belum diberikan di pengaturan sistem.';

  @override
  String get errPushEnableFailed => 'Push notification belum dapat diaktifkan.';

  @override
  String get errPushPrefsSaveFailed =>
      'Preferensi mobile push belum dapat disimpan.';

  @override
  String get errPushTokenUnavailable =>
      'Token push belum tersedia pada perangkat ini.';

  @override
  String get errPushRegisterFailed =>
      'Server belum dapat mendaftarkan perangkat push.';

  @override
  String get errPushTokenSyncFailed => 'Token push belum dapat disinkronkan.';

  @override
  String get errPushEnableFirst =>
      'Aktifkan Push Mobile sebelum mengirim notifikasi tes.';

  @override
  String get errPushTestNoDevice =>
      'Server belum menemukan perangkat terdaftar, atau endpoint tes belum di-deploy.';

  @override
  String get errPushTestRateLimited =>
      'Terlalu banyak permintaan notifikasi tes. Tunggu sebentar lalu coba lagi.';

  @override
  String get errPushTestNotReceived =>
      'Server menerima permintaan tes, tetapi perangkat ini tidak menerima pesan FCM dalam 15 detik. Credential Firebase dan konfigurasi project di backend perlu diperiksa.';

  @override
  String get errPushTestFailed =>
      'Permintaan notifikasi tes gagal. Periksa koneksi lalu coba lagi.';

  @override
  String get errPushTestRejected =>
      'FCM menolak semua pesan tes. Periksa token perangkat dan konfigurasi Firebase di backend.';

  @override
  String get errPushTestNotConfigured =>
      'Layanan push notification belum dikonfigurasi di backend.';

  @override
  String get appErrInstrumentUnsupported =>
      'Instrumen ini belum mendukung Rekomendasi Ukuran Posisi.';

  @override
  String get appErrNoStandardPlan =>
      'Standard Plan atau TP Standard Trading Rules tidak tersedia.';

  @override
  String get appErrFundsPositive => 'Dana trading tersedia harus lebih dari 0.';

  @override
  String get appErrMaxLossPositive => 'Batas rugi maksimum harus lebih dari 0.';

  @override
  String get appErrMaxLossExceedsFunds =>
      'Batas rugi maksimum tidak boleh melebihi dana tersedia.';

  @override
  String get appErrExposureNegative => 'Eksposur berjalan tidak boleh negatif.';

  @override
  String get appErrTpRulesInvalid =>
      'TP Standard Trading Rules tidak cocok atau tidak valid.';

  @override
  String get appErrLevelsInvalid =>
      'Level Entry dan Stop Loss Standard Plan tidak valid.';

  @override
  String get appErrSnapshotConflict =>
      'Snapshot teknikal berkonflik dengan arah pasar.';

  @override
  String get appErrBelowMinimumLot =>
      'Dana atau batas rugi belum cukup untuk lot minimum tier ini.';

  @override
  String get mindsetPacingTitle => 'Jeda evaluasi';

  @override
  String get mindsetPacingBody =>
      'Beberapa analisis dibuat dalam waktu berdekatan. Pertimbangkan memberi waktu untuk mengevaluasi analisis sebelumnya.';

  @override
  String get mindsetConcentrationTitle => 'Fokus instrumen';

  @override
  String mindsetConcentrationBody(int count, int total, String instrument) {
    return '$count dari $total analisis yang sedang dihitung berfokus pada $instrument.';
  }

  @override
  String get mindsetPendingTitle => 'Analisis masih menunggu';

  @override
  String mindsetPendingBody(int count) {
    return '$count analisis yang sedang dihitung belum selesai dievaluasi. Gunakan hasil berikutnya sebagai bahan refleksi, bukan kepastian.';
  }

  @override
  String get mindsetJournalTitle => 'Konsistensi catatan';

  @override
  String get mindsetJournalBody =>
      'Catatan pribadi masih jarang digunakan. Menulis alasan awal dapat membantu refleksi setelah evaluasi tersedia.';

  @override
  String get localTraderSentiment => 'Sentimen trader lokal';

  @override
  String journalSentimentGated(int entries, int traders) {
    return 'Data disembunyikan sampai minimal $entries entri dari $traders trader tersedia.';
  }

  @override
  String journalSentimentSample(int entries, int days) {
    return '$entries entri · $days hari';
  }

  @override
  String get journalSentimentDisclaimer =>
      'Agregat anonim jurnal komunitas, bukan sinyal trading.';

  @override
  String get personalNote => 'Catatan Pribadi';

  @override
  String get addNote => 'Tambah catatan';

  @override
  String get notePrivateHint =>
      'Tersimpan privat di akunmu dan tidak dikirim ke AI.';

  @override
  String get noteHint => 'Tulis alasan, observasi, atau pelajaranmu…';

  @override
  String get deleteNote => 'Hapus catatan';

  @override
  String get noNoteYet => 'Belum ada catatan untuk analisis ini.';

  @override
  String get newsLinkFailed => 'Tautan berita tidak dapat dibuka.';

  @override
  String get newsLoadFailed => 'Berita belum dapat dimuat.';

  @override
  String get newsEmpty => 'Belum ada berita terbaru.';

  @override
  String get newsDisclaimer =>
      'Berita bersifat informasi dan bukan rekomendasi investasi.';

  @override
  String get newsSourceFallback => 'Sumber berita';

  @override
  String get latestNews => 'Berita Terkini';

  @override
  String get refresh => 'Segarkan';

  @override
  String get scrollForMore => 'Geser untuk melihat lainnya';

  @override
  String get publicAiPerformanceSubtitle =>
      'Rekam jejak anonim seluruh analisis TradePilot';

  @override
  String get analyticsLoadFailed => 'Analytics belum dapat dimuat. Coba lagi.';

  @override
  String get sessionChangedReopen => 'Sesi berubah. Buka kembali halaman ini.';

  @override
  String get analyticsDisclaimer =>
      'Statistik ini menjelaskan kebiasaan analisis, bukan hasil profit trading.';

  @override
  String get analyticsActivitySummary => 'Ringkasan aktivitas';

  @override
  String get analyticsWeeklyActivity => 'Aktivitas mingguan';

  @override
  String get metricAllAnalyses => 'Semua analisis';

  @override
  String get metricThisMonth => 'Bulan ini';

  @override
  String get metricThisWeek => 'Minggu ini';

  @override
  String get metricFeedbackGiven => 'Feedback diberikan';

  @override
  String get metricDominantMode => 'Mode dominan';

  @override
  String get metricOutcomeAccuracy => 'Akurasi outcome';

  @override
  String get instrumentRanking => 'Peringkat instrumen';

  @override
  String countAnalyses(int count) {
    return '$count analisis';
  }

  @override
  String get loadedResults => 'Hasil yang sedang dimuat';

  @override
  String analyticsPartialScope(int loaded, int total) {
    return 'Hanya menghitung $loaded dari $total analisis. Muat lebih banyak di History untuk memperluas ringkasan.';
  }

  @override
  String analyticsFullScope(int loaded) {
    return 'Menghitung semua $loaded analisis yang tersedia di perangkat saat ini.';
  }

  @override
  String get metricEvaluated => 'Dievaluasi';

  @override
  String get metricPending => 'Menunggu';

  @override
  String get metricPositiveOutcomes => 'Outcome positif';

  @override
  String get metricNegativeOutcomes => 'Outcome negatif';

  @override
  String get metricHasNote => 'Punya catatan';

  @override
  String get metricAverageConfidence => 'Rata-rata keyakinan';

  @override
  String get metricTopTimeframe => 'Timeframe teratas';

  @override
  String get metricTopInstrument => 'Instrumen teratas';

  @override
  String get traderMirrorLoadFailed => 'Trader Mirror belum dapat dimuat.';

  @override
  String get traderMirrorDisclaimer =>
      'Cermin kebiasaan ini bersifat retrospektif dan tidak memberikan instruksi trading.';

  @override
  String get traderMirrorNoHighlights =>
      'Belum cukup data untuk membuat sorotan.';

  @override
  String traderMirrorCoverage(int days, int resolved) {
    return 'Cakupan $days hari · $resolved evaluasi selesai';
  }

  @override
  String get traderMirrorSessions => 'Sesi pasar';

  @override
  String get traderMirrorInstruments => 'Konsentrasi instrumen';

  @override
  String get traderMirrorTiming => 'Waktu analisis';

  @override
  String get traderMirrorPostLoss => 'Pola setelah outcome negatif';

  @override
  String get traderMirrorEvaluationDiscipline => 'Disiplin evaluasi';

  @override
  String get traderMirrorProcessReflection => 'Refleksi proses';

  @override
  String traderMirrorSamples(int count) {
    return '$count sampel';
  }

  @override
  String traderMirrorBasedOn(int count) {
    return 'Berdasarkan $count analisis yang sedang dimuat di perangkat.';
  }

  @override
  String get traderMirrorNeedMore =>
      'Butuh sedikitnya 3 analisis untuk refleksi yang cukup hati-hati.';

  @override
  String traderMirrorGated(String need, int have) {
    return 'Perlu $need data; tersedia $have.';
  }

  @override
  String get traderMirrorUngated => 'Data cukup untuk menampilkan rincian.';

  @override
  String get traderMirrorNeedMoreGeneric => 'lebih banyak';

  @override
  String get dailySummaryLoadFailed => 'Ringkasan harian belum dapat dimuat.';

  @override
  String get dailySummarySaveFailed => 'Pengaturan ringkasan gagal disimpan.';

  @override
  String get dailySummaryEmpty => 'Belum ada ringkasan untuk hari ini.';

  @override
  String dailySummaryTimezone(String timezone) {
    return 'Zona waktu: $timezone';
  }

  @override
  String get dailySummaryDeliveryTime => 'Waktu pengiriman';

  @override
  String get dailySummaryFullDigest => 'Ringkasan lengkap';

  @override
  String get dailySummaryQuotaOnly => 'Hanya kuota';

  @override
  String dailySummaryPreferredSide(String side) {
    return 'Sisi pilihan: $side';
  }

  @override
  String get guideSearchHint => 'Cari panduan...';

  @override
  String get guideQuickStart => 'Mulai cepat';

  @override
  String get guideQuickStartHint => 'Mulai dari alur yang paling penting.';

  @override
  String get guideSubtitle => 'Pengetahuan, fitur, dan mindset.';

  @override
  String get guideNoResults => 'Artikel tidak ditemukan.';

  @override
  String get marketChartUnavailable => 'Chart market belum tersedia.';

  @override
  String get journalCheckFailed => 'Jurnal belum dapat diperiksa.';

  @override
  String get alertStatusLoadFailed => 'Status alert belum dapat dimuat.';

  @override
  String get alertNeedsNotificationPermission =>
      'Aktifkan izin notifikasi agar alert harga dapat digunakan.';

  @override
  String get alertEnableFailed =>
      'Alert gagal diaktifkan. Pastikan notifikasi aktif dan instrumen memiliki feed harga live.';

  @override
  String get alertDisableFailed =>
      'Alert gagal dinonaktifkan. Coba lagi sebentar.';

  @override
  String get fundamentalDriftNone =>
      'Fundamental terbaru masih mendukung seluruh sumber awal.';

  @override
  String fundamentalDriftSome(int missing, int total) {
    return '$missing dari $total sumber awal tidak lagi ada di window terbaru.';
  }

  @override
  String get outcomePendingLabel => 'Menunggu hasil';

  @override
  String get outcomePendingBody =>
      'Market masih berjalan dan sistem sedang mengevaluasi apakah level TP atau SL tersentuh.';

  @override
  String get outcomeTp1Label => 'TP1 Tercapai';

  @override
  String get outcomeTp1Body =>
      'Harga sudah mencapai target profit pertama dari skenario analysis.';

  @override
  String get outcomeTp2Label => 'TP2 Tercapai';

  @override
  String get outcomeTp2Body =>
      'Harga sudah mencapai target profit kedua dari skenario analysis.';

  @override
  String get outcomeSlLabel => 'Stop Loss Tersentuh';

  @override
  String get outcomeSlBody =>
      'Harga mencapai batas risiko terlebih dahulu. Ini contoh kenapa Stop Loss penting dalam setiap setup.';

  @override
  String get outcomeExpiredLabel => 'Kedaluwarsa';

  @override
  String get outcomeExpiredBody =>
      'Masa berlaku analysis selesai tanpa target utama terkonfirmasi.';

  @override
  String get outcomeInvalidatedLabel => 'Analisis Tidak Valid';

  @override
  String get outcomeInvalidatedBody =>
      'Setup tidak lagi memenuhi struktur analysis awal.';

  @override
  String get outcomeUnknownLabel => 'Status belum tersedia';

  @override
  String get outcomeUnknownBody => 'Outcome belum dapat dievaluasi.';

  @override
  String get whyNotHigherConfidence => 'Kenapa keyakinan tidak lebih tinggi?';

  @override
  String get seeFullReasoning => 'Lihat alasan lengkap';

  @override
  String analysisBasis(String instrument, String timeframe) {
    return 'Dasar analisis: $instrument · $timeframe';
  }

  @override
  String get technicalEvidence => 'Bukti teknikal';

  @override
  String get newsCalendarContext => 'Konteks berita & kalender';

  @override
  String get mainRisk => 'Risiko utama';

  @override
  String get reassessIf => 'Tinjau ulang jika';

  @override
  String get copyText => 'Salin teks';

  @override
  String get copyImage => 'Salin gambar';

  @override
  String get fullReasoningCopied => 'Alasan lengkap disalin';

  @override
  String get fullReasoningCopyFailed => 'Alasan lengkap gagal disalin.';

  @override
  String get reasoningImageCopied => 'Gambar disalin';

  @override
  String get reasoningImageCopyFailed => 'Gambar gagal disalin.';

  @override
  String get citedSources => 'Sumber yang dirujuk';

  @override
  String get awaitConfirmationNotice =>
      'Tunggu konfirmasi — AI belum merekomendasikan Buy atau Sell saat ini.';

  @override
  String get instrumentRulesUnavailable => 'Aturan instrumen tidak tersedia.';

  @override
  String get tradingRulesLoadFailed => 'Aturan trading belum dapat dimuat.';

  @override
  String get tradingRulesUnavailable => 'Aturan trading tidak tersedia.';

  @override
  String get positionSizeRecommendation => 'Rekomendasi Ukuran Posisi';

  @override
  String get adaptiveTradingPlan => 'Rencana Trading Adaptif';

  @override
  String get adaptiveTradingPlanSubtitle =>
      'Simulasikan entry, ukuran lot, dan risiko dari analisis ini.';

  @override
  String get fixedAccountRulesProfile => 'PROFIL ATURAN AKUN TETAP';

  @override
  String get tradingCapital => 'Modal trading';

  @override
  String get lossLimit => 'Batas kerugian';

  @override
  String get adaptiveIntradayOnly =>
      'Perhitungan ini hanya berlaku untuk posisi intraday (day trade); posisi overnight tidak termasuk.';

  @override
  String get theoreticalMarginCapacity => 'Kapasitas margin teoretis';

  @override
  String theoreticalMarginCapacityValue(String lot) {
    return 'Hingga $lot lot per posisi sebelum Stop Loss dan batas risiko seluruh plan diterapkan.';
  }

  @override
  String analysisCandleSnapshotFetched(String date) {
    return 'Snapshot candle analisis diambil: $date';
  }

  @override
  String get createRecommendation => 'Buat rekomendasi';

  @override
  String get understandDetails => 'Pahami detailnya';

  @override
  String get understandDetailsSubtitle =>
      'Lihat temuan analisis tersimpan dan cara Adaptive meresponsnya. Indikator live tidak memperbarui plan ini secara otomatis.';

  @override
  String get whyThisAnalysis => 'Alasan analisis ini';

  @override
  String get analysisInvalidWhen => 'Analisis ini menjadi tidak valid jika:';

  @override
  String get scenariosSupportingFactors =>
      'Lihat skenario dan faktor pendukung';

  @override
  String get scenarios => 'Skenario';

  @override
  String get scenarioMain => 'Skenario A — Utama';

  @override
  String get scenarioAlternative => 'Skenario B — Alternatif';

  @override
  String get scenarioWait => 'Skenario C — Tunggu / Tanpa Posisi';

  @override
  String get wherePlanComesFrom => 'Asal plan ini';

  @override
  String planCandidateSummary(int buy, int sell) {
    return 'Dari snapshot analisis ini: $buy kandidat swing Buy dan $sell kandidat swing Sell. Hanya level dalam plan tersimpan dan batas keamanan yang dapat digunakan.';
  }

  @override
  String get sourceLayeredPlan => 'Sumber plan berlapis ini';

  @override
  String get sourceLayeredPlanBody =>
      'Dasar utama: analisis tersimpan—zona entry pada waktu analisis, satu Stop Loss final, target, bias, confidence, hitungan teknikal, kondisi market, dan snapshot fundamental. Level swing chart saat ini dapat menjadi kandidat layer terpisah; level tersebut tidak pernah diam-diam menggantikan level analisis tersimpan.';

  @override
  String fixedAccountProfileSummary(String lot, String margin) {
    return 'Minimum $lot lot · margin $margin';
  }

  @override
  String get adaptiveSupportedInstruments =>
      'Adaptive Plan mendukung analisis XAU/USD, BRENT, HSI, dan NIKKEI. Pilih tier akun yang sesuai dengan akun aktifmu.';

  @override
  String get tradingCapitalHelp =>
      'Masukkan dana yang tersedia untuk plan ini. Dana harus menutup margin harian dan risiko jika Stop Loss final tersentuh; kekurangan dana akan ditampilkan.';

  @override
  String get lossLimitHelp =>
      'Masukkan kerugian maksimum dalam USD yang kamu terima untuk seluruh plan. Menaikkan batas ini hanya membantu jika modal trading juga menutup margin harian dan risiko Stop Loss final.';

  @override
  String get riskStyleHelp =>
      'Gaya menentukan seberapa banyak batas kerugian yang dapat dipakai dan cara risiko dialokasikan pada seluruh layer. Lot dihitung dari jarak tiap entry ke Stop Loss; batas pengaman market tetap menjadi prioritas.';

  @override
  String get printSavePdf => 'Cetak / simpan PDF';

  @override
  String get printableReportOpenFailed =>
      'Laporan siap cetak tidak dapat dibuka.';

  @override
  String get reportBriefingTitle => 'Ringkasan briefing';

  @override
  String get reportSourcesTitle => 'Sumber data';

  @override
  String get priceRiseScenario => 'Skenario harga naik (Buy)';

  @override
  String get priceFallScenario => 'Skenario harga turun (Sell)';

  @override
  String scenarioFitsRisk(String side) {
    return 'Setup $side sesuai dengan risiko dan danamu. Konfirmasi chart saat ini sebelum entry.';
  }

  @override
  String watchEntry(String entry) {
    return 'Pantau entry di sekitar $entry. Entry hanya jika setup terkonfirmasi; jangan menggeser stop.';
  }

  @override
  String get minimumRiskAtStop => 'Risiko minimum saat stop';

  @override
  String get brokerFundsAtStop => 'Dana broker saat stop';

  @override
  String get reviewOneDirection => 'Tinjau satu arah pada satu waktu';

  @override
  String get planReadyToReview => 'Plan siap ditinjau';

  @override
  String get conditionalScenarioNotActionable =>
      'Skenario kondisional · belum bisa dieksekusi';

  @override
  String get adaptiveWaitDecisionBody =>
      'Arah pasar belum terkonfirmasi. Tunggu sampai sinyal selaras; jangan entry ke sisi sebaliknya.';

  @override
  String get hardLossMaximum => 'Batas kerugian maksimum';

  @override
  String get entryDirectionUnconfirmedTitle => 'Arah entry belum terkonfirmasi';

  @override
  String get entryDirectionUnconfirmedBody =>
      'Ini hanya skenario kondisional—belum bisa dieksekusi sekarang. Tunggu sampai analisis tersimpan dan arah pasar saat ini mendukung sisi ini; menyalin sebagai rencana entry dinonaktifkan.';

  @override
  String get entryDirectionUnconfirmedNextAction =>
      'Langkah selanjutnya: tunggu atau lewati. Jangan gunakan limit finansial lebih besar untuk mengakali pengaman arah ini.';

  @override
  String get referenceNumbersOnly =>
      'Hanya angka referensi—pilihan saat ini diblokir atau menunggu konfirmasi.';

  @override
  String get answerAtGlance => 'Jawaban sekilas';

  @override
  String get objectiveScenario =>
      'Tier dan gaya risiko pilihanmu, ditampilkan sebagai skenario objektif.';

  @override
  String get entryLotPerPosition => 'Titik entry & lot per posisi';

  @override
  String get initialEntry => 'Entry awal';

  @override
  String get additionalPosition => 'Tambahan';

  @override
  String allEntriesFill(int positions, String lots) {
    return 'Jika semua entry terisi: $positions posisi · $lots lot';
  }

  @override
  String get oneFinalStopLoss => 'Satu Stop Loss final';

  @override
  String get estimatedMaximumLoss => 'Estimasi kerugian maksimum';

  @override
  String get riskContext => 'Konteks risiko';

  @override
  String get usableRiskBudget => 'Anggaran risiko terpakai';

  @override
  String get reservedLossCeiling => 'Batas kerugian tersisa';

  @override
  String get profitTargets => 'Target profit';

  @override
  String estimatedProfit(String amount) {
    return 'Estimasi profit: +$amount';
  }

  @override
  String get extraPositionsManual =>
      'Posisi tambahan bersifat manual: konfirmasi chart dan setup sebelum setiap penambahan.';

  @override
  String get viewPlanDetails => 'Lihat detail plan';

  @override
  String get extraLayersManual =>
      'Layer tambahan adalah checkpoint manual untuk skenario ini. Sebelum setiap layer, pastikan level dapat dicapai, analisis masih selaras, invalidation belum terjadi, dan tidak ada risiko fundamental baru.';

  @override
  String get ifEntriesFill => 'Jika entry terisi';

  @override
  String get firstEntryOnly => 'Hanya entry pertama';

  @override
  String get allPlannedEntries => 'Semua entry terencana';

  @override
  String get grossEstimateDisclaimer =>
      'Hanya entry yang terisi yang dihitung. Ini estimasi kotor pada level yang ditampilkan, bukan jaminan fill atau hasil bersih; spread, fee, slippage, dan likuidasi dini dapat mengubah hasil.';

  @override
  String get whyLossCeilingUnused => 'Mengapa batas rugi tidak habis digunakan';

  @override
  String get lossCeilingUnusedBody =>
      'Sisa batas rugi tidak otomatis membenarkan posisi tambahan; setiap entry juga memerlukan harga valid dan dana bebas yang cukup.';

  @override
  String get showExplanation => 'Tampilkan penjelasan';

  @override
  String get layerExplanation =>
      'Setiap baris menunjukkan nilai posisi tersebut, nilai kumulatif sampai layer itu, dan sisa dana setelah margin harian serta satu Stop Loss final.';

  @override
  String get marginThisPosition => 'Margin posisi ini';

  @override
  String get marginUsedSoFar => 'Margin terpakai sejauh ini';

  @override
  String get riskThisPosition => 'Risiko posisi ini pada SL final';

  @override
  String get riskAtStopSoFar => 'Risiko pada SL final sejauh ini';

  @override
  String get fundsNeededAtStop => 'Dana dibutuhkan pada SL final';

  @override
  String get fundsRemaining => 'Dana tersisa';

  @override
  String get cumulativeProfitTp1 => 'Profit kumulatif ke TP1';

  @override
  String get cumulativeProfitTp2 => 'Profit kumulatif ke TP2';

  @override
  String get moreCalculationDetails => 'Detail kalkulasi lainnya';

  @override
  String get weightedAverageEntry => 'Rata-rata entry tertimbang';

  @override
  String get dayMarginPlusLoss => 'Margin harian + rugi pada SL';

  @override
  String get howUseRecommendation => 'Cara menggunakan rekomendasi ini';

  @override
  String get howUseRecommendationBody =>
      '1. Pilih hanya satu skenario berdasarkan keputusanmu sendiri.\n2. Entry hanya pada titik valid dari plan analisis.\n3. Sebelum setiap layer tambahan, konfirmasi ulang setup dan invalidation.\n4. Tutup pada Stop Loss final; jangan menggesernya untuk menahan posisi rugi.';

  @override
  String get manualExecutionDisclaimer =>
      'Kamu tetap memutuskan dan memasang setiap trade sendiri; fitur ini tidak pernah membuka atau menutup posisi secara otomatis.';

  @override
  String get adaptivePlanIntro =>
      'Ubah Standard Plan menjadi ukuran posisi sesuai dana dan batas rugi.';

  @override
  String get adaptivePlanDisclaimer =>
      'Kalkulator ini tidak mengubah level AI dan tidak mengirim order. Isi dana bebas yang sudah dikurangi margin posisi lain.';

  @override
  String get availableTradingFunds => 'Dana trading tersedia';

  @override
  String get maxLossLimit => 'Batas rugi maksimum';

  @override
  String get accountTier => 'Tier akun';

  @override
  String get buildPositionPlan => 'Buat rencana posisi';

  @override
  String get copyPositionPlan => 'Salin rencana';

  @override
  String get positionPlanCopied => 'Rencana posisi disalin.';

  @override
  String get positionPlanCopyFailed => 'Rencana posisi gagal disalin.';

  @override
  String get positionDirection => 'Arah';

  @override
  String get riskStyle => 'Gaya risiko';

  @override
  String get riskStyleConservative => 'Conservative';

  @override
  String get riskStyleBalanced => 'Moderat';

  @override
  String get riskStyleAggressive => 'Aggressive';

  @override
  String get totalLots => 'Total lot';

  @override
  String get marginRequired => 'Margin dibutuhkan';

  @override
  String get estimatedCycleLoss => 'Estimasi rugi siklus';

  @override
  String get adaptiveCopyManualContext =>
      'Rencana ini bersifat manual dan bersyarat — konfirmasi chart terkini dan risiko fundamental sebelum entry atau menambah layer. Bukan order otomatis.';

  @override
  String get notRecommended => 'Tidak direkomendasikan';

  @override
  String get adaptivePlanFootnote =>
      'Day trading only. Estimasi tidak memasukkan spread, slippage, fee, VAT, rollover, atau auto-liquidation broker.';

  @override
  String get lossToSl => 'Rugi ke SL';

  @override
  String get entryZone => 'Zona Entry';

  @override
  String get primaryScenario => 'Skenario Utama';

  @override
  String get analyzeAction => 'Analisis';

  @override
  String get setAlertAction => 'Pasang Alert';

  @override
  String get currentPriceLabel => 'Harga saat ini';

  @override
  String get trackMarketsTradingView => 'Pantau semua market di TradingView';

  @override
  String get marketSessionsAboutTitle => 'Tentang sesi market';

  @override
  String get marketSessionsAboutBody =>
      'Bagian ini menunjukkan sesi market global yang sedang buka. Ini berguna sebagai konteks untuk Emas, forex, dan instrumen non-kripto lainnya.';

  @override
  String get marketSessionsOverlapBody =>
      'Ketika dua sesi beririsan, aktivitas dan likuiditas biasanya lebih tinggi.';

  @override
  String get typicalSessionHours => 'Jam sesi umum';

  @override
  String get shownInJakarta => 'Ditampilkan dalam Asia/Jakarta';

  @override
  String get marketSessionContextDisclaimer =>
      'Ini adalah konteks market, bukan sinyal trading atau pemicu order otomatis.';

  @override
  String get analyzeFooterDisclaimer =>
      'TradePilot adalah alat bantu pengambilan keputusan, bukan broker, layanan trading, atau penasihat keuangan pribadi. Keputusan dan risiko tetap menjadi tanggung jawabmu.';

  @override
  String get searchOrEnterInstrumentCode => 'Cari atau masukkan kode';

  @override
  String get directionalBias => 'BIAS ARAH';

  @override
  String forTimeframe(String timeframe) {
    return 'Untuk timeframe $timeframe';
  }

  @override
  String get strongBearishBias => 'Bias bearish kuat';

  @override
  String get neutralWait => 'Netral / Tunggu';

  @override
  String get strongBullishBias => 'Bias bullish kuat';

  @override
  String get biasNotInstruction =>
      'Kecenderungan hasil analisis — bukan instruksi beli/jual';

  @override
  String get learn => 'Pelajari';

  @override
  String relevantForHours(int hours) {
    return 'Masih relevan sekitar $hours jam lagi';
  }

  @override
  String get shareChart => 'Bagikan chart';

  @override
  String get copyAnalysisImage => 'Salin gambar analisis';

  @override
  String get savePng => 'Simpan PNG';

  @override
  String get shareImage => 'Bagikan gambar';

  @override
  String get chartImageCopied => 'Gambar chart disalin';

  @override
  String get chartImageSaved => 'Gambar chart tersimpan di galeri';

  @override
  String get chartImageFailed => 'Gambar chart gagal diproses. Coba lagi.';

  @override
  String requestInstrument(String symbol) {
    return 'Request $symbol';
  }

  @override
  String instrumentNotAvailableTitle(String symbol) {
    return '$symbol belum tersedia';
  }

  @override
  String get instrumentNotAvailableBody =>
      'Terima kasih, permintaanmu membantu kami menentukan instrumen berikutnya. Kami akan mempertimbangkan analisis untuk instrumen ini di masa depan.';

  @override
  String get clear => 'Hapus';

  @override
  String get adaptiveAccountMicro => 'Micro';

  @override
  String get adaptiveAccountMicroDesc => 'Minimum 0,01 lot · margin \$10';

  @override
  String get adaptiveAccountMini => 'Mini';

  @override
  String get adaptiveAccountMiniDesc => 'Minimum 0,10 lot · margin \$100';

  @override
  String adaptiveAccountOpeningMinimum(String amount) {
    return 'Minimum untuk membuka akun Micro adalah $amount. Dana yang lebih kecil tetap dapat menjadi free margin jika akun sudah aktif.';
  }

  @override
  String get adaptiveAccountRegular => 'Regular';

  @override
  String get adaptiveAccountRegularDesc => 'Minimum 1,00 lot · margin \$1.000';

  @override
  String adaptiveAccountRule(
    String amount,
    String lot,
    String maximum,
    String size,
    String tier,
    String unit,
  ) {
    return '$tier: minimum $lot lot membutuhkan margin $amount. Maksimum $maximum lot berlaku untuk setiap posisi, sedangkan total seluruh rencana boleh lebih besar jika margin dan risiko Stop Loss mengizinkan. Contract size $size $unit untuk satu posisi minimum.';
  }

  @override
  String adaptiveAccountRuleUncapped(
    String amount,
    String lot,
    String size,
    String tier,
    String unit,
  ) {
    return '$tier: minimum $lot lot membutuhkan margin $amount. Adaptive tidak memasang batas lot per posisi buatan untuk Regular; aturan broker yang terverifikasi, dana bebas, dan risiko Stop Loss tetap berlaku. Contract size $size $unit untuk satu posisi minimum.';
  }

  @override
  String get adaptiveAccountTitle => 'Tipe akun';

  @override
  String get adaptiveAlternativeAvailableShort =>
      'Alternatif tersedia untuk ditinjau; Standard Plan tetap.';

  @override
  String adaptiveAlternativeBasis(
    String entry,
    String loss,
    String lot,
    String margin,
    String profit,
    String rr,
    String side,
    String stop,
    String target,
  ) {
    return 'Hanya jika SL tersimpan tampak kurang sesuai: Entry, SL, dan target dari swing chart yang berdiri sendiri untuk $side. Satu posisi lot minimum $lot; Entry $entry, SL $stop, target $target (RR $rr). Margin day $margin, estimasi rugi di SL $loss, profit bruto di target $profit. Konfirmasi chart terkini dan risiko fundamental sebelum trading.';
  }

  @override
  String get adaptiveAlternativeNoLevels =>
      'Alternatif lengkap belum didukung oleh chart, batas akun, dan arah saat ini. Jalankan analisis baru alih-alih hanya menggeser SL atau target.';

  @override
  String get adaptiveAlternativeTitle => 'Skenario Adaptive (alternatif)';

  @override
  String get adaptiveAlternativeUnavailableShort =>
      'Alternatif belum tersedia — jalankan analisis baru, jangan geser SL/target.';

  @override
  String get adaptiveAlternativeUnchanged =>
      'Skenario terpisah untuk ditinjau saja. Standard Plan tidak diubah dan tidak ada order yang dikirim.';

  @override
  String get adaptiveAnalysisBasis =>
      'Plan memakai analisis di atas: zona Entry, satu Stop Loss final, target, bias, confidence, sinyal teknikal, kondisi market, dan snapshot fundamental.';

  @override
  String get adaptiveAnalysisExpired =>
      'Analisis tersimpan sudah kedaluwarsa. Jalankan analisis baru sebelum membuat rekomendasi Adaptive.';

  @override
  String get adaptiveBlockedBoth =>
      'Risiko lot minimum melewati batas rugi dan dana broker kurang. Mengubah satu input saja belum tentu cukup.';

  @override
  String get adaptiveBlockedBothNext =>
      'Hanya jika siap menanggung rugi lebih besar dan dana broker benar-benar bertambah, ubah kedua input lalu hitung ulang. Jika tidak, tunggu setup lain. Jangan geser stop; perubahan itu belum menjamin entry.';

  @override
  String get adaptiveBlockedDismiss => 'Tunggu setup lain';

  @override
  String get adaptiveBlockedEditFunds => 'Ubah dana broker';

  @override
  String get adaptiveBlockedEditLoss => 'Ubah batas rugi';

  @override
  String get adaptiveBlockedFunds =>
      'Dana broker yang tersedia belum cukup untuk posisi minimum hingga stop.';

  @override
  String get adaptiveBlockedFundsGap => 'Dana kurang';

  @override
  String get adaptiveBlockedFundsNext =>
      'Perbarui dana yang benar-benar tersedia di akun broker, lalu hitung ulang. Jika tidak, tunggu setup lain. Ini soal dana broker, bukan kredit analisis TradePilot.';

  @override
  String get adaptiveBlockedRisk =>
      'Risiko lot minimum melewati batas rugimu. Menambah dana broker saja tidak mengatasinya.';

  @override
  String get adaptiveBlockedRiskGap => 'Melewati batas rugi';

  @override
  String get adaptiveBlockedRiskNext =>
      'Jika sadar dan siap menanggung rugi lebih besar, ubah batas rugi lalu hitung ulang. Jika tidak, tunggu setup dengan risiko lebih kecil. Jangan geser stop; batas baru belum menjamin entry.';

  @override
  String get adaptiveBlockedTitle => 'Kenapa belum bisa entry?';

  @override
  String get adaptiveCandleSourceTime => 'Snapshot candle analisis diambil';

  @override
  String adaptiveCapacityNone(String tier) {
    return 'Dana ini belum memenuhi margin transaksi minimum untuk profil $tier.';
  }

  @override
  String get adaptiveChartCandidatesLoading =>
      'Membaca level swing chart terkini…';

  @override
  String get adaptiveChartConfirmation =>
      'Swing level terbaru di antara Entry dan Stop Loss dapat menjadi kandidat layer. Level ini hanya checkpoint tambahan dan tidak mengganti level analisis.';

  @override
  String adaptiveCompareBoth(String funds, String risk) {
    return 'Risiko melewati batas rugi sebesar $risk dan dana kurang $funds. Lewati; tambah dana saja tidak cukup.';
  }

  @override
  String get adaptiveCompareConflict =>
      'Sinyal pasar bertentangan. Lewati setup ini; ganti akun atau tambah dana tidak mengubah arah.';

  @override
  String get adaptiveCompareFinancialNoAlternative =>
      'Kontrak minimum terhalang batas akun ini, bukan karena kurang analisis AI. Jangan geser stop atau target tersimpan untuk memaksa entry.';

  @override
  String adaptiveCompareFunds(String funds) {
    return 'Dana hingga stop kurang $funds. Lewati; hitung ulang hanya jika dana broker berubah.';
  }

  @override
  String get adaptiveCompareLimited =>
      'Risiko lot minimum melewati target gaya, meski masih di bawah batas rugi. Jangan entry.';

  @override
  String get adaptiveCompareLimitedBadge => 'Hanya opsi terbatas';

  @override
  String adaptiveCompareLimitedNext(String target) {
    return 'Tunggu setup lain dengan risiko lot minimum maksimal $target; jangan geser stop.';
  }

  @override
  String get adaptiveCompareNoCredit =>
      'Dihitung lokal dari analisis tersimpan, aturan broker, dan candle terkini. Tidak memakai kredit AI tambahan.';

  @override
  String adaptiveCompareRisk(String risk) {
    return 'Risiko lot minimum melewati batas rugi sebesar $risk. Lewati; tambah dana tidak mengatasinya.';
  }

  @override
  String get adaptiveCompareSkip => 'LEWATI';

  @override
  String get adaptiveCompareUnavailable =>
      'Data posisi minimum belum lengkap. Tunggu dan periksa data pasar.';

  @override
  String get adaptiveCompareWait => 'TUNGGU';

  @override
  String get adaptiveConditionalAdditionalFunds =>
      'Tambahan dana bebas yang dibutuhkan';

  @override
  String get adaptiveConditionalAdditionalLoss =>
      'Tambahan batas rugi yang dibutuhkan';

  @override
  String get adaptiveConditionalHelp =>
      'Kandidat ini hanya terblokir oleh dana atau batas rugi yang dimasukkan. Kandidat belum menjadi bagian dari rencana aktif; tinjau ulang hanya setelah input disesuaikan dan chart serta analisis tersimpan dikonfirmasi lagi.';

  @override
  String get adaptiveConditionalManual =>
      'Tetap manual: harga bergerak melawan posisi saja bukan pemicu.';

  @override
  String get adaptiveConditionalOverviewHelp =>
      'Analisis belum mendukung entry sekarang. Pilih Buy atau Sell untuk meninjau level, lot, margin, dan risikonya sebagai skenario bersyarat, bukan instruksi order.';

  @override
  String get adaptiveConditionalTitle => 'Rencana finansial bersyarat';

  @override
  String get adaptiveConditionalTotalFunds =>
      'Total dana yang dibutuhkan di SL final';

  @override
  String get adaptiveConditionalTotalRisk => 'Total risiko di SL final';

  @override
  String adaptiveContextFundamental(
    String events,
    String highImpact,
    String news,
  ) {
    return 'Snapshot fundamental: $news berita, $events agenda ekonomi, $highImpact berdampak tinggi.';
  }

  @override
  String get adaptiveContextFundamentalUnavailable =>
      'Snapshot fundamental tidak tersedia untuk analisis ini.';

  @override
  String get adaptiveContextMissing => 'Konteks belum tersedia';

  @override
  String adaptiveContextTechnical(String buy, String neutral, String sell) {
    return 'Snapshot teknikal: $buy mendukung naik, $sell mendukung turun, $neutral netral.';
  }

  @override
  String get adaptiveContractMicroAssumption =>
      'Micro adalah asumsi 1/10 Mini, termasuk USD 0,50/poin untuk indeks; bukan aturan resmi broker. Nilai Mini dan Regular berasal dari tabel broker yang diberikan.';

  @override
  String adaptiveContractMinimumBasis(String lot) {
    return 'Kontrak tambahan mengikuti ukuran lot tier: lot posisi ÷ lot minimum $lot. Contract size tidak dikalikan lot sekali lagi.';
  }

  @override
  String get adaptiveContractTableTitle =>
      'Nilai kontrak per tier akun (untuk satu posisi minimum)';

  @override
  String get adaptiveContractTier => 'Tier';

  @override
  String get adaptiveContractValue => 'Nilai kontrak';

  @override
  String get adaptiveCopy => 'Salin Adaptive Plan';

  @override
  String get adaptiveCopyBlocked => 'Penyalinan tidak tersedia';

  @override
  String get adaptiveCopyFailed => 'Gagal menyalin';

  @override
  String get adaptiveCopySuccess => 'Berhasil disalin';

  @override
  String get adaptiveCopyTitle => 'TradePilot.id — Adaptive Plan';

  @override
  String get adaptiveDecisionTitle => 'Keputusan Adaptive';

  @override
  String get adaptiveDirectionHelp =>
      'Buy dan Sell memakai level dari rencana tersimpan masing-masing. Pilih arah yang ingin diperiksa; tidak ada order yang dijalankan otomatis.';

  @override
  String adaptiveDirectionUnavailable(String side) {
    return '$side tidak tersedia karena analisis tersimpan belum menyediakan entry dan Stop Loss final yang lengkap untuk arah tersebut.';
  }

  @override
  String get adaptiveDisclaimer =>
      'Skenario Buy/Sell adalah bahan pertimbangan, bukan perintah posisi, bukan jaminan profit atau order otomatis. TradePilot.id tidak mengeksekusi transaksi; cek data terbaru dan putuskan sendiri.';

  @override
  String get adaptiveExternalLiquidation =>
      'Spread, gap harga, selisih eksekusi, pajak, dan aturan broker tetap dapat menambah risiko. Rencana ini tidak menghitung posisi overnight.';

  @override
  String get adaptiveFillUncertain =>
      'Hanya entry yang terisi yang dihitung. Ini estimasi bruto pada level tertera, bukan jaminan fill atau hasil bersih; spread, biaya, slippage, dan likuidasi lebih awal dapat mengubah hasil.';

  @override
  String adaptiveFillValues(
    String loss,
    String lossPercent,
    String lots,
    String margin,
    String positions,
    String profit,
    String profitPercent,
  ) {
    return '$positions posisi · $lots lot · margin $margin · rugi di SL $loss ($lossPercent% dari dana bebas) · profit bruto TP2 $profit ($profitPercent% dari dana bebas)';
  }

  @override
  String get adaptiveGuideChartCaption =>
      'Grafik memakai candle historis hingga waktu analisis dan level Standard Plan yang tersimpan. Keputusan Adaptive dijelaskan terpisah di bawah; ini bukan harga live.';

  @override
  String get adaptiveGuideChartScenario => 'Skenario analisis';

  @override
  String get adaptiveGuideChartUnavailable =>
      'Grafik pada waktu analisis ini tidak tersedia. Panduan tetap bisa dicetak tanpa menggantinya dengan grafik hari ini.';

  @override
  String get adaptiveGuideDirectionTitle => 'Skenario Adaptive yang ditinjau';

  @override
  String get adaptiveGuideDisclaimer =>
      'TradePilot.id adalah alat analisis pasar, bukan broker — kami tidak membuka, menutup, atau mengelola posisi Anda. Laporan ini merangkum temuan dan skenario Buy/Sell berdasarkan data saat analisis dibuat; bukan ajakan bertransaksi, bukan jaminan profit, dan bukan order otomatis. Pasar dapat berubah sewaktu-waktu — periksa kondisi terkini dan ambil keputusan sendiri sebelum bertindak.';

  @override
  String get adaptiveGuideDisclaimerTitle => 'Catatan penting';

  @override
  String get adaptiveGuideNoPlan =>
      'Plan Adaptive belum dihitung untuk analisis ini. Belum ada arah Buy atau Sell yang bisa disebut siap.';

  @override
  String adaptiveGuideOpening(String instrument, String timeframe) {
    return 'Ringkasan kondisi $instrument pada timeframe $timeframe saat analisis dibuat, beserta dasar keputusan plan Adaptive.';
  }

  @override
  String get adaptiveGuidePreparing =>
      'Menyiapkan panduan dan grafik analisis…';

  @override
  String adaptiveGuideReviewStatus(String side) {
    return 'Skenario $side untuk ditinjau, bukan instruksi entry';
  }

  @override
  String get adaptiveGuideStoresNote =>
      'Aplikasi TradePilot.id akan tersedia di Play Store dan App Store setelah proses rilis selesai.';

  @override
  String get adaptiveGuideTitle => 'Laporan Analisis & Rencana Posisi Adaptive';

  @override
  String get adaptiveGuideVisitTitle => 'Lanjutkan di TradePilot.id';

  @override
  String get adaptiveIfAllFilled => 'Jika semua entry terisi';

  @override
  String get adaptiveInsightsTitle => 'Detail plan';

  @override
  String get adaptiveInvalidDescription =>
      'Belum ada sisi yang memiliki plan aman dan disetujui. Periksa status dan angka lot minimum tiap sisi di bawah; angka diagnostik bukan plan entry yang valid. Ubah input finansial hanya jika terjangkau dan dapat diterima secara mandiri, atau tunggu/skip.';

  @override
  String get adaptiveInvalidTitle => 'Belum ada rencana yang aman';

  @override
  String adaptiveInvalidationCue(String count) {
    return '$count kondisi batal';
  }

  @override
  String get adaptiveLayerCheckpoint =>
      'Checkpoint manual: tambah posisi hanya jika chart terbaru mengonfirmasi level ini dan setup masih valid.';

  @override
  String get adaptiveLayerExceedsFunds => 'Melebihi dana tersedia';

  @override
  String get adaptiveLayerPlanTitle => 'Plan layer manual';

  @override
  String adaptiveLayerShortfall(String amount) {
    return 'Kekurangan: $amount';
  }

  @override
  String get adaptiveLevel => 'Posisi';

  @override
  String get adaptiveLot => 'lot';

  @override
  String get adaptiveMarginRequired => 'Margin yang dipakai';

  @override
  String adaptiveMinimumActionBoth(String funds, String loss) {
    return 'Hanya jika terjangkau dan dapat diterima secara mandiri: dana bebas perlu naik $funds dan batas rugi keras naik $loss, lalu hitung ulang. Jika tidak, tunggu atau skip.';
  }

  @override
  String adaptiveMinimumActionFunds(String amount) {
    return 'Hanya jika dana tersebut benar-benar tersedia: masukkan tambahan dana bebas minimal $amount, lalu hitung ulang. Jika tidak, tunggu atau skip; ini bukan instruksi entry.';
  }

  @override
  String adaptiveMinimumActionLoss(String amount) {
    return 'Hanya jika kamu menerima risiko yang lebih besar secara mandiri: naikkan batas rugi keras minimal $amount, lalu hitung ulang. Jika tidak, tunggu atau skip.';
  }

  @override
  String get adaptiveMinimumActionReanalysis =>
      'Langkah berikutnya: tunggu analisis baru yang lengkap; perubahan dana tidak dapat menyelesaikan guardrail analisis.';

  @override
  String get adaptiveMinimumBlockerAnalysis =>
      'Analisis tersimpan belum mendukung posisi baru dalam kondisi saat ini.';

  @override
  String adaptiveMinimumBlockerBoth(String budget, String funds, String risk) {
    return 'Lot minimum melampaui kedua batas: perlu tambahan dana bebas $funds dan rugi di SL ($risk) melebihi budget efektif ($budget).';
  }

  @override
  String get adaptiveMinimumBlockerDirection =>
      'Snapshot teknikal tersimpan bertentangan dengan arah pasar; input finansial tidak dapat melewati guardrail ini.';

  @override
  String adaptiveMinimumBlockerMargin(String amount) {
    return 'Posisi minimum membutuhkan tambahan dana bebas $amount untuk menutup margin day dan rugi pada SL tersimpan.';
  }

  @override
  String adaptiveMinimumBlockerRisk(String budget, String risk) {
    return 'Rugi lot minimum ($risk) melebihi budget rugi efektif ($budget).';
  }

  @override
  String adaptiveMinimumNumbers(
    String budget,
    String margin,
    String risk,
    String total,
  ) {
    return 'Margin day lot minimum: $margin · rugi pada SL final tersimpan: $risk · budget rugi efektif: $budget · dana bebas yang dibutuhkan di SL: $total.';
  }

  @override
  String adaptiveMinimumTier(String lot, String tier) {
    return 'Tier akun: $tier · minimum tier: $lot lot.';
  }

  @override
  String adaptiveNextBlocked(String position, String reason) {
    return 'Posisi $position belum masuk plan: $reason';
  }

  @override
  String adaptiveNextFunds(
    String amount,
    String lot,
    String position,
    String price,
  ) {
    return 'Posisi $position · $price · $lot lot: perkiraan perlu tambahan dana bebas broker $amount untuk ditinjau.';
  }

  @override
  String get adaptiveNextFundsNotEnough =>
      'Tambah dana saja tidak mengatasi batas rugi.';

  @override
  String get adaptiveNextFundsNote =>
      'Belum masuk plan saat ini. Jika dana itu benar-benar tersedia di broker, perbarui modal trading di atas dan hitung ulang; cek lagi chart dan risiko. Ini bukan top up kredit analisis TradePilot.';

  @override
  String get adaptiveNoFixedCap => 'tanpa batas buatan Adaptive';

  @override
  String get adaptivePositionSingular => 'posisi';

  @override
  String get adaptivePostureEntryOnly =>
      'Dari kondisi yang terekam, baru entry awal yang bisa dipertimbangkan. Tunda layer tambahan sampai ada analisis baru yang lebih jelas.';

  @override
  String get adaptivePostureNotRecommended =>
      'Sinyal utamanya belum searah. Lebih aman tidak menambah layer sampai analisis baru memberi arah yang lebih jelas.';

  @override
  String get adaptivePostureScalingAllowed =>
      'Analisis masih memberi ruang untuk menambah posisi, tetapi setiap layer perlu konfirmasi baru. Harga yang bergerak melawan posisi saja bukan alasan untuk masuk.';

  @override
  String get adaptiveReady =>
      'Masukkan modal trading dan batas rugi. Perhitungan memakai nilai tersebut secara langsung.';

  @override
  String get adaptiveReasonContextUnavailable =>
      'Konteks analisis belum lengkap, sehingga sistem tidak menyarankan layer tambahan.';

  @override
  String get adaptiveReasonDirectionalConflict =>
      'Bias pasar dan snapshot teknikal saling bertentangan. Rencana ber-layer ditolak agar tidak menambah lot dalam kondisi yang tidak jelas.';

  @override
  String get adaptiveReasonFundamentalClear =>
      'Tidak ada katalis fundamental besar dalam snapshot analisis ini.';

  @override
  String adaptiveReasonFundamentalHighImpact(String count) {
    return 'Ada $count agenda ekonomi berdampak tinggi. Jumlah layer dikurangi dan setiap checkpoint tersisa wajib diperiksa ulang.';
  }

  @override
  String adaptiveReasonFundamentalPresent(String events, String news) {
    return 'Sebanyak $news berita dan $events agenda ekonomi dipertimbangkan sebagai konteks, tanpa mengarang arah yang tidak disebutkan analisis.';
  }

  @override
  String get adaptiveReasonFundamentalUnavailable =>
      'Konteks fundamental tidak tersedia, sehingga sistem tidak menebak arah dari berita.';

  @override
  String get adaptiveReasonHighRisk =>
      'Analisis tersimpan menandai risiko tinggi. Ini mengurangi kepadatan dan ukuran checkpoint, tetapi tidak otomatis membatalkan gaya rencana yang dipilih.';

  @override
  String adaptiveReasonLowConfidence(String confidence) {
    return 'Confidence analisis hanya sampai $confidence%. Penambahan posisi dikurangi, sedangkan batas keras margin dan Stop Loss tetap berlaku.';
  }

  @override
  String get adaptiveReasonNeutralBias =>
      'Bias tersimpan netral. Sisi pilihan Standard Plan masih dapat ditinjau, tetapi dengan layer lebih sedikit atau lebih kecil.';

  @override
  String get adaptiveReasonRangeSupportsScaling =>
      'Market ranging masih memberi ruang untuk layer terkontrol selama Stop Loss tetap dipatuhi.';

  @override
  String adaptiveReasonShortTimeframe(String timeframe) {
    return 'Timeframe $timeframe sangat singkat dan lebih mudah terkena noise harga, sehingga checkpoint dipertimbangkan lebih sedikit dan lebih kecil.';
  }

  @override
  String get adaptiveReasonStagedAddCondition =>
      'Sebelum tambah layer, cek level sudah tersentuh, setup masih valid, belum ada invalidation, dan tidak ada risiko fundamental baru. Harga bergerak melawan posisi saja bukan alasan untuk entry.';

  @override
  String get adaptiveReasonTechnicalMixed =>
      'Sinyal teknikal bercampur. Layer dipertimbangkan lebih sedikit atau lebih kecil dan setiap checkpoint perlu konfirmasi chart terbaru.';

  @override
  String adaptiveReasonTechnicalSupportsBuy(String buy, String sell) {
    return 'Snapshot teknikal lebih mendukung naik ($buy vs $sell), sehingga konfirmasi mengarah ke Buy.';
  }

  @override
  String adaptiveReasonTechnicalSupportsSell(String buy, String sell) {
    return 'Snapshot teknikal lebih mendukung turun ($sell vs $buy), sehingga konfirmasi mengarah ke Sell.';
  }

  @override
  String get adaptiveReasonTechnicalUnavailable =>
      'Snapshot teknikal tidak tersedia untuk timeframe ini, sehingga sistem tidak menganggapnya sebagai dukungan scaling.';

  @override
  String get adaptiveReasonTrendFavorsBuy =>
      'Bias dan kondisi pasar lebih mendukung skenario naik. Layer tambahan hanya dipertimbangkan untuk sisi Buy.';

  @override
  String get adaptiveReasonTrendFavorsSell =>
      'Bias dan kondisi pasar lebih mendukung skenario turun. Layer tambahan hanya dipertimbangkan untuk sisi Sell.';

  @override
  String get adaptiveReasonTrendOpposesBuy =>
      'Skenario Buy berlawanan dengan arah utama, sehingga tidak mendapat layer tambahan.';

  @override
  String get adaptiveReasonTrendOpposesSell =>
      'Skenario Sell berlawanan dengan arah utama, sehingga tidak mendapat layer tambahan.';

  @override
  String get adaptiveReasonVolatileMarket =>
      'Analisis tersimpan menandai pasar volatil. Checkpoint dibuat lebih hati-hati, bukan otomatis dihapus semua.';

  @override
  String get adaptiveReasoningTitle => 'Kenapa plan ini dipilih';

  @override
  String get adaptiveRefreshRules => 'Coba lagi aturan trading';

  @override
  String get adaptiveRejectedAnalysis =>
      'Analisis tersimpan dan gaya rencana saat ini tidak mendukung checkpoint sedalam ini.';

  @override
  String get adaptiveRejectedBadge => 'Tidak dipakai';

  @override
  String get adaptiveRejectedHelp =>
      'Level ini ditampilkan agar hitungannya transparan, tetapi tidak masuk plan yang disarankan.';

  @override
  String get adaptiveRejectedLoss =>
      'Checkpoint ini akan melewati batas keras akumulasi rugi pada satu Stop Loss final.';

  @override
  String get adaptiveRejectedMargin =>
      'Checkpoint ini membutuhkan dana bebas lebih untuk menutup margin day dan rugi di Stop Loss final.';

  @override
  String get adaptiveRejectedTier =>
      'Posisi ini sendiri akan melewati batas lot per posisi pada tier akun yang dipilih.';

  @override
  String get adaptiveRejectedTitle => 'Kandidat layer yang tidak dipakai';

  @override
  String adaptiveRiskBudgetRate(String rate) {
    return '$rate% dari batas rugi setelah guardrail';
  }

  @override
  String adaptiveRiskStyleActive(String style) {
    return 'Gaya $style';
  }

  @override
  String adaptiveRiskStyleAggressiveDesc(String maximum) {
    return 'Dapat memakai sampai 100% batas rugi dan memberi porsi initial lebih besar; maksimum $maximum lot per posisi tetap berlaku.';
  }

  @override
  String get adaptiveRiskStyleAggressiveDescUncapped =>
      'Dapat memakai sampai 100% batas rugi dan memberi porsi initial lebih besar; dana bebas dan risiko Stop Loss tetap membatasi posisi.';

  @override
  String get adaptiveRiskStyleBalanced => 'Moderat';

  @override
  String get adaptiveRiskStyleBalancedDesc =>
      'Memakai maksimal 75% batas rugi dengan pembagian moderat untuk seluruh layer.';

  @override
  String get adaptiveRiskStyleConservativeDesc =>
      'Memakai maksimal 50% batas rugi, dengan initial lebih kecil dan cadangan layer lebih besar.';

  @override
  String get adaptiveRulesError =>
      'Rekomendasi posisi tidak tersedia: TP Standard Trading Rules untuk instrumen ini tidak dapat dimuat atau belum lengkap. Jangan memperkirakan margin, ukuran kontrak, atau minimum pergerakan sendiri.';

  @override
  String get adaptiveRulesLoading => 'Menyiapkan aturan margin standar…';

  @override
  String get adaptiveScenariosReviewHelp =>
      'Status di bawah menunjukkan apakah setup masih menunggu atau terblokir, bukan instruksi Entry. Keputusan akhir tetap di tangan kamu.';

  @override
  String get adaptiveShareAudienceNote =>
      'Angka lot, margin, dan batas rugi mengikuti input akun ini — tidak berlaku otomatis untuk akun lain.';

  @override
  String get adaptiveShareFailed =>
      'Gagal membagikan detail Adaptive. Coba lagi.';

  @override
  String adaptiveShareInvalidation(String count) {
    return '$count kondisi pembatalan dari analisis tersimpan. Rinciannya ada di bawah.';
  }

  @override
  String get adaptiveShareSnapshotNote =>
      'Laporan ini mencatat kondisi pasar saat analisis dibuat, bukan harga live — periksa kondisi terkini sebelum bertindak.';

  @override
  String get adaptiveShareSummaryCopied => 'Gambar plan disalin';

  @override
  String get adaptiveShareSummaryCopy => 'Salin gambar plan';

  @override
  String get adaptiveShareSummaryDownloaded => 'PNG plan diunduh';

  @override
  String get adaptiveShareSummaryFailed =>
      'Gambar plan tidak dapat dibuat. Coba lagi.';

  @override
  String get adaptiveShareSummaryMenu => 'Bagikan plan';

  @override
  String adaptiveSideBlocked(String side) {
    return '$side belum aman pada lot minimum broker.';
  }

  @override
  String adaptiveSideConditional(String side) {
    return '$side dapat dihitung, tetapi arah entry belum dikonfirmasi analisis. Lihat skenario bersyaratnya di bawah.';
  }

  @override
  String get adaptiveSideEntryOnly =>
      'Skenario ini hanya untuk entry awal; tidak ada layer tambahan yang direkomendasikan.';

  @override
  String adaptiveSideNotAligned(String side) {
    return '$side belum searah dengan analisis utama; skenarionya hanya untuk dipantau, bukan entry sekarang.';
  }

  @override
  String adaptiveSideReady(String side) {
    return 'Skenario $side layak berdasarkan tier akun dan batas keselamatan yang dipilih.';
  }

  @override
  String adaptiveSideUnavailable(String side) {
    return '$side tidak dapat dinilai karena Entry atau Stop Loss tersimpan belum lengkap.';
  }

  @override
  String get adaptiveSnapshotLayers => 'posisi';

  @override
  String get adaptiveSnapshotLevelsOnly =>
      'Memakai level Standard Plan tersimpan; snapshot candle yang layak tidak tersedia dari analisis ini.';

  @override
  String get adaptiveSnapshotLevelsOnlyDetail =>
      'Analisis lama mungkin tidak menyimpan snapshot candle; feed yang gagal juga bisa membuatnya tidak layak. Adaptive tetap bisa menghitung dari level tersimpan, tetapi tidak bisa mengonfirmasi swing dan volatilitas dari candle. Jalankan analisis baru untuk menangkap dasar datanya bersama.';

  @override
  String get adaptiveSnapshotTotalLots => 'Total lot rencana';

  @override
  String get adaptiveSnapshotUnavailable =>
      'Angka aman belum bisa dihitung dari Entry, Stop Loss, aturan trading, serta batas risiko atau dana saat ini. Cek status sisi di atas; jangan gunakan ini sebagai sinyal Entry.';

  @override
  String adaptiveStageAddReason(
    String basis,
    String distance,
    String level,
    String lot,
    String price,
    String risk,
  ) {
    return 'Checkpoint manual untuk posisi $level di $price. Dasar: $basis. Gunakan hanya jika chart terkini mengonfirmasi skenario tersimpan, invalidation belum terjadi, dan tidak ada risiko fundamental baru. Harga melawan posisi saja bukan pemicu. Ukuran $lot lot mengikuti pola pilihan, tetap dalam batas per posisi, berjarak $distance dari entry, dan menambah sekitar $risk rugi pada SL final.';
  }

  @override
  String get adaptiveStageBasisEntryEdge =>
      'tepi berlawanan dari zona entry analisis tersimpan';

  @override
  String adaptiveStageBasisRiskCheckpoint(String progress) {
    return 'level swing chart terkini pada $progress% jalur entry menuju SL tersimpan';
  }

  @override
  String get adaptiveStageInitialReason => 'Entry dari Standard Plan.';

  @override
  String get adaptiveStepAdd =>
      'Sebelum tambah layer, pastikan harga sudah menyentuh level, setup masih valid, belum ada invalidation, dan tidak ada risiko fundamental baru. Harga bergerak melawan posisi saja bukan alasan menambah.';

  @override
  String get adaptiveStepChoose =>
      'Pilih satu skenario saja—naik atau turun—sesuai keputusan kamu.';

  @override
  String get adaptiveStepEntry =>
      'Entry di level yang tercantum pada trade plan.';

  @override
  String get adaptiveStepStop =>
      'Cut loss jika harga menyentuh Cut Loss / SL. Jangan memindahkan batas ini untuk menahan rugi.';

  @override
  String get adaptiveStopRisk => 'Akumulasi rugi di SL';

  @override
  String get adaptiveTpProfit => 'Estimasi profit';

  @override
  String get adaptiveUnusedReasonLevels =>
      'Zona entry dan chart tidak menyediakan harga tambahan yang berbeda dan bermakna. Satu harga tidak akan dipecah menjadi beberapa tiket.';

  @override
  String get adaptiveUnusedReasonMargin =>
      'Dana bebas harus menutup margin sekaligus rugi di SL; menambah lot di sini akan melampaui batas gabungan itu.';

  @override
  String get adaptiveUnusedReasonPolicy =>
      'Gaya yang dipilih atau kehati-hatian pasar menyisihkan sebagian plafon rugi. Plafon ini bukan target untuk dihabiskan.';

  @override
  String get adaptiveUnusedReasonTier =>
      'Batas lot per posisi akun yang dipilih menahan rencana ini. Tipe akun tidak pernah diganti otomatis.';

  @override
  String adaptiveVolatilityObserved(String count, String range) {
    return 'Rentang tipikal candle: $range dari $count candle timeframe terpilih; ini konteks, bukan jarak Stop Loss wajib.';
  }

  @override
  String adaptiveVolatilityTight(String distance, String side) {
    return 'Jarak SL Standard Plan sisi $side ($distance) lebih kecil dari rentang tipikal candle tersebut. Periksa struktur harga sebelum entry; Stop Loss tersimpan tidak diubah.';
  }

  @override
  String adaptiveVolatilityTightShort(String side) {
    return 'SL $side lebih dekat dari rentang candle — cek struktur harga sebelum entry.';
  }

  @override
  String adaptiveVolatilityTitle(String timeframe) {
    return 'Volatilitas teramati pada $timeframe';
  }

  @override
  String get adaptiveVolatilityUnavailable =>
      'Data candle pembanding tidak tersedia. Jangan menganggap jarak SL ini sesuai timeframe yang dipilih.';

  @override
  String get adaptiveVolatilityUnavailableShort =>
      'Data candle pembanding tidak tersedia — jarak SL belum terkonfirmasi.';

  @override
  String get biasTitle => 'Bias Arah';

  @override
  String chartShareAccessibleLevels(String levels) {
    return 'Level Standard Plan yang digambar: $levels.';
  }

  @override
  String get chartShareAccessibleNoLevels =>
      'Tidak ada level Standard Plan yang digambar.';

  @override
  String chartShareAccessibleRange(String count, String end, String start) {
    return 'Candle historis dari $start sampai $end ($count candle).';
  }

  @override
  String get chartShareAnalyzed => 'Dianalisis';

  @override
  String get chartShareMade => 'Gambar dibuat';

  @override
  String get chartShareSourceNote =>
      'Candle historis diambil saat gambar dibuat dan dibatasi sebelum analisis. Level dan bias berasal dari analisis tersimpan, bukan harga live.';

  @override
  String get chartShareTitle => 'Grafik analisis';

  @override
  String get chartShareWait => 'TUNGGU — tinjau Buy & Sell';

  @override
  String get chartShareWarning =>
      'Level hanya acuan, bukan instruksi entry. Periksa syarat entry, risiko, invalidasi, dan kondisi pasar terkini sebelum bertindak.';

  @override
  String get citationsLabel => 'Sumber yang dirujuk:';

  @override
  String get tradePlanEntry => 'Entry';

  @override
  String get tradePlanSl => 'Stop Loss';

  @override
  String get instrumentPickerHint =>
      'Pilih kode yang tersedia atau ketik kode baru.';

  @override
  String get instrumentRequestSending => 'Mengirim permintaan…';

  @override
  String get instrumentRequestError =>
      'Permintaan instrumen gagal dikirim. Silakan coba lagi.';

  @override
  String get instrumentNoMatch =>
      'Tidak ada instrumen terverifikasi yang cocok. Analisis hanya tersedia untuk pilihan terverifikasi yang ditampilkan.';

  @override
  String get instrumentSourceLimitations =>
      'Analisis baru hanya dapat memilih empat instrumen utama dan empat pasangan FX terverifikasi. Cakupan penyedia serta sumber harga/riwayat bisa terbatas; permintaan tidak menjamin dukungan.';

  @override
  String get instrumentRequestNoCredit =>
      'Mengirim permintaan ini tidak memakai kuota analisis atau kredit. Cakupan bergantung pada sumber data pasar terverifikasi dan mungkin tetap tidak tersedia.';

  @override
  String get instrumentLegacyUnsupported =>
      'Analisis lama ini menggunakan instrumen yang tidak lagi dapat dipilih. Hasil tersimpannya tetap bisa dibaca, tetapi tidak dapat dikirim ulang.';

  @override
  String get instrumentNotVerifiedTitle => 'Instrumen belum terverifikasi';

  @override
  String get instrumentNotVerifiedDesc =>
      'Pilih salah satu instrumen terverifikasi sebelum memulai analisis baru.';

  @override
  String get loadingBtn => 'Memproses';

  @override
  String levelUpTitle(String n) {
    return 'Selamat! Kamu naik ke Level $n!';
  }

  @override
  String get levelUpDescription =>
      'Kedisiplinanmu berkembang. Terus bangun kebiasaan yang konsisten.';

  @override
  String get levelUpCloseLabel => 'Tutup perayaan kenaikan level';

  @override
  String get levelUpWaysLabel => 'Cara naik level';

  @override
  String levelUpHint(String xp) {
    return 'Aktivitas kecil yang konsisten memberi XP. Butuh $xp XP lagi untuk level berikutnya.';
  }

  @override
  String get levelUpJournal => 'Tulis refleksi singkat di jurnal';

  @override
  String get levelUpEvaluation => 'Evaluasi analisis tanpa menambahkan catatan';

  @override
  String get levelUpChecklist => 'Selesaikan checklist pra-analisis';

  @override
  String get levelUpGuide => 'Selesaikan satu artikel panduan';

  @override
  String get levelUpWait => 'Pilih menunggu saat risiko tinggi';

  @override
  String get levelUpStreak => 'Jaga streak harianmu';

  @override
  String levelUpDailyCap(String cap, String xp) {
    return '$xp XP · maksimal $cap/hari';
  }

  @override
  String levelUpPerDay(String xp) {
    return '$xp XP/hari';
  }

  @override
  String get completionPreparing => 'Menyiapkan progres bacaan…';

  @override
  String completionWait(String seconds) {
    return 'Lanjut baca dulu — tombol aktif dalam $seconds detik.';
  }

  @override
  String get completionSaving => 'Menyimpan progres bacaan…';

  @override
  String get completionStartFailed =>
      'Gagal menyiapkan progres bacaan. Coba lagi.';

  @override
  String get alertsArmError =>
      'Alert belum bisa dipasang: instrumen tidak didukung feed live atau analisis tidak punya level yang layak. Pengaturan notifikasi bukan penyebabnya.';

  @override
  String get alertsRetryError =>
      'Alert belum bisa dipasang karena layanan sedang bermasalah. Coba lagi.';

  @override
  String get alertsNoPush =>
      'Notifikasi push belum aktif untuk akun ini. Aktifkan di menu Notifikasi agar alert harga dapat dikirim.';

  @override
  String get alertsEnableNotifications => 'Aktifkan notifikasi';

  @override
  String get fastPlanWaitTitle => 'Belum ada entry sekarang.';

  @override
  String get fastPlanEntryPending => 'Tunggu candle close terkonfirmasi';

  @override
  String get fastPlanSlPending => 'Tentukan setelah swing konfirmasi terbentuk';

  @override
  String get fastPlanTp1Pending => 'Gunakan struktur pasar berikutnya';

  @override
  String get fastPlanTp2Pending => 'Evaluasi ulang setelah TP1';

  @override
  String get fastPlanRrPending =>
      'Hitung setelah entry dan Stop Loss terbentuk';

  @override
  String get adaptiveShareSummaryTitle => 'Ringkasan Adaptive Plan';

  @override
  String get adaptiveShareSummaryWarning =>
      'Acuan dari analisis tersimpan, bukan order. Periksa syarat entry, risiko, kondisi batal, dan pasar terkini sebelum bertindak.';

  @override
  String get biasRiskDisclaimer =>
      'Bias menunjukkan kecenderungan arah dari data yang tersedia, bukan tingkat risiko.';

  @override
  String get riskTitle => 'Risiko Keseluruhan';

  @override
  String get riskOverallNote =>
      'Mencakup teknikal dan berita/kalender jika tersedia; bisa berbeda dari Compare Risk.';

  @override
  String traderMirrorCoverageAll(int resolved) {
    return 'Mencakup seluruh riwayat · $resolved evaluasi selesai';
  }

  @override
  String get themeUpdateFailed =>
      'Gagal menyimpan tema. Tampilan dikembalikan.';

  @override
  String summaryPending(String n) {
    return '$n masih menunggu';
  }

  @override
  String get topupReturnSuccess =>
      'Pembayaran berhasil! Kredit sudah ditambahkan ke saldo kamu.';

  @override
  String get topupReturnProcessing =>
      'Pembayaran sedang diproses. Saldo kamu akan update otomatis begitu selesai.';

  @override
  String get topupReturnCancelled => 'Pembayaran dibatalkan.';

  @override
  String get topupReturnFailed =>
      'Pembayaran gagal. Coba lagi atau hubungi support.';
}
