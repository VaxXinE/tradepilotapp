import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';

/// Alur lupa password 3 langkah, setara `forgot-password.tsx` di web app:
/// 1) masukkan email -> ambil pertanyaan keamanan
/// 2) jawab pertanyaan -> dapat reset token
/// 3) set password baru
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1;
  final _emailController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String? _securityQuestion;
  String? _resetToken;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (_emailController.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.getSecurityQuestion(_emailController.text);
    if (result != null && mounted) {
      setState(() {
        _securityQuestion = result.securityQuestion;
        _step = 2;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.verifySecurityAnswer(
      email: _emailController.text,
      answer: _answerController.text,
    );
    if (result != null && mounted) {
      setState(() {
        _resetToken = result.resetToken;
        _step = 3;
      });
    }
  }

  Future<void> _submitNewPassword() async {
    if (_newPasswordController.text.length < 8 || _resetToken == null) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
      resetToken: _resetToken!,
      newPassword: _newPasswordController.text,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah. Silakan masuk.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorBanner(message: auth.errorMessage),
                  if (_step == 1) ..._buildStepEmail(auth),
                  if (_step == 2) ..._buildStepAnswer(auth),
                  if (_step == 3) ..._buildStepNewPassword(auth),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildStepEmail(AuthProvider auth) => [
        const Text('Masukkan email akun kamu untuk memulai pemulihan.'),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: auth.isBusy ? null : _submitEmail,
          child: auth.isBusy ? const _BtnSpinner() : const Text('Lanjut'),
        ),
      ];

  List<Widget> _buildStepAnswer(AuthProvider auth) => [
        Text('Pertanyaan: ${_securityQuestion ?? "-"}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        TextField(
          controller: _answerController,
          decoration: const InputDecoration(labelText: 'Jawaban'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: auth.isBusy ? null : _submitAnswer,
          child: auth.isBusy ? const _BtnSpinner() : const Text('Verifikasi'),
        ),
      ];

  List<Widget> _buildStepNewPassword(AuthProvider auth) => [
        const Text('Masukkan password baru kamu.'),
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password Baru',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: auth.isBusy ? null : _submitNewPassword,
          child: auth.isBusy ? const _BtnSpinner() : const Text('Simpan Password'),
        ),
      ];
}

class _BtnSpinner extends StatelessWidget {
  const _BtnSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
      );
}
