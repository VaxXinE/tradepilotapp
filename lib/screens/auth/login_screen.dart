import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: LanguageMenuButton(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -1.25),
                          radius: 1.25,
                          colors: [
                            Color(0xFF201700),
                            Color(0xFF0A0802),
                            Color(0xFF000000),
                          ],
                          stops: [0, 0.45, 1],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            key: const Key('login-brand-mark'),
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.darkPrimary.withValues(alpha: 0.20),
                                  const Color(
                                    0xFFFACC15,
                                  ).withValues(alpha: 0.15),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.darkPrimary.withValues(
                                  alpha: 0.30,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darkPrimary.withValues(
                                    alpha: 0.24,
                                  ),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/trade_pilot_app_icon.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              semanticLabel: l10n.tradePilotLogo,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.welcomeBack,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.loginDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ErrorBanner(message: auth.errorMessage),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: AutofillGroup(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      OutlinedButton.icon(
                                        key: const Key('google-sign-in-button'),
                                        onPressed: auth.isBusy
                                            ? null
                                            : auth.loginWithGoogle,
                                        icon: const ExcludeSemantics(
                                          child: Text(
                                            'G',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4285F4),
                                            ),
                                          ),
                                        ),
                                        label: Text(l10n.continueWithGoogle),
                                      ),
                                      if (defaultTargetPlatform ==
                                          TargetPlatform.iOS) ...[
                                        const SizedBox(height: 10),
                                        SignInWithAppleButton(
                                          key: const Key(
                                            'apple-sign-in-button',
                                          ),
                                          onPressed: auth.isBusy
                                              ? null
                                              : auth.loginWithApple,
                                          text: l10n.continueWithApple,
                                          height: 48,
                                          // Samakan dengan OutlinedButton
                                          // Google tepat di atasnya.
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(AppColors.radiusMd),
                                          ),
                                          style: isDark
                                              ? SignInWithAppleButtonStyle.white
                                              : SignInWithAppleButtonStyle
                                                    .black,
                                        ),
                                      ],
                                      const SizedBox(height: 18),
                                      Row(
                                        children: [
                                          const Expanded(child: Divider()),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              l10n.or.toUpperCase(),
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: Divider()),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      _FieldLabel(l10n.usernameEmail),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        textCapitalization:
                                            TextCapitalization.none,
                                        autocorrect: false,
                                        autofillHints: const [
                                          AutofillHints.username,
                                        ],
                                        decoration: InputDecoration(
                                          hintText: l10n.usernameEmailHint,
                                        ),
                                        validator: (value) {
                                          final email = value?.trim() ?? '';
                                          return email.contains('@')
                                              ? null
                                              : l10n.invalidEmail;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _FieldLabel(l10n.password),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        onFieldSubmitted: (_) => _submit(),
                                        decoration: InputDecoration(
                                          hintText: l10n.password,
                                          suffixIcon: IconButton(
                                            tooltip: _obscurePassword
                                                ? l10n.showPassword
                                                : l10n.hidePassword,
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                          ),
                                        ),
                                        validator: (value) =>
                                            (value == null || value.isEmpty)
                                            ? l10n.passwordRequired
                                            : null,
                                      ),
                                      CheckboxListTile(
                                        key: const Key('remember-me-checkbox'),
                                        value: _rememberMe,
                                        onChanged: _setRememberMe,
                                        title: Text(
                                          l10n.rememberMe,
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 14,
                                          ),
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                      _PremiumLoginButton(
                                        busy: auth.isBusy,
                                        label: l10n.signIn,
                                        onPressed: _submit,
                                      ),
                                      const SizedBox(height: 4),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ForgotPasswordScreen(),
                                              ),
                                            ),
                                        child: Text(l10n.forgotPassword),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                child: Text(l10n.register),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
  );
}

class _PremiumLoginButton extends StatelessWidget {
  const _PremiumLoginButton({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFE06A), Color(0xFFE3A400)],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkPrimary.withValues(alpha: 0.32),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : const Icon(Icons.psychology_alt_outlined, size: 19),
      label: Text(label),
    ),
  );
}
