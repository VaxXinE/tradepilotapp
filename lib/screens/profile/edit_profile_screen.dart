import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/api/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/l10n.dart';
import '../../widgets/error_banner.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  bool _uploadingAvatar = false;

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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.profileUpdated)));
    Navigator.of(context).pop();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final contentType = _imageContentType(file);
    if (contentType == null || bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.avatarRequirements)),
        );
      }
      return;
    }

    setState(() => _uploadingAvatar = true);
    final auth = context.read<AuthProvider>();
    try {
      final response = await auth.client.storage.requestUploadUrl(
        uploadUrlRequest: UploadUrlRequest(
          (builder) => builder
            ..name = file.name
            ..size = bytes.length
            ..contentType = contentType,
        ),
      );
      final target = response.data;
      if (target == null) throw StateError('Missing upload target');
      await Dio().putUri<void>(
        Uri.parse(target.uploadURL),
        data: bytes,
        options: Options(contentType: contentType),
      );
      final saved = await auth.updateAvatarPath(target.objectPath);
      if (!saved) throw StateError('Profile update failed');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.avatarUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _uploadingAvatar = true);
    await context.read<AuthProvider>().updateAvatarPath(null);
    if (mounted) setState(() => _uploadingAvatar = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final l10n = context.l10n;
    final avatar = _avatarUrl(user?.avatarUrl);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorBanner(message: auth.profileError),
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    foregroundImage: avatar == null
                        ? null
                        : NetworkImage(avatar),
                    child: user?.avatarUrl == null
                        ? const Icon(Icons.person_rounded, size: 42)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _uploadingAvatar ? null : _pickAvatar,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.changePhoto),
                    ),
                    if (user?.avatarUrl != null)
                      TextButton(
                        onPressed: _uploadingAvatar ? null : _removeAvatar,
                        child: Text(l10n.remove),
                      ),
                  ],
                ),
                if (_uploadingAvatar) const LinearProgressIndicator(),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _displayNameController,
                  autofocus: true,
                  maxLength: AuthProvider.maxDisplayNameLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: l10n.displayName),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    if (length < 2) return l10n.nameMinimumCharacters;
                    if (length > AuthProvider.maxDisplayNameLength) {
                      return l10n.nameTooLong;
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
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    helperText: l10n.emailChangeUnsupported,
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
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _imageContentType(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (const {
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
    }.contains(mime)) {
      return mime;
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return null;
  }

  String? _avatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConfig.baseUrl}/storage/$clean';
  }
}
