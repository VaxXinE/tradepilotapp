import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:one_of/one_of.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../analysis/analysis_detail_screen.dart';

class TradeJournalScreen extends StatefulWidget {
  const TradeJournalScreen({super.key, this.analysis, this.initialEntry});

  final Analysis? analysis;
  final JournalEntry? initialEntry;

  @override
  State<TradeJournalScreen> createState() => _TradeJournalScreenState();
}

class _TradeJournalScreenState extends State<TradeJournalScreen> {
  List<JournalEntry> _entries = const [];
  JournalStats? _stats;
  String? _outcomeFilter;
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  int _requestId = 0;
  int? _ownerUserId;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.analysis != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openForm(widget.initialEntry),
      );
    }
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
      final entriesFuture = auth.client.tradeJournal.listJournalEntries(
        limit: 100,
        outcome: _outcomeFilter,
      );
      final response = await entriesFuture;
      JournalStats? stats;
      try {
        stats = (await auth.client.tradeJournal.getJournalStats()).data;
      } catch (_) {
        // Statistik bersifat tambahan; daftar jurnal tetap harus bisa dipakai.
      }
      if (!_sameUser(userId) || requestId != _requestId) return;
      setState(() {
        _entries = response.data?.entries.toList() ?? const [];
        _stats = stats;
        _error = null;
      });
    } catch (_) {
      if (_sameUser(userId) && requestId == _requestId) {
        setState(() => _error = context.l10n.journalLoadFailed);
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
      builder: (_) => _JournalDialog(
        entry: entry,
        initialInstrument: widget.analysis?.instrument,
      ),
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
          createJournalEntryBody: CreateJournalEntryBody((builder) {
            builder
              ..analysisId = widget.analysis?.id
              ..instrument = result.instrument
              ..side = result.side == 'buy'
                  ? CreateJournalEntryBodySideEnum.buy
                  : CreateJournalEntryBodySideEnum.sell
              ..outcome = CreateJournalEntryBodyOutcomeEnum.valueOf(
                result.outcome,
              )
              ..mood = result.mood
              ..note = result.note
              ..tradedAt = result.tradedAt.toUtc();
            _setDecimals(
              builder,
              result.entryPrice,
              result.exitPrice,
              result.quantity,
            );
          }),
        );
        saved = response.data;
      } else {
        final response = await auth.client.tradeJournal.updateJournalEntry(
          id: entry.id,
          updateJournalEntryBody: UpdateJournalEntryBody((builder) {
            builder
              ..instrument = result.instrument
              ..side = result.side == 'buy'
                  ? UpdateJournalEntryBodySideEnum.buy
                  : UpdateJournalEntryBodySideEnum.sell
              ..outcome = UpdateJournalEntryBodyOutcomeEnum.valueOf(
                result.outcome,
              )
              ..mood = result.mood
              ..note = result.note
              ..tradedAt = result.tradedAt.toUtc();
            _setUpdateDecimals(
              builder,
              result.entryPrice,
              result.exitPrice,
              result.quantity,
            );
          }),
        );
        saved = response.data;
      }
      final savedEntry = saved;
      if (!_sameUser(userId) || savedEntry == null) return;
      if (entry == null) {
        unawaited(
          auth.telemetry.track(
            AnalyticsEventBodyEventTypeEnum.tradeLogged,
            path: '/journal',
            metadata: {'instrument': result.instrument, 'side': result.side},
          ),
        );
      }
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
          SnackBar(content: Text(context.l10n.journalSaveFailed)),
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
        title: Text(context.l10n.journalDeleteTitle),
        content: Text(context.l10n.journalDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
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
          SnackBar(content: Text(l10n.journalDeleteFailed)),
        );
      }
    } finally {
      if (_sameUser(userId)) setState(() => _mutating = false);
    }
  }

  String _outcome(JournalEntryOutcomeEnum outcome) => switch (outcome.name) {
    'win' => context.l10n.positiveOutcome,
    'loss' => context.l10n.negativeOutcome,
    'breakeven' => context.l10n.breakeven,
    'skipped' => context.l10n.skippedTrade,
    _ => context.l10n.open,
  };

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    if (_ownerUserId != null && currentUserId != _ownerUserId) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.tradeJournal)),
        body: Center(child: Text(context.l10n.journalSessionChanged)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tradeJournal)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mutating ? null : () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.add),
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
                      child: Text(context.l10n.tryAgain),
                    ),
                  ),
                ],
              )
            : _entries.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 140),
                  const Icon(Icons.menu_book_outlined, size: 52),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noJournalEntries,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: _entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_stats case final stats?)
                          _JournalStatsCard(stats: stats),
                        DropdownButtonFormField<String?>(
                          initialValue: _outcomeFilter,
                          decoration: InputDecoration(
                            labelText: context.l10n.journalOutcomeFilter,
                            prefixIcon: const Icon(Icons.filter_alt_outlined),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(context.l10n.all),
                            ),
                            DropdownMenuItem(
                              value: 'open',
                              child: Text(context.l10n.open),
                            ),
                            DropdownMenuItem(
                              value: 'win',
                              child: Text(context.l10n.positive),
                            ),
                            DropdownMenuItem(
                              value: 'loss',
                              child: Text(context.l10n.negative),
                            ),
                            DropdownMenuItem(
                              value: 'breakeven',
                              child: Text(context.l10n.breakeven),
                            ),
                            DropdownMenuItem(
                              value: 'skipped',
                              child: Text(context.l10n.skippedTrade),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _outcomeFilter = value);
                            _load();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            context.l10n.journalPrivateLimit,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  }
                  final entry = _entries[index - 1];
                  final details = <String>[
                    _outcome(entry.outcome),
                    DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(entry.tradedAt.toLocal()),
                    if (entry.entryPrice != null) 'Entry ${entry.entryPrice}',
                    if (entry.exitPrice != null) 'Exit ${entry.exitPrice}',
                    if (entry.quantity != null) 'Qty ${entry.quantity}',
                    if (entry.pnlAmount != null) 'P/L ${entry.pnlAmount}',
                    if (entry.pnlPercent != null) '${entry.pnlPercent}%',
                    if (entry.mood?.trim().isNotEmpty == true) entry.mood!,
                  ];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${entry.instrument} · ${entry.side.name.toUpperCase()}',
                      ),
                      subtitle: Text(
                        '${details.join(' · ')}${entry.note?.trim().isNotEmpty == true ? '\n${entry.note}' : ''}',
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
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(context.l10n.edit),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(context.l10n.delete),
                          ),
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
    this.entryPrice,
    this.exitPrice,
    this.quantity,
    this.tradedAt,
  );
  final String instrument;
  final String side;
  final String outcome;
  final String? mood;
  final String? note;
  final String? entryPrice;
  final String? exitPrice;
  final String? quantity;
  final DateTime tradedAt;
}

