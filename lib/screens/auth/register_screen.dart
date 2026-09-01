import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  bool _obscurePassword = true;
  RegisterBodySelectedModeEnum _mode = RegisterBodySelectedModeEnum.beginner;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    FocusScope.of(context).unfocus();
    final ok = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
      securityAnswer: _securityAnswerController.text.trim(),
      mode: _mode,
    );
    if (ok && mounted) Navigator.of(context).pop();
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
      appBar: AppBar(title: Text(l10n.createAccount)),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.startTradingJourney,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.registerDescription,
                            style: TextStyle(color: muted, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          ErrorBanner(message: auth.errorMessage),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: InputDecoration(
                              labelText: l10n.fullName,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.nameRequired
                                : null,
                          ),
                          const SizedBox(height: 14),
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
                            validator: (value) =>
                                (value?.trim().contains('@') ?? false)
                                ? null
                                : l10n.invalidEmail,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              helperText: l10n.minimumEightCharacters,
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
                            validator: (v) => (v == null || v.length < 8)
                                ? l10n.passwordMinimumCharacters
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.experienceLevel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<RegisterBodySelectedModeEnum>(
                            segments: [
                              ButtonSegment(
                                value: RegisterBodySelectedModeEnum.beginner,
                                icon: Icon(Icons.school_outlined),
                                label: Text(l10n.beginner),
                              ),
                              ButtonSegment(
                                value: RegisterBodySelectedModeEnum.pro,
                                icon: Icon(Icons.show_chart_rounded),
                                label: Text(l10n.pro),
                              ),
                            ],
                            selected: {_mode},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              setState(() => _mode = selection.first);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mode == RegisterBodySelectedModeEnum.beginner
                                ? l10n.beginnerModeHelp
                                : l10n.proModeHelp,
                            style: TextStyle(color: muted, fontSize: 12.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.securityQuestion,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.firstPetQuestion,
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _securityAnswerController,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: l10n.answer,
                              prefixIcon: const Icon(Icons.shield_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.answerRequired
                                : null,
                          ),
                          const SizedBox(height: 24),
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
                                : Text(l10n.createAccount),
                          ),
                          const SizedBox(height: 24),
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
