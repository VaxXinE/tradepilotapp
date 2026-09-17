import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../providers/auth_provider.dart';
import '../../l10n/l10n.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/responsive_page.dart';

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

  Future<void> _deleteAccount(
    Future<bool> Function(AuthProvider) action,
  ) async {
    final auth = context.read<AuthProvider>();
    final success = await action(auth);
    if (!mounted || !success) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    final hasPassword = auth.user?.hasPassword ?? true;
    final canDelete =
        _confirmed &&
        (!hasPassword || _passwordController.text.isNotEmpty) &&
        !auth.isDeletingAccount;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccount)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePagePadding(
            context,
            horizontal: 24,
            maxWidth: 480,
          ),
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
              if (hasPassword)
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
                )
              else
                Text(
                  l10n.federatedDeleteReauthDescription,
                  textAlign: TextAlign.center,
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
              if (hasPassword)
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: error),
                  onPressed: canDelete
                      ? () => _deleteAccount(
                          (auth) =>
                              auth.deleteAccount(_passwordController.text),
                        )
                      : null,
                  child: auth.isDeletingAccount
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(l10n.deleteAccountPermanently),
                )
              else ...[
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  SignInWithAppleButton(
                    key: const Key('delete-with-apple'),
                    onPressed: canDelete
                        ? () => _deleteAccount(
                            (auth) => auth.deleteAppleAccount(),
                          )
                        : null,
                    text: l10n.verifyAppleAndDelete,
                    height: 48,
                    style: Theme.of(context).brightness == Brightness.dark
                        ? SignInWithAppleButtonStyle.white
                        : SignInWithAppleButtonStyle.black,
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton(
                  key: const Key('delete-with-google'),
                  style: FilledButton.styleFrom(backgroundColor: error),
                  onPressed: canDelete
                      ? () =>
                            _deleteAccount((auth) => auth.deleteGoogleAccount())
                      : null,
                  child: auth.isDeletingAccount
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(l10n.verifyGoogleAndDelete),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
