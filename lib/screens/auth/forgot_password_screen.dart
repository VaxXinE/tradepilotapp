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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final result = await auth.getSecurityQuestion(_emailController.text.trim());
    if (result != null && mounted) {
      setState(() {
        _securityQuestion = result.securityQuestion;
        _step = 2;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final result = await auth.verifySecurityAnswer(
      email: _emailController.text.trim(),
      answer: _answerController.text.trim(),
    );
    if (result != null && mounted) {
      setState(() {
        _resetToken = result.resetToken;
        _step = 3;
      });
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate() || _resetToken == null) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
      resetToken: _resetToken!,
      newPassword: _newPasswordController.text,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah. Silakan masuk.'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
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
                          Row(
                            children: List.generate(3, (index) {
                              return Expanded(
                                child: Container(
                                  height: 4,
                                  margin: EdgeInsets.only(
                                    right: index == 2 ? 0 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index < _step
                                        ? theme.colorScheme.primary
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Langkah $_step dari 3',
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ErrorBanner(message: auth.errorMessage),
                          if (_step == 1) ..._buildStepEmail(auth, muted),
                          if (_step == 2) ..._buildStepAnswer(auth, muted),
                          if (_step == 3) ..._buildStepNewPassword(auth, muted),
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

  List<Widget> _buildStepEmail(AuthProvider auth, Color muted) => [
    const Text(
      'Temukan akunmu',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 6),
    Text(
      'Masukkan email akun untuk memulai pemulihan password.',
      style: TextStyle(color: muted, height: 1.4),
    ),
    const SizedBox(height: 24),
    TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      onFieldSubmitted: (_) => _submitEmail(),
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'nama@email.com',
        prefixIcon: Icon(Icons.mail_outline_rounded),
      ),
      validator: (value) => (value?.trim().contains('@') ?? false)
          ? null
          : 'Masukkan email yang valid',
    ),
    const SizedBox(height: 20),
    ElevatedButton(
      onPressed: auth.isBusy ? null : _submitEmail,
      child: auth.isBusy ? const _BtnSpinner() : const Text('Lanjut'),
    ),
  ];

  List<Widget> _buildStepAnswer(AuthProvider auth, Color muted) => [
    const Text(
      'Verifikasi identitasmu',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 6),
    Text(
      'Jawab pertanyaan keamanan yang dibuat saat pendaftaran.',
      style: TextStyle(color: muted, height: 1.4),
    ),
    const SizedBox(height: 24),
    Text(
      _securityQuestion ?? '-',
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 12),
    TextFormField(
      controller: _answerController,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submitAnswer(),
      decoration: const InputDecoration(
        labelText: 'Jawaban',
        prefixIcon: Icon(Icons.shield_outlined),
      ),
      validator: (value) =>
          (value?.trim().isEmpty ?? true) ? 'Jawaban wajib diisi' : null,
    ),
    const SizedBox(height: 20),
    ElevatedButton(
      onPressed: auth.isBusy ? null : _submitAnswer,
      child: auth.isBusy ? const _BtnSpinner() : const Text('Verifikasi'),
    ),
    const SizedBox(height: 8),
    TextButton(
      onPressed: auth.isBusy
          ? null
          : () => setState(() {
              _step = 1;
              _answerController.clear();
            }),
      child: const Text('Ganti email'),
    ),
  ];

  List<Widget> _buildStepNewPassword(AuthProvider auth, Color muted) => [
    const Text(
      'Buat password baru',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 6),
    Text(
      'Gunakan minimal 8 karakter dan jangan gunakan ulang password lama.',
      style: TextStyle(color: muted, height: 1.4),
    ),
    const SizedBox(height: 24),
    TextFormField(
      controller: _newPasswordController,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      onFieldSubmitted: (_) => _submitNewPassword(),
      decoration: InputDecoration(
        labelText: 'Password baru',
        helperText: 'Minimal 8 karakter',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
          icon: Icon(
            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (value) =>
          (value?.length ?? 0) < 8 ? 'Password minimal 8 karakter' : null,
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
  Widget build(BuildContext context) => SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      color: Theme.of(context).colorScheme.onPrimary,
    ),
  );
}