class _JournalDialog extends StatefulWidget {
  const _JournalDialog({this.entry, this.initialInstrument});
  final JournalEntry? entry;
  final String? initialInstrument;

  @override
  State<_JournalDialog> createState() => _JournalDialogState();
}

class _JournalDialogState extends State<_JournalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instrument;
  late final TextEditingController _mood;
  late final TextEditingController _note;
  late final TextEditingController _entryPrice;
  late final TextEditingController _exitPrice;
  late final TextEditingController _quantity;
  late DateTime _tradedAt;
  late String _side;
  late String _outcome;

  @override
  void initState() {
    super.initState();
    _instrument = TextEditingController(
      text: widget.entry?.instrument ?? widget.initialInstrument ?? '',
    );
    _mood = TextEditingController(text: widget.entry?.mood ?? '');
    _note = TextEditingController(text: widget.entry?.note ?? '');
    _entryPrice = TextEditingController(text: widget.entry?.entryPrice ?? '');
    _exitPrice = TextEditingController(text: widget.entry?.exitPrice ?? '');
    _quantity = TextEditingController(text: widget.entry?.quantity ?? '');
    _tradedAt = widget.entry?.tradedAt.toLocal() ?? DateTime.now();
    _side = widget.entry?.side.name ?? 'buy';
    _outcome = widget.entry?.outcome.name ?? 'open';
  }

  @override
  void dispose() {
    _instrument.dispose();
    _mood.dispose();
    _note.dispose();
    _entryPrice.dispose();
    _exitPrice.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.entry == null
            ? context.l10n.addJournal
            : context.l10n.editJournal,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('journal-instrument-field'),
                controller: _instrument,
                maxLength: 32,
                decoration: InputDecoration(labelText: context.l10n.instrument),
                validator: (value) => value?.trim().isEmpty == true
                    ? context.l10n.instrumentRequired
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _side,
                decoration: InputDecoration(labelText: context.l10n.side),
                items: [
                  DropdownMenuItem(
                    value: 'buy',
                    child: Text(context.l10n.buyJournalSide),
                  ),
                  DropdownMenuItem(
                    value: 'sell',
                    child: Text(context.l10n.sellJournalSide),
                  ),
                ],
                onChanged: (value) => _side = value!,
              ),
              DropdownButtonFormField<String>(
                initialValue: _outcome,
                decoration: InputDecoration(
                  labelText: context.l10n.retrospectiveStatus,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'open',
                    child: Text(context.l10n.open),
                  ),
                  DropdownMenuItem(
                    value: 'win',
                    child: Text(context.l10n.positiveOutcome),
                  ),
                  DropdownMenuItem(
                    value: 'loss',
                    child: Text(context.l10n.negativeOutcome),
                  ),
                  DropdownMenuItem(
                    value: 'breakeven',
                    child: Text(context.l10n.breakeven),
                  ),
                  DropdownMenuItem(
                    value: 'skipped',
                    child: Text(context.l10n.skippedTrade),
                  ),
                ],
                onChanged: (value) => _outcome = value!,
              ),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _entryPrice,
                      label: 'Entry',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberField(controller: _exitPrice, label: 'Exit'),
                  ),
                ],
              ),
              _NumberField(controller: _quantity, label: context.l10n.quantity),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: Text(context.l10n.tradeTime),
                subtitle: Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(_tradedAt),
                ),
                onTap: _pickDateTime,
              ),
              TextField(
                controller: _mood,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: context.l10n.moodOptional,
                ),
              ),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 5,
                maxLength: 5000,
                decoration: InputDecoration(
                  labelText: context.l10n.reflectionOptional,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
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
                _optional(_entryPrice.text),
                _optional(_exitPrice.text),
                _optional(_quantity.text),
                _tradedAt,
              ),
            );
          },
          child: Text(context.l10n.save),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tradedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_tradedAt),
    );
    if (time == null) return;
    setState(
      () => _tradedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();
}

