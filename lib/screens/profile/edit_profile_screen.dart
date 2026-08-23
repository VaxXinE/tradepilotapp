import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: context.read<AuthProvider>().user?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().updateDisplayName(
      _displayNameController.text,
    );
    if (!mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorBanner(message: auth.profileError),
                TextFormField(
                  controller: _displayNameController,
                  autofocus: true,
                  maxLength: AuthProvider.maxDisplayNameLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Nama Tampilan'),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    if (length < 2) return 'Nama minimal 2 karakter';
                    if (length > AuthProvider.maxDisplayNameLength) {
                      return 'Nama terlalu panjang';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!auth.isUpdatingProfile) _submit();
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: user?.email ?? '',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    helperText: 'Perubahan email belum didukung oleh server.',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isUpdatingProfile ? null : _submit,
                  child: auth.isUpdatingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
