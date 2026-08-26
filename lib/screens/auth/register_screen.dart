import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/theme/app_colors.dart';
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

  static const _securityQuestion = 'Nama hewan peliharaan pertama kamu?';

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
      securityQuestion: _securityQuestion,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
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
                          const Text(
                            'Mulai perjalanan tradingmu',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Buat akun dan sesuaikan analisis dengan pengalamanmu.',
                            style: TextStyle(color: muted, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          ErrorBanner(message: auth.errorMessage),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama wajib diisi'
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
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'nama@email.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (value) =>
                                (value?.trim().contains('@') ?? false)
                                ? null
                                : 'Masukkan email yang valid',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              helperText: 'Minimal 8 karakter',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Tampilkan password'
                                    : 'Sembunyikan password',
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
                                ? 'Password minimal 8 karakter'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Level pengalaman',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<RegisterBodySelectedModeEnum>(
                            segments: const [
                              ButtonSegment(
                                value: RegisterBodySelectedModeEnum.beginner,
                                icon: Icon(Icons.school_outlined),
                                label: Text('Pemula'),
                              ),
                              ButtonSegment(
                                value: RegisterBodySelectedModeEnum.pro,
                                icon: Icon(Icons.show_chart_rounded),
                                label: Text('Pro'),
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
                                ? 'Penjelasan lebih sederhana dan bertahap.'
                                : 'Informasi pasar lebih ringkas dan teknis.',
                            style: TextStyle(color: muted, fontSize: 12.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Pertanyaan Keamanan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _securityQuestion,
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
                            decoration: const InputDecoration(
                              labelText: 'Jawaban',
                              prefixIcon: Icon(Icons.shield_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Jawaban wajib diisi'
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
                                : const Text('Buat Akun'),
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