CreateJournalEntryBodyEntryPrice? _decimal(String? value) {
  if (value == null) return null;
  final parsed = num.tryParse(value);
  if (parsed == null) return null;
  return CreateJournalEntryBodyEntryPrice(
    (builder) => builder.oneOf = OneOf.fromValue2<String, num>(value: parsed),
  );
}

void _setDecimals(
  CreateJournalEntryBodyBuilder builder,
  String? entry,
  String? exit,
  String? quantity,
) {
  final entryValue = _decimal(entry);
  final exitValue = _decimal(exit);
  final quantityValue = _decimal(quantity);
  if (entryValue != null) builder.entryPrice.replace(entryValue);
  if (exitValue != null) builder.exitPrice.replace(exitValue);
  if (quantityValue != null) builder.quantity.replace(quantityValue);
}

void _setUpdateDecimals(
  UpdateJournalEntryBodyBuilder builder,
  String? entry,
  String? exit,
  String? quantity,
) {
  final entryValue = _decimal(entry);
  final exitValue = _decimal(exit);
  final quantityValue = _decimal(quantity);
  if (entryValue != null) builder.entryPrice.replace(entryValue);
  if (exitValue != null) builder.exitPrice.replace(exitValue);
  if (quantityValue != null) builder.quantity.replace(quantityValue);
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (value) =>
        value == null || value.trim().isEmpty || num.tryParse(value) != null
        ? null
        : context.l10n.enterValidNumber,
  );
}

class _JournalStatsCard extends StatelessWidget {
  const _JournalStatsCard({required this.stats});
  final JournalStats stats;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _Stat(context.l10n.entries, '${stats.totals.entries}'),
          _Stat(
            context.l10n.winRate,
            stats.winRate == null ? '—' : '${(stats.winRate! * 100).round()}%',
          ),
          _Stat(context.l10n.wins, '${stats.totals.wins}'),
          _Stat(context.l10n.losses, '${stats.totals.losses}'),
          _Stat(context.l10n.open, '${stats.totals.open}'),
          _Stat(
            context.l10n.averageProfitLoss,
            stats.avgPnlPercent == null
                ? '—'
                : '${stats.avgPnlPercent!.toStringAsFixed(2)}%',
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}
