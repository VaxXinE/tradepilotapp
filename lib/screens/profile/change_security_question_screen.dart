import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';

class ChangeSecurityQuestionScreen extends StatefulWidget {
  const ChangeSecurityQuestionScreen({super.key});

  @override
  State<ChangeSecurityQuestionScreen> createState() =>
      _ChangeSecurityQuestionScreenState();
}

class _ChangeSecurityQuestionScreenState
    extends State<ChangeSecurityQuestionScreen> {
  static const _questions = [
    'Nama hewan peliharaan pertama kamu?',
    'Nama kota tempat kamu lahir?',
    'Nama ibu kandung kamu?',
    'Nama sekolah dasar kamu?',
    'Nama teman terbaik masa kecil kamu?',
  ];

  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _answer = TextEditingController();
  late String _question;
  bool _obscurePassword = true;
  bool _obscureAnswer = true;

  @override
  void initState() {
    super.initState();
    final current = context.read<AuthProvider>().user?.securityQuestion;
    _question = _questions.contains(current) ? current! : _questions.first;
  }

  @override
  void dispose() {
    _password.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.changeSecurityQuestion(
      currentPassword: _password.text,
      securityQuestion: _question,
      securityAnswer: _answer.text.trim(),
    );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.securityQuestionUpdated)),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.watch<LocaleController>().locale.languageCode;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changeSecurityQuestion)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorBanner(message: auth.profileError),
                  DropdownButtonFormField<String>(
                    initialValue: _question,
                    decoration: InputDecoration(
                      labelText: l10n.securityQuestion,
                    ),
                    items: List.generate(
                      _questions.length,
                      (index) => DropdownMenuItem(
                        value: _questions[index],
                        child: Text(_label(language, index)),
                      ),
                    ),
                    onChanged: (value) => setState(() => _question = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _answer,
                    obscureText: _obscureAnswer,
                    decoration: InputDecoration(
                      labelText: l10n.newSecurityAnswer,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureAnswer = !_obscureAnswer),
                        icon: Icon(
                          _obscureAnswer
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? l10n.answerRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.currentPassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                    validator: (value) => value?.isEmpty == true
                        ? l10n.currentPasswordRequired
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.isChangingPassword ? null : _submit,
                    child: auth.isChangingPassword
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _label(String language, int index) {
    if (language == 'id') return _questions[index];
    return const [
      'Name of your first pet?',
      'City where you were born?',
      "Your mother's maiden name?",
      'Name of your elementary school?',
      'Name of your childhood best friend?',
    ][index];
  }
}
