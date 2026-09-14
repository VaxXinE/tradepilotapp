import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/storage/signed_upload.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/error_banner.dart';

/// Halaman Top Up Credit.
///
/// Alur pembayarannya manual: pengguna membayar lewat QRIS backend, lalu
/// mengirim permintaan top-up yang ditinjau admin. Karena itu saldo tidak
/// berubah saat submit — hanya riwayat yang bertambah dengan status `pending`.
class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key, this.imagePicker});

  /// Disuntikkan pada test; produksi memakai [ImagePicker] biasa.
  final ImagePicker? imagePicker;

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  // Nominal preset mengikuti mobile web (PRESET_AMOUNTS pada pages/topup.tsx).
  static const _presetAmounts = [5000, 10000, 15000, 20000];

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  _PickedProof? _proof;
  bool _paymentStep = false;
  bool _uploadingProof = false;
  String? _proofError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CreditProvider>().refreshAll();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  int? get _amount {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');

    return digits.isEmpty ? null : int.tryParse(digits);
  }

  bool get _isBusy =>
      _uploadingProof || context.read<CreditProvider>().isSubmitting;

  void _continueToPayment() {
    final amount = _amount;
    final rate = context.read<CreditProvider>().config?.rupiahPerCredit;
    if (amount == null || amount <= 0) {
      _showMessage(context.l10n.topUpAmountRequired);
      return;
    }
    if (rate != null && amount < rate) {
      _showMessage(context.l10n.topUpAmountTooSmall(_rupiah(rate)));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _paymentStep = true);
  }

  Future<void> _pickProof() async {
    final picker = widget.imagePicker ?? ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );

    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    final contentType = resolveImageContentType(
      mimeType: file.mimeType,
      fileName: file.name,
    );

    // Format dan ukuran ditolak di sini, sebelum byte apa pun dikirim.
    if (contentType == null || bytes.length > maxSignedUploadBytes) {
      setState(() {
        _proof = null;
        _proofError = context.l10n.avatarRequirements;
      });
      return;
    }

    setState(() {
      _proof = _PickedProof(
        fileName: file.name,
        mimeType: contentType,
        bytes: bytes,
      );
      _proofError = null;
    });
  }

  void _removeProof() {
    setState(() {
      _proof = null;
      _proofError = null;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final credit = context.read<CreditProvider>();

    // Double-submit: satu penjaga di provider, satu di sini supaya upload bukti
    // pun tidak bisa jalan dua kali.
    if (_isBusy) return;

    FocusScope.of(context).unfocus();
    credit.clearSubmitError();

    final amount = _amount;

    if (amount == null || amount <= 0) {
      setState(() => _proofError = null);
      _showMessage(l10n.topUpAmountRequired);
      return;
    }

    final rate = credit.config?.rupiahPerCredit;

    if (rate != null && amount < rate) {
      _showMessage(l10n.topUpAmountTooSmall(_rupiah(rate)));
      return;
    }

    String? proofObjectPath;
    final proof = _proof;

    if (proof != null) {
      setState(() {
        _uploadingProof = true;
        _proofError = null;
      });

      try {
        proofObjectPath =
            await SignedUploadService(
              context.read<AuthProvider>().client,
            ).uploadImage(
              fileName: proof.fileName,
              bytes: proof.bytes,
              mimeType: proof.mimeType,
            );
      } on SignedUploadException catch (error) {
        if (!mounted) return;

        setState(() {
          _uploadingProof = false;
          _proofError = error.failure == SignedUploadFailure.failed
              ? l10n.topUpProofFailed
              : l10n.avatarRequirements;
        });

        // Upload gagal berarti tidak ada POST /topups sama sekali — tidak boleh
        // ada top-up yang terkirim setengah jalan tanpa buktinya.
        return;
      }

      if (!mounted) return;

      setState(() => _uploadingProof = false);
    }

    final created = await credit.submitTopup(
      amountRupiah: amount,
      paymentReferenceNote: _referenceController.text,
      proofObjectPath: proofObjectPath,
    );

    if (!mounted || created == null) return;

    _amountController.clear();
    _referenceController.clear();

    setState(() {
      _proof = null;
      _proofError = null;
      _paymentStep = false;
    });

    _showMessage(l10n.topUpSubmitted);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final credit = context.watch<CreditProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.topUpCredit)),
      body: RefreshIndicator(
        onRefresh: credit.refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BalanceCard(credit: credit),
                    const SizedBox(height: 16),
                    if (_paymentStep)
                      _buildPaymentStep(context, credit, theme)
                    else
                      _buildAmountStep(context, credit, theme),
                    const SizedBox(height: 24),
                    Text(
                      l10n.topUpHistory,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HistorySection(credit: credit),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountStep(
    BuildContext context,
    CreditProvider credit,
    ThemeData theme,
  ) {
    final l10n = context.l10n;
    final amount = _amount;
    final credits = amount == null ? null : credit.creditsFor(amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.topUpChooseAmount, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final preset in _presetAmounts)
                  OutlinedButton(
                    onPressed: () {
                      _amountController.text = '$preset';
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: amount == preset
                          ? theme.colorScheme.primary.withValues(alpha: .10)
                          : null,
                      side: BorderSide(
                        color: amount == preset
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: Text(_rupiah(preset)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.topUpAmountLabel,
                hintText: l10n.topUpAmountHint,
                prefixText: 'Rp ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (credits != null && credits > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.topUpCreditsPreview(credits),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (credit.config case final config?) ...[
              const SizedBox(height: 4),
              Text(
                l10n.topUpRatePerCredit(_rupiah(config.rupiahPerCredit)),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _continueToPayment,
              child: Text(l10n.topUpContinuePayment),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep(
    BuildContext context,
    CreditProvider credit,
    ThemeData theme,
  ) {
    final l10n = context.l10n;
    final amount = _amount ?? 0;
    final credits = credit.creditsFor(amount) ?? 0;
    final busy = _uploadingProof || credit.isSubmitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.topUpPayment,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => _paymentStep = false),
                      child: Text(l10n.topUpChangeAmount),
                    ),
                  ],
                ),
                Text(
                  l10n.topUpPaymentSummary(_rupiah(amount), credits),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _QrisCard(credit: credit, embedded: true),
                const SizedBox(height: 16),
                ErrorBanner(message: credit.submitError),
                ErrorBanner(message: _proofError),
                TextField(
                  controller: _referenceController,
                  enabled: !busy,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: l10n.topUpReferenceLabel,
                    hintText: l10n.topUpReferenceHint,
                  ),
                ),
                const SizedBox(height: 8),
                _ProofField(
                  proof: _proof,
                  busy: busy,
                  onPick: _pickProof,
                  onRemove: _removeProof,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.topUpSubmit),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PickedProof {
  const _PickedProof({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.credit});

  final CreditProvider credit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.creditBalance, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  if (credit.isLoadingBalance && !credit.hasBalance)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (credit.balanceError != null && !credit.hasBalance)
                    Text(
                      l10n.creditBalanceFailed,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    )
                  else
                    Text(
                      '${credit.balance ?? 0}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            if (credit.balanceError != null)
              TextButton(
                onPressed: credit.loadBalance,
                child: Text(l10n.tryAgain),
              ),
          ],
        ),
      ),
    );
  }
}

class _QrisCard extends StatelessWidget {
  const _QrisCard({required this.credit, this.embedded = false});

  final CreditProvider credit;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final config = credit.config;

    if (credit.isLoadingConfig && config == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (config == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                credit.configError ?? l10n.topUpConfigFailed,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: credit.loadConfig,
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            l10n.topUpScanQris,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              config.qrisImageUrl,
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, _, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.topUpQrisUnavailable,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.topUpRatePerCredit(_rupiah(config.rupiahPerCredit)),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return embedded ? content : Card(child: content);
  }
}

class _ProofField extends StatelessWidget {
  const _ProofField({
    required this.proof,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });

  final _PickedProof? proof;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final picked = proof;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.topUpProofLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        if (picked != null) ...[
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  picked.bytes,
                  height: 72,
                  width: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => const SizedBox(
                    height: 72,
                    width: 72,
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.topUpProofAttached,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.remove,
                onPressed: busy ? null : onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: busy ? null : onPick,
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(
            picked == null ? l10n.topUpAddProof : l10n.topUpChangeProof,
          ),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.credit});

  final CreditProvider credit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (credit.isLoadingHistory && credit.history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (credit.history.isEmpty) {
      return Column(
        children: [
          ErrorBanner(message: credit.historyError),
          if (credit.historyError == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.topUpHistoryEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            TextButton(
              onPressed: () => credit.loadHistory(refresh: true),
              child: Text(l10n.tryAgain),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErrorBanner(message: credit.historyError),
        for (final request in credit.history) _HistoryTile(request: request),
        if (credit.hasMoreHistory)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: credit.isLoadingMoreHistory
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: credit.loadMoreHistory,
                    child: Text(l10n.topUpLoadMore),
                  ),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.request});

  final TopupRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final reviewNote = request.reviewNote;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _rupiah(request.amountRupiah),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.topUpRequestedCredits(request.creditsRequested),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              DateFormat.yMMMd().add_Hm().format(request.createdAt.toLocal()),
              style: theme.textTheme.bodySmall,
            ),
            if (request.status == TopupRequestStatus.approved &&
                request.creditsGranted != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.topUpCreditsGranted(request.creditsGranted!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (reviewNote != null && reviewNote.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l10n.topUpReviewNote(reviewNote),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TopupRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final (label, color) = switch (status) {
      TopupRequestStatus.approved => (l10n.topUpApproved, scheme.primary),
      TopupRequestStatus.rejected => (l10n.topUpRejected, scheme.error),
      _ => (l10n.pending, scheme.tertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _rupiah(int amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(amount);
}
