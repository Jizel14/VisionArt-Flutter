import 'package:flutter/material.dart';

import '../../../core/auth_service.dart';
import '../../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

/// Edit profile: name, email, bio, avatar, phone, website; saved via backend PATCH /auth/me.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.authService,
    required this.initialName,
    required this.initialEmail,
    required this.initialBio,
    required this.initialAvatarUrl,
    required this.initialPhoneNumber,
    required this.initialWebsite,
    required this.onSaved,
  });

  final AuthService authService;
  final String initialName;
  final String initialEmail;
  final String? initialBio;
  final String? initialAvatarUrl;
  final String? initialPhoneNumber;
  final String? initialWebsite;
  final VoidCallback onSaved;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _websiteController;

  bool _loading = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _bioController = TextEditingController(text: widget.initialBio ?? '');
    _avatarUrlController = TextEditingController(
      text: widget.initialAvatarUrl ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: widget.initialPhoneNumber ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.initialWebsite ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    _phoneNumberController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final bio = _bioController.text.trim();
    final avatarUrl = _avatarUrlController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final website = _websiteController.text.trim();

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
      _successMessage = null;
      _loading = true;
    });

    try {
      await widget.authService.updateProfile(
        name: name,
        email: email,
        bio: bio.isNotEmpty ? bio : null,
        avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
        website: website.isNotEmpty ? website : null,
      );

      if (mounted) {
        setState(() {
          _loading = false;
          _successMessage = 'Profile updated successfully!';
        });
        widget.onSaved();
        // Delay navigation to show success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } on SessionExpiredException {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
          ),
        );
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: context.cardBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.borderColor),
        ),
      ),
      onChanged: (_) => setState(() => _error = null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;

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
                // Avatar URL Preview
                if (_avatarUrlController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _avatarUrlController.text,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: context.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  hint: 'Your display name',
                ),
                const SizedBox(height: 20),
                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                // Bio
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  hint: 'Tell us about yourself...',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                // Avatar URL
                _buildTextField(
                  controller: _avatarUrlController,
                  label: 'Avatar URL',
                  hint: 'https://example.com/avatar.jpg',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 20),
                // Phone Number
                _buildTextField(
                  controller: _phoneNumberController,
                  label: 'Phone Number',
                  hint: '+1 (555) 000-0000',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                // Website
                _buildTextField(
                  controller: _websiteController,
                  label: 'Website',
                  hint: 'https://example.com',
                  keyboardType: TextInputType.url,
                ),
                // Success Message
                if (_successMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: AppColors.success, fontSize: 14),
                    ),
                  ),
                ],
                // Error Message
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Save Button
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
