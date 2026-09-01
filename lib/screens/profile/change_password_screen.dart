import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../l10n/l10n.dart';
import '../../widgets/error_banner.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted || !success) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.passwordChanged)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorBanner(message: auth.profileError),
                _PasswordField(
                  controller: _currentController,
                  label: l10n.currentPassword,
                  obscureText: _obscureCurrent,
                  onToggleVisibility: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (value) => value == null || value.isEmpty
                      ? l10n.currentPasswordRequired
                      : null,
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _newController,
                  label: l10n.newPassword,
                  obscureText: _obscureNew,
                  onToggleVisibility: () =>
                      setState(() => _obscureNew = !_obscureNew),
                  validator: (value) => value == null || value.length < 8
                      ? l10n.passwordMinimumCharacters
                      : null,
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  controller: _confirmationController,
                  label: l10n.confirmNewPassword,
                  obscureText: _obscureConfirmation,
                  onToggleVisibility: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation,
                  ),
                  validator: (value) => value != _newController.text
                      ? l10n.passwordConfirmationMismatch
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isChangingPassword ? null : _submit,
                  child: auth.isChangingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: obscureText
              ? context.l10n.showPassword
              : context.l10n.hidePassword,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }
}
