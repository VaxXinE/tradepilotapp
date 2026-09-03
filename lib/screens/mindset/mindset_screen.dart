import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../l10n/l10n.dart';

class MindsetScreen extends StatelessWidget {
  const MindsetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final id = context.watch<LocaleController>().locale.languageCode == 'id';
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.traderMindset)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _modules.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _modules.length) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                context.l10n.mindsetDisclaimer,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }
          final module = _modules[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(id ? module.titleId : module.titleEn),
              subtitle: Text(id ? module.summaryId : module.summaryEn),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _MindsetModuleScreen(module: module, id: id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MindsetModuleScreen extends StatelessWidget {
  const _MindsetModuleScreen({required this.module, required this.id});
  final _MindsetModule module;
  final bool id;

  @override
  Widget build(BuildContext context) {
    final points = id ? module.pointsId : module.pointsEn;
    return Scaffold(
      appBar: AppBar(title: Text(id ? module.titleId : module.titleEn)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            id ? module.bodyId : module.bodyEn,
            style: const TextStyle(fontSize: 16, height: 1.55),
          ),
          const SizedBox(height: 18),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(point, style: const TextStyle(height: 1.45)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MindsetModule {
  const _MindsetModule({
    required this.titleEn,
    required this.titleId,
    required this.summaryEn,
    required this.summaryId,
    required this.bodyEn,
    required this.bodyId,
    required this.pointsEn,
    required this.pointsId,
  });
  final String titleEn;
  final String titleId;
  final String summaryEn;
  final String summaryId;
  final String bodyEn;
  final String bodyId;
  final List<String> pointsEn;
  final List<String> pointsId;
}

const _modules = [
  _MindsetModule(
    titleEn: 'FOMO — Trading Late on a Move',
    titleId: 'FOMO — Telat Masuk Saat Harga Sudah Jalan',
    summaryEn:
        'Why chasing breakouts hurts and how to wait for second chances.',
    summaryId:
        'Kenapa mengejar breakout sering merugikan dan cara menunggu peluang kedua.',
    bodyEn:
        'FOMO is the urge to enter after a move has started because you fear missing the rest. When a move already feels obvious, the impulse may be close to exhaustion.',
    bodyId:
        'FOMO adalah dorongan masuk setelah harga bergerak karena takut ketinggalan. Saat pergerakan sudah terasa sangat jelas, impulsnya bisa hampir selesai.',
    pointsEn: [
      'Accept that missing moves is normal.',
      'Wait for a pullback to clear structure.',
      'If it never comes, let the trade go.',
    ],
    pointsId: [
      'Terima bahwa melewatkan pergerakan itu normal.',
      'Tunggu pullback ke struktur yang jelas.',
      'Jika tidak datang, lepaskan trade tersebut.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Revenge Trading — Trying to Win It Back',
    titleId: 'Revenge Trading — Memaksa Balik Modal',
    summaryEn: 'Recognize the most expensive emotion, then stop.',
    summaryId: 'Kenali salah satu emosi termahal dalam trading, lalu berhenti.',
    bodyEn:
        'Revenge trading means opening a trade after a loss to recover money rather than because the setup matches your plan.',
    bodyId:
        'Revenge trading berarti membuka posisi setelah rugi untuk mengembalikan uang, bukan karena setup sesuai rencana.',
    pointsEn: [
      'After two losses, take a 30-minute break.',
      'After three daily losses, stop for the day.',
      'Never raise size to win it back.',
    ],
    pointsId: [
      'Setelah dua rugi, istirahat 30 menit.',
      'Setelah tiga rugi sehari, berhenti untuk hari itu.',
      'Jangan menaikkan ukuran untuk balas kerugian.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Loss Aversion — Holding Losers Too Long',
    titleId: 'Loss Aversion — Menahan Kerugian Terlalu Lama',
    summaryEn: 'Why losses feel stronger than equivalent gains.',
    summaryId: 'Mengapa rugi terasa lebih kuat daripada untung yang setara.',
    bodyEn:
        'Loss aversion often makes traders close winners early and keep losers open in hope. A planned small loss can then become a large one.',
    bodyId:
        'Loss aversion sering membuat trader menutup profit terlalu cepat dan menahan rugi dengan harapan. Kerugian kecil yang direncanakan akhirnya membesar.',
    pointsEn: [
      'Set the stop before entry.',
      'Treat the stop as a rule.',
      'Use smaller size if accepting the loss is difficult.',
    ],
    pointsId: [
      'Tentukan stop sebelum entry.',
      'Perlakukan stop sebagai aturan.',
      'Gunakan ukuran lebih kecil jika sulit menerima rugi.',
    ],
  ),
  _MindsetModule(
    titleEn: "Anchoring — 'It Was Cheaper Yesterday'",
    titleId: "Anchoring — 'Kemarin Lebih Murah'",
    summaryEn: 'Your entry price matters less than current evidence.',
    summaryId: 'Harga entry tidak lebih penting dari bukti pasar saat ini.',
    bodyEn:
        'Anchoring means holding onto a reference price and ignoring new information. The market does not know your entry price.',
    bodyId:
        'Anchoring berarti terpaku pada harga referensi dan mengabaikan informasi baru. Pasar tidak mengetahui harga entry kamu.',
    pointsEn: [
      'Reassess current evidence.',
      'Ask whether you would open the same trade now.',
      'Exit when the original thesis is invalid.',
    ],
    pointsId: [
      'Nilai ulang bukti terbaru.',
      'Tanya apakah kamu akan membuka trade yang sama sekarang.',
      'Keluar saat tesis awal tidak berlaku.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Risk First — Position Sizing Mindset',
    titleId: 'Risiko Dulu — Mindset Ukuran Posisi',
    summaryEn: 'Discipline starts with position size.',
    summaryId: 'Disiplin dimulai dari ukuran posisi.',
    bodyEn:
        'Think first about how much you can lose, then entry, then target. Position size must follow the risk limit—not the desired profit.',
    bodyId:
        'Pikirkan dulu berapa maksimal kerugian, lalu entry, kemudian target. Ukuran posisi mengikuti batas risiko, bukan target profit.',
    pointsEn: [
      'Define account risk per trade.',
      'Calculate size from entry and stop.',
      'Skip setups that require excessive risk.',
    ],
    pointsId: [
      'Tentukan risiko akun per trade.',
      'Hitung ukuran dari entry dan stop.',
      'Lewati setup yang membutuhkan risiko berlebihan.',
    ],
  ),
  _MindsetModule(
    titleEn: "Plan vs Prediction — You Don't Need to Be Right",
    titleId: 'Rencana vs Prediksi — Tidak Harus Selalu Benar',
    summaryEn: 'Good risk management matters more than prediction.',
    summaryId: 'Manajemen risiko yang baik lebih penting daripada prediksi.',
    bodyEn:
        'Trading is not only predicting direction. It is managing the position consistently when you are right and when you are wrong.',
    bodyId:
        'Trading bukan hanya memprediksi arah. Trading adalah mengelola posisi secara konsisten saat benar maupun salah.',
    pointsEn: [
      'Define scenarios before entry.',
      'Let winners exceed planned losses.',
      'Judge process, not one outcome.',
    ],
    pointsId: [
      'Tentukan skenario sebelum entry.',
      'Biarkan profit melebihi rugi terencana.',
      'Nilai proses, bukan satu outcome.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Journaling — Your Most Valuable Tool',
    titleId: 'Journaling — Alat Refleksi Terpenting',
    summaryEn: "What you don't measure, you can't improve.",
    summaryId: 'Yang tidak diukur sulit diperbaiki.',
    bodyEn:
        'Record the instrument, timeframe, entry and exit reason, emotions, and what you would change. Patterns become visible over time.',
    bodyId:
        'Catat instrumen, timeframe, alasan masuk dan keluar, emosi, serta hal yang akan diubah. Pola akan terlihat seiring waktu.',
    pointsEn: [
      'Journal every executed trade.',
      'Separate planned and impulse trades.',
      'Review patterns weekly.',
    ],
    pointsId: [
      'Jurnalkan setiap trade.',
      'Pisahkan trade terencana dan impulsif.',
      'Tinjau pola setiap minggu.',
    ],
  ),
  _MindsetModule(
    titleEn: 'Patience — Doing Nothing Is a Trade',
    titleId: 'Sabar — Diam Juga Sebuah Keputusan',
    summaryEn: 'Staying in cash is a valid position.',
    summaryId: 'Tetap memegang cash adalah posisi yang valid.',
    bodyEn:
        'High-quality setups are uncommon. Trading every market condition exposes the account to noise where the edge is weak.',
    bodyId:
        'Setup berkualitas tinggi tidak sering muncul. Trading di setiap kondisi membuat akun terpapar noise saat edge lemah.',
    pointsEn: [
      'Wait for conditions in your plan.',
      'Do not confuse activity with progress.',
      'A skipped weak setup protects capital.',
    ],
    pointsId: [
      'Tunggu kondisi yang sesuai rencana.',
      'Jangan samakan sibuk dengan kemajuan.',
      'Melewatkan setup lemah melindungi modal.',
    ],
  ),
];
