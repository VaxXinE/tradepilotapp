import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/language_menu_button.dart';
import 'auth_visuals.dart';
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
  /// that the server cannot revoke. The password is now never written;
  /// [TokenStorage.purgeLegacyCredentials] deletes older stored values.
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
    final muted = theme.colorScheme.onSurfaceVariant;
    final l10n = context.l10n;

    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) => Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  authAccentColor(context).withValues(alpha: 0.08),
                  background,
                ),
                background,
                background,
              ],
              stops: const [0, 0.3, 1],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Navigator.of(context).canPop()
                              ? IconButton(
                                  tooltip: l10n.back,
                                  onPressed: auth.isBusy
                                      ? null
                                      : () => Navigator.of(context).maybePop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size.square(44),
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHigh,
                                    side: BorderSide(
                                      color: authBorderColor(context),
                                    ),
                                  ),
                                )
                              : const SizedBox.square(dimension: 44),
                          const LanguageMenuButton(),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  key: const Key('login-brand-mark'),
                                  width: 68,
                                  height: 68,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isDark
                                          ? const [
                                              Color(0xFF1C2028),
                                              Color(0xFF121419),
                                            ]
                                          : const [
                                              Color(0xFFFFFFFF),
                                              Color(0xFFFFF8E1),
                                            ],
                                    ),
                                    border: Border.all(
                                      color: authBorderColor(context),
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: authAccentColor(context)
                                            .withValues(
                                              alpha: isDark ? 0.18 : 0.1,
                                            ),
                                        blurRadius: 32,
                                        spreadRadius: 2,
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
                              ),
                              const SizedBox(height: 20),
                              Text(
                                l10n.welcomeBack,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontSize: 28,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.loginDescription,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              AuthErrorBanner(message: auth.errorMessage),
                              AuthPanel(
                                child: AutofillGroup(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        AuthGoogleButton(
                                          buttonKey: const Key(
                                            'google-sign-in-button',
                                          ),
                                          label: l10n.continueWithGoogle,
                                          onPressed: auth.isBusy
                                              ? null
                                              : auth.loginWithGoogle,
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
                                            height: 50,
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(12),
                                                ),
                                            style: isDark
                                                ? SignInWithAppleButtonStyle
                                                      .white
                                                : SignInWithAppleButtonStyle
                                                      .black,
                                          ),
                                        ],
                                        /* Facebook dan TikTok disembunyikan
                                           sampai provider OAuth production
                                           tersedia di backend.
                                        const SizedBox(height: 10),
                                        AuthSocialButton(
                                          buttonKey: const Key(
                                            'facebook-sign-in-button',
                                          ),
                                          label: l10n.continueWithFacebook,
                                          onPressed: auth.isBusy
                                              ? null
                                              : auth.loginWithFacebook,
                                          mark: 'f',
                                          markColor: const Color(0xFF1877F2),
                                        ),
                                        const SizedBox(height: 10),
                                        AuthSocialButton(
                                          buttonKey: const Key(
                                            'tiktok-sign-in-button',
                                          ),
                                          label: l10n.continueWithTikTok,
                                          onPressed: auth.isBusy
                                              ? null
                                              : auth.loginWithTikTok,
                                          mark: '♪',
                                          markColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        */
                                        const SizedBox(height: 20),
                                        AuthDivider(
                                          label: l10n.orSignInWithEmail,
                                        ),
                                        const SizedBox(height: 20),
                                        _AuthTextField(
                                          controller: _emailController,
                                          label: l10n.usernameEmail,
                                          hintText: l10n.usernameEmailHint,
                                          prefixIcon:
                                              Icons.alternate_email_rounded,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          textCapitalization:
                                              TextCapitalization.none,
                                          autocorrect: false,
                                          autofillHints: const [
                                            AutofillHints.username,
                                          ],
                                          validator: (value) {
                                            final email = value?.trim() ?? '';
                                            return email.contains('@')
                                                ? null
                                                : l10n.invalidEmail;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        _AuthTextField(
                                          controller: _passwordController,
                                          label: l10n.password,
                                          hintText: l10n.password,
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          onFieldSubmitted: (_) => _submit(),
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
                                          validator: (value) =>
                                              (value == null || value.isEmpty)
                                              ? l10n.passwordRequired
                                              : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Checkbox(
                                                  key: const Key(
                                                    'remember-me-checkbox',
                                                  ),
                                                  value: _rememberMe,
                                                  onChanged: auth.isBusy
                                                      ? null
                                                      : _setRememberMe,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    l10n.rememberMe,
                                                    style: TextStyle(
                                                      color: muted,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton(
                                              onPressed: auth.isBusy
                                                  ? null
                                                  : () => Navigator.of(context)
                                                        .push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                const ForgotPasswordScreen(),
                                                          ),
                                                        ),
                                              child: Text(l10n.forgotPassword),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        _PremiumLoginButton(
                                          busy: auth.isBusy,
                                          label: l10n.signIn,
                                          onPressed: _submit,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                child: Container(
                                  key: const Key('login-security-badge'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0D1512)
                                        : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF24513B)
                                          : const Color(0xFF86CFA8),
                                    ),
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 7,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_outlined,
                                        size: 16,
                                        color: Color(0xFF10B981),
                                      ),
                                      Text(
                                        l10n.secureSignIn.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFFD1D5DB)
                                              : const Color(0xFF14532D),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    l10n.noAccount,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: auth.isBusy
                                        ? null
                                        : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterScreen(),
                                            ),
                                          ),
                                    child: Text(l10n.register),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
    this.autofillHints,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final Iterable<String>? autofillHints;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = authBorderColor(context);
    final borderRadius = BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autocorrect: autocorrect,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: authFieldColor(context),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            hintText: hintText,
            prefixIcon: Icon(
              prefixIcon,
              color: theme.colorScheme.onSurfaceVariant,
              size: 19,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: authAccentColor(context), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
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
        colors: [Color(0xFFFFDA4F), Color(0xFFF0AD05)],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkPrimaryForeground,
        disabledForegroundColor: AppColors.darkPrimaryForeground.withValues(
          alpha: 0.55,
        ),
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.darkPrimaryForeground,
              ),
            )
          : const Icon(Icons.login_rounded, size: 19),
      label: Text(label),
    ),
  );
}
