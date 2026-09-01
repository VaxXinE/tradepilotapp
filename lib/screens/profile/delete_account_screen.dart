import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../l10n/l10n.dart';
import '../../widgets/error_banner.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _confirmed = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refresh);
  }

  @override
  void dispose() {
    _passwordController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _deleteAccount() async {
    final success = await context.read<AuthProvider>().deleteAccount(
      _passwordController.text,
    );
    if (!mounted || !success) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    final canDelete =
        _confirmed &&
        _passwordController.text.isNotEmpty &&
        !auth.isDeletingAccount;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccount)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.warning_amber_rounded, color: error, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n.permanentAction,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.deleteAccountWarning, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ErrorBanner(message: auth.profileError),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.currentPassword,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.deleteAccountAcknowledgement),
                value: _confirmed,
                onChanged: auth.isDeletingAccount
                    ? null
                    : (value) => setState(() => _confirmed = value ?? false),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: error),
                onPressed: canDelete ? _deleteAccount : null,
                child: auth.isDeletingAccount
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(l10n.deleteAccountPermanently),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
