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
      email: _emailController.text,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    ErrorBanner(message: auth.errorMessage),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Masukkan email yang valid' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
                    ),
                    const SizedBox(height: 20),
                    Text('Level Pengalaman',
                        style: TextStyle(fontWeight: FontWeight.w600, color: muted, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ModeChip(
                            label: 'Pemula',
                            selected: _mode == RegisterBodySelectedModeEnum.beginner,
                            onTap: () => setState(() => _mode = RegisterBodySelectedModeEnum.beginner),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModeChip(
                            label: 'Pro',
                            selected: _mode == RegisterBodySelectedModeEnum.pro,
                            onTap: () => setState(() => _mode = RegisterBodySelectedModeEnum.pro),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Pertanyaan Keamanan',
                        style: TextStyle(fontWeight: FontWeight.w600, color: muted, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(_securityQuestion,
                        style: TextStyle(color: muted, fontSize: 13, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _securityAnswerController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(labelText: 'Jawaban'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Jawaban wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: auth.isBusy ? null : _submit,
                      child: auth.isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text('Buat Akun'),
                    ),
                    const SizedBox(height: 24),
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

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final onPrimary = isDark ? AppColors.darkPrimaryForeground : AppColors.lightPrimaryForeground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppColors.radius),
          border: Border.all(color: selected ? primary : border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? onPrimary : null,
          ),
        ),
      ),
    );
  }
}
