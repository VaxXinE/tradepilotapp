// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Trade Pilot';

  @override
  String get tradePilotLogo => 'Logo Trade Pilot';

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
      'Gunakan level berikut sebagai struktur risiko, bukan jaminan harga akan bergerak sesuai skenario.';

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
  String get analysisHelpfulQuestion => 'Apakah analisis ini membantu?';

  @override
  String get helpful => 'Membantu';

  @override
  String get notHelpful => 'Kurang Membantu';

  @override
  String get analysisSafetyDisclaimer =>
      'Trade Pilot adalah alat bantu analisis. Selalu batasi risiko dan hindari membuka posisi hanya berdasarkan satu indikator.';

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
      'Instrumen sama, timeframe berbeda — buat analisis baru tanpa keluar dari halaman ini.';

  @override
  String get analyzeThisTimeframe => 'Analisis timeframe ini';

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
  String get analysisSnapshotTitle => 'Konteks Saat Analisis Dibuat';

  @override
  String get analysisSnapshotDescription =>
      'Bagian ini adalah snapshot data yang AI gunakan saat membuat analisis.';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

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
  String get historyPageTitle => 'Riwayat Analisis';

  @override
  String historyTotalAnalyses(int count) {
    return '$count analisis tersimpan';
  }

  @override
  String get profile => 'Profil';

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
      'Rekam jejak anonim seluruh analisis AI Trade Pilot. Ini bukan statistik akun pribadi.';

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
  String get performanceByInstrument => 'Per instrumen';

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
  String get continueWithGoogle => 'Lanjutkan dengan Google';

  @override
  String get googleDeleteReauthDescription =>
      'Untuk melindungi akunmu, verifikasi identitas dengan Google sebelum penghapusan.';

  @override
  String get verifyGoogleAndDelete => 'Verifikasi dengan Google dan hapus';

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
  String get errGoogleSignInFailed =>
      'Gagal masuk dengan Google. Silakan coba lagi.';

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
      'Verifikasi identitasmu untuk masuk ke Trade Pilot';

  @override
  String get biometricUnavailable =>
      'Biometrik tidak tersedia. Gunakan email dan password.';

  @override
  String get createAccount => 'Buat Akun';

  @override
  String get startTradingJourney => 'Mulai perjalanan tradingmu';

  @override
  String get registerDescription =>
      'Buat akun dan sesuaikan analisis dengan pengalamanmu.';

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
      'Informasi dan broadcast penting dari Trade Pilot.';

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
      'Trade Pilot membantu kamu memahami kondisi pasar, tetapi semua keputusan dan pengelolaan risiko tetap menjadi tanggung jawabmu.';

  @override
  String get wantMarketAnalysis => 'Ingin analisis pasar?';

  @override
  String get getStarted => 'Mulai menggunakan Trade Pilot';

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
  String get perHour => 'Per jam';

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
  String get quotaHour => 'Sisa per jam';

  @override
  String get quotaDay => 'Sisa per hari';

  @override
  String get quotaHourShort => '/jam';

  @override
  String get quotaDayShort => '/hari';

  @override
  String get selectInstrument => 'Pilih Instrumen';

  @override
  String get instrumentCategoryCommoditiesIndices => 'Komoditas & Indeks';

  @override
  String get instrumentCategoryForex => 'Valas';

  @override
  String get instrumentCategoryCrypto => 'Kripto';

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
      'Trade Pilot membantu menjelaskan harga, momentum, sesi pasar, dan peristiwa penting dengan bahasa yang lebih sederhana.';

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
  String get searchInstrumentOrNote => 'Cari instrumen atau catatan';

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
  String get historySummary => 'Ringkasan riwayat';

  @override
  String get historyListTab => 'Riwayat';

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
  String get appLocked => 'Trade Pilot terkunci';

  @override
  String get appLockedDescription =>
      'Sesimu masih aktif. Verifikasi identitasmu untuk melanjutkan.';

  @override
  String get unlock => 'Buka Kunci';

  @override
  String get biometricUnlockReason =>
      'Verifikasi identitasmu untuk membuka Trade Pilot';

  @override
  String get unlockFailed =>
      'Identitasmu tidak bisa diverifikasi. Coba lagi atau keluar.';

  @override
  String get biometricLock => 'Kunci biometrik';

  @override
  String get biometricLockOn => 'Minta sidik jari atau wajah setiap app dibuka';

  @override
  String get biometricLockOff => 'Langsung terbuka ke dashboard';

  @override
  String get biometricLockUnavailable =>
      'Belum ada sidik jari atau face unlock di perangkat ini.';

  @override
  String get riskMapTitle => 'Peta Risiko Timeframe';

  @override
  String get riskMapDescription =>
      'Bandingkan risiko teknikal di berbagai timeframe sebelum membuat analisis.';

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
    return 'Gunakan $timeframe';
  }

  @override
  String get standardRulesTitle => 'TP Standard Trading Rules';

  @override
  String get standardRulesDescription =>
      'Aturan broker-neutral yang menjadi dasar estimasi Trade Pilot.';

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
  String get analysisQuotaHourTitle => 'Batas per jam tercapai';

  @override
  String get analysisQuotaHourMessage =>
      'Kuota analisis per jam kamu sudah habis. Coba lagi setelah waktu tunggu berakhir.';

  @override
  String get analysisQuotaDayTitle => 'Batas harian tercapai';

  @override
  String get analysisQuotaDayMessage =>
      'Kuota gratis harian kamu sudah habis. Gunakan credit atau coba lagi besok.';

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
  String analysisQuotaBalances(int hourly, int daily, int credits) {
    return 'Per jam: $hourly • Harian: $daily • Credit: $credits';
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
  String get topUpProofLabel => 'Bukti pembayaran (opsional)';

  @override
  String get topUpAddProof => 'Lampirkan bukti';

  @override
  String get topUpChangeProof => 'Ganti bukti';

  @override
  String get topUpProofAttached => 'Bukti terlampir';

  @override
  String get topUpSubmit => 'Kirim permintaan top-up';

  @override
  String get topUpSubmitted =>
      'Permintaan top-up terkirim. Akan segera ditinjau.';

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
      'Sesi login sudah berakhir. Silakan login kembali.';

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
      'Rekam jejak anonim seluruh analisis Trade Pilot';

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
  String get guideQuickStartHint => 'Tiga panduan untuk memahami alur utama.';

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
  String get riskStyleConservative => 'Konservatif';

  @override
  String get riskStyleBalanced => 'Seimbang';

  @override
  String get riskStyleAggressive => 'Agresif';

  @override
  String get totalLots => 'Total lot';

  @override
  String get marginRequired => 'Margin dibutuhkan';

  @override
  String get estimatedCycleLoss => 'Estimasi rugi siklus';

  @override
  String get adaptiveCopyManualContext =>
      'Gunakan sebagai konteks perencanaan manual, bukan instruksi eksekusi.';

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
}
