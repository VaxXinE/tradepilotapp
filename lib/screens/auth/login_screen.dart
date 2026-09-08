import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/language_menu_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _rememberedEmailKey = 'remembered_login_email';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage(aOptions: AndroidOptions());
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _restoreRememberedEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<AuthProvider>().telemetry.pageView('/login'));
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final rememberMe = _rememberMe;
    FocusScope.of(context).unfocus();
    final success = await auth.login(email: email, password: password);
    if (!success) return;

    try {
      if (rememberMe) {
        await _storage.write(key: _rememberedEmailKey, value: email);
      } else {
        await _storage.delete(key: _rememberedEmailKey);
      }
    } catch (_) {
      // Login tetap berhasil jika secure storage perangkat bermasalah.
    }
  }

  /// Restores the email only.
  ///
  /// Builds up to 1.0.1 also persisted the password here and typed it back into
  /// the form, which meant a stolen unlocked phone handed over a credential
  /// that — unlike a session token — the server cannot revoke, and that one tap
  /// on the reveal icon would show in plain text. The password is now never
  /// written; [TokenStorage.purgeLegacyCredentials] deletes whatever older
  /// builds left behind.
  Future<void> _restoreRememberedEmail() async {
    try {
      final email = await _storage.read(key: _rememberedEmailKey);
      if (!mounted || email == null) return;

      _emailController.text = email;
      setState(() => _rememberMe = true);
    } catch (_) {
      // Form tetap bisa dipakai tanpa email tersimpan.
    }
  }

  Future<void> _setRememberMe(bool? value) async {
    final enabled = value ?? false;
    setState(() => _rememberMe = enabled);
    if (!enabled) {
      try {
        await _storage.delete(key: _rememberedEmailKey);
      } catch (_) {
        // Penghapusan akan dicoba lagi saat login berikutnya.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: const [LanguageMenuButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              key: const Key('login-brand-mark'),
                              width: 120,
                              height: 80,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.darkBackground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.asset(
                                'assets/images/trade_pilot_app_icon.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                semanticLabel: l10n.tradePilotLogo,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.aiTradingAssistant,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            l10n.welcomeBack,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.loginDescription,
                            style: TextStyle(color: muted, height: 1.4),
                          ),
                          const SizedBox(height: 22),
                          ErrorBanner(message: auth.errorMessage),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              hintText: l10n.emailHint,
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                              ),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              return email.contains('@')
                                  ? null
                                  : l10n.invalidEmail;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? l10n.showPassword
                                    : l10n.hidePassword,
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? l10n.passwordRequired
                                : null,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  key: const Key('remember-me-checkbox'),
                                  value: _rememberMe,
                                  onChanged: _setRememberMe,
                                  title: Text(l10n.rememberMe),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                                child: Text(l10n.forgotPassword),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: auth.isBusy ? null : _submit,
                            child: auth.isBusy
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : Text(l10n.signIn),
                          ),
                          // No biometric button here on purpose. Biometrics can
                          // only unlock a session that already exists, and a
                          // user who has one never reaches this screen — they
                          // land on LockScreen instead. The only thing a button
                          // here could unlock is a stored password, which is
                          // exactly what this app no longer keeps.
                          const SizedBox(height: 22),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                l10n.noAccount,
                                style: TextStyle(color: muted),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(48, 48),
                                ),
                                child: Text(l10n.register),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
