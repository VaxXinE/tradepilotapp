import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../providers/auth_provider.dart';
import '../analysis/analysis_detail_screen.dart';

class TradeJournalScreen extends StatefulWidget {
  const TradeJournalScreen({super.key});

  @override
  State<TradeJournalScreen> createState() => _TradeJournalScreenState();
}

class _TradeJournalScreenState extends State<TradeJournalScreen> {
  List<JournalEntry> _entries = const [];
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  int _requestId = 0;
  int? _ownerUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _sameUser(int? userId) {
    if (!mounted) return false;
    final auth = context.read<AuthProvider>();
    return auth.status == AuthStatus.authenticated && auth.user?.id == userId;
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    _ownerUserId ??= userId;
    final requestId = ++_requestId;
    try {
      final response = await auth.client.tradeJournal.listJournalEntries(
        limit: 100,
      );
      if (!_sameUser(userId) || requestId != _requestId) return;
      setState(() {
        _entries = response.data?.entries.toList() ?? const [];
        _error = null;
      });
    } catch (_) {
      if (_sameUser(userId) && requestId == _requestId) {
        setState(() => _error = 'Jurnal belum dapat dimuat. Coba lagi.');
      }
    } finally {
      if (_sameUser(userId) && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openForm([JournalEntry? entry]) async {
    if (_mutating) return;
    final result = await showDialog<_JournalDraft>(
      context: context,
      builder: (_) => _JournalDialog(entry: entry),
    );
    if (result == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final userId = auth.user?.id;
    setState(() => _mutating = true);
    try {
      final JournalEntry? saved;
      if (entry == null) {
        final response = await auth.client.tradeJournal.createJournalEntry(
          createJournalEntryBody: CreateJournalEntryBody(
            (builder) => builder
              ..instrument = result.instrument
              ..side = result.side == 'buy'
                  ? CreateJournalEntryBodySideEnum.buy
                  : CreateJournalEntryBodySideEnum.sell
              ..outcome = CreateJournalEntryBodyOutcomeEnum.valueOf(
                result.outcome,
              )
              ..mood = result.mood
              ..note = result.note
              ..tradedAt = DateTime.now().toUtc(),
          ),
        );
        saved = response.data;
      } else {
        final response = await auth.client.tradeJournal.updateJournalEntry(
          id: entry.id,
          updateJournalEntryBody: UpdateJournalEntryBody(
            (builder) => builder
              ..instrument = result.instrument
              ..side = result.side == 'buy'
                  ? UpdateJournalEntryBodySideEnum.buy
                  : UpdateJournalEntryBodySideEnum.sell
              ..outcome = UpdateJournalEntryBodyOutcomeEnum.valueOf(
                result.outcome,
              )
              ..mood = result.mood
              ..note = result.note,
          ),
        );
        saved = response.data;
      }
      final savedEntry = saved;
      if (!_sameUser(userId) || savedEntry == null) return;
      setState(() {
        final index = _entries.indexWhere((item) => item.id == savedEntry.id);
        if (index < 0) {
          _entries = [savedEntry, ..._entries];
        } else {
          final updated = [..._entries];
          updated[index] = savedEntry;
          _entries = updated;
        }
        _error = null;
      });
    } catch (_) {
      if (mounted && _sameUser(userId)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Entri jurnal gagal disimpan.')),
        );
      }
    } finally {
      if (_sameUser(userId)) setState(() => _mutating = false);
    }
  }

  Future<void> _delete(JournalEntry entry) async {
    if (_mutating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus entri jurnal?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final userId = auth.user?.id;
    setState(() => _mutating = true);
    try {
      await auth.client.tradeJournal.deleteJournalEntry(id: entry.id);
      if (mounted && _sameUser(userId)) {
        setState(
          () =>
              _entries = _entries.where((item) => item.id != entry.id).toList(),
        );
      }
    } catch (_) {
      if (_sameUser(userId)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Entri jurnal gagal dihapus.')),
        );
      }
    } finally {
      if (_sameUser(userId)) setState(() => _mutating = false);
    }
  }

  String _outcome(JournalEntryOutcomeEnum outcome) => switch (outcome.name) {
    'win' => 'Outcome positif',
    'loss' => 'Outcome negatif',
    'breakeven' => 'Impas',
    'skipped' => 'Tidak diambil',
    _ => 'Masih terbuka',
  };

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    if (_ownerUserId != null && currentUserId != _ownerUserId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trade Journal')),
        body: const Center(
          child: Text('Sesi berubah. Buka kembali halaman ini.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Trade Journal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mutating ? null : () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _entries.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null && _entries.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(child: Text(_error!)),
                  Center(
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Coba lagi'),
                    ),
                  ),
                ],
              )
            : _entries.isEmpty
            ? ListView(
                padding: EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 140),
                  Icon(Icons.menu_book_outlined, size: 52),
                  SizedBox(height: 12),
                  Text('Belum ada entri jurnal.', textAlign: TextAlign.center),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: _entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Maksimum 100 entri terbaru dari server. Data ini bersifat pribadi.',
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  final entry = _entries[index - 1];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${entry.instrument} · ${entry.side.name.toUpperCase()}',
                      ),
                      subtitle: Text(
                        '${_outcome(entry.outcome)} · ${DateFormat('dd MMM yyyy, HH:mm').format(entry.tradedAt.toLocal())}'
                        '${entry.note?.trim().isNotEmpty == true ? '\n${entry.note}' : ''}',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      onTap: entry.analysisId == null
                          ? () => _openForm(entry)
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AnalysisDetailScreen(
                                  analysisId: entry.analysisId!,
                                ),
                              ),
                            ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            value == 'edit' ? _openForm(entry) : _delete(entry),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _JournalDraft {
  const _JournalDraft(
    this.instrument,
    this.side,
    this.outcome,
    this.mood,
    this.note,
  );
  final String instrument;
  final String side;
  final String outcome;
  final String? mood;
  final String? note;
}

class _JournalDialog extends StatefulWidget {
  const _JournalDialog({this.entry});
  final JournalEntry? entry;

  @override
  State<_JournalDialog> createState() => _JournalDialogState();
}

class _JournalDialogState extends State<_JournalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instrument;
  late final TextEditingController _mood;
  late final TextEditingController _note;
  late String _side;
  late String _outcome;

  @override
  void initState() {
    super.initState();
    _instrument = TextEditingController(text: widget.entry?.instrument ?? '');
    _mood = TextEditingController(text: widget.entry?.mood ?? '');
    _note = TextEditingController(text: widget.entry?.note ?? '');
    _side = widget.entry?.side.name ?? 'buy';
    _outcome = widget.entry?.outcome.name ?? 'open';
  }

  @override
  void dispose() {
    _instrument.dispose();
    _mood.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entry == null ? 'Tambah jurnal' : 'Edit jurnal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _instrument,
                maxLength: 32,
                decoration: const InputDecoration(labelText: 'Instrumen'),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Instrumen wajib diisi.'
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _side,
                decoration: const InputDecoration(labelText: 'Sisi'),
                items: const [
                  DropdownMenuItem(
                    value: 'buy',
                    child: Text('Buy (catatan transaksi)'),
                  ),
                  DropdownMenuItem(
                    value: 'sell',
                    child: Text('Sell (catatan transaksi)'),
                  ),
                ],
                onChanged: (value) => _side = value!,
              ),
              DropdownButtonFormField<String>(
                initialValue: _outcome,
                decoration: const InputDecoration(
                  labelText: 'Status retrospektif',
                ),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Masih terbuka')),
                  DropdownMenuItem(
                    value: 'win',
                    child: Text('Outcome positif'),
                  ),
                  DropdownMenuItem(
                    value: 'loss',
                    child: Text('Outcome negatif'),
                  ),
                  DropdownMenuItem(value: 'breakeven', child: Text('Impas')),
                  DropdownMenuItem(
                    value: 'skipped',
                    child: Text('Tidak diambil'),
                  ),
                ],
                onChanged: (value) => _outcome = value!,
              ),
              TextField(
                controller: _mood,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Kondisi diri (opsional)',
                ),
              ),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 5,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Refleksi (opsional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _JournalDraft(
                _instrument.text.trim().toUpperCase(),
                _side,
                _outcome,
                _mood.text.trim().isEmpty ? null : _mood.text.trim(),
                _note.text.trim().isEmpty ? null : _note.text.trim(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
