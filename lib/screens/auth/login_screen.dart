import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.localAuthentication});

  final LocalAuthentication? localAuthentication;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _rememberedEmailKey = 'remembered_login_email';
  static const _rememberedPasswordKey = 'remembered_login_password';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  late final LocalAuthentication _localAuthentication;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _biometricsAvailable = false;
  bool _isAuthenticatingBiometric = false;

  @override
  void initState() {
    super.initState();
    _localAuthentication = widget.localAuthentication ?? LocalAuthentication();
    _restoreRememberedCredentials();
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
        await _storage.write(key: _rememberedPasswordKey, value: password);
      } else {
        await _clearRememberedCredentials();
      }
    } catch (_) {
      // Login tetap berhasil jika secure storage perangkat bermasalah.
    }
  }

  Future<void> _restoreRememberedCredentials() async {
    try {
      final email = await _storage.read(key: _rememberedEmailKey);
      final password = await _storage.read(key: _rememberedPasswordKey);
      if (!mounted || email == null || password == null) return;

      _emailController.text = email;
      _passwordController.text = password;
      final biometrics = await _localAuthentication.getAvailableBiometrics();
      if (!mounted) return;
      setState(() {
        _rememberMe = true;
        _biometricsAvailable = biometrics.isNotEmpty;
      });
    } catch (_) {
      // Form tetap bisa dipakai tanpa kredensial tersimpan.
    }
  }

  Future<void> _setRememberMe(bool? value) async {
    final enabled = value ?? false;
    setState(() {
      _rememberMe = enabled;
      if (!enabled) _biometricsAvailable = false;
    });
    if (!enabled) {
      try {
        await _clearRememberedCredentials();
      } catch (_) {
        // Penghapusan akan dicoba lagi saat login berikutnya.
      }
    }
  }

  Future<void> _clearRememberedCredentials() async {
    await _storage.delete(key: _rememberedEmailKey);
    await _storage.delete(key: _rememberedPasswordKey);
  }

  Future<void> _loginWithBiometrics() async {
    if (_isAuthenticatingBiometric) return;
    setState(() => _isAuthenticatingBiometric = true);

    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: context.l10n.biometricReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated && mounted) await _submit();
    } on LocalAuthException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.biometricUnavailable)),
        );
      }
    } finally {
      if (mounted) setState(() => _isAuthenticatingBiometric = false);
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
                                'assets/images/trade_pilot_logo.png',
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
                          if (_biometricsAvailable) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(child: Divider(endIndent: 12)),
                                Text(l10n.or, style: TextStyle(color: muted)),
                                const Expanded(child: Divider(indent: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              key: const Key('biometric-login-button'),
                              onPressed:
                                  auth.isBusy || _isAuthenticatingBiometric
                                  ? null
                                  : _loginWithBiometrics,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: Text(
                                _isAuthenticatingBiometric
                                    ? l10n.verifying
                                    : l10n.signInWithBiometrics,
                              ),
                            ),
                          ],
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
