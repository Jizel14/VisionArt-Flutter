import 'package:flutter/material.dart';

import '../../../core/auth_service.dart';
import '../../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

/// Edit profile: name and email, saved via backend PATCH /auth/me.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.authService,
    required this.initialName,
    required this.initialEmail,
    required this.onSaved,
  });

  final AuthService authService;
  final String initialName;
  final String initialEmail;
  final VoidCallback onSaved;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Email is required');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await widget.authService.updateProfile(name: name, email: email);
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit profile', style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SmokeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Your display name',
                    filled: true,
                    fillColor: context.cardBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'your@email.com',
                    filled: true,
                    fillColor: context.cardBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
