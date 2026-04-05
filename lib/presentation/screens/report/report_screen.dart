import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

/// Types of reports available.
enum ReportCategory {
  artwork('artwork', 'Oeuvre inappropriée', Icons.palette_rounded),
  bug('bug', 'Bug / Problème technique', Icons.bug_report_rounded),
  user('user', 'Utilisateur abusif', Icons.person_off_rounded),
  other('other', 'Autre', Icons.flag_rounded);

  const ReportCategory(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.authService,
    this.initialType,
    this.targetId,
    this.targetLabel,
  });

  final AuthService authService;

  /// Pre-selected report type (e.g. 'artwork' when tapping '!' on a card).
  final String? initialType;

  /// ID of the artwork or user being reported.
  final String? targetId;

  /// A human-readable label for the target (e.g. artwork title).
  final String? targetLabel;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late ReportCategory _selectedCategory;
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCategory = ReportCategory.values.firstWhere(
      (c) => c.value == widget.initialType,
      orElse: () => ReportCategory.other,
    );

    // Pre-fill subject when reporting a specific target
    if (widget.targetLabel != null) {
      _subjectCtrl.text = 'Signalement: ${widget.targetLabel}';
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    if (subject.length < 3) {
      setState(() => _error = 'Le sujet doit contenir au moins 3 caractères');
      return;
    }
    if (description.length < 5) {
      setState(
          () => _error = 'La description doit contenir au moins 5 caractères');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.authService.submitReport(
        type: _selectedCategory.value,
        subject: subject,
        description: description,
        targetId: widget.targetId,
        imageUrl: _imageUrlCtrl.text.trim().isNotEmpty
            ? _imageUrlCtrl.text.trim()
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signalement envoyé avec succès !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final cardBg = context.cardBackgroundColor;
    final border = context.borderColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Signaler',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SmokeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target info banner
                if (widget.targetId != null) ...[
                  _GlassContainer(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.lightBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.targetLabel != null
                                ? 'Cible: ${widget.targetLabel}'
                                : 'ID: ${widget.targetId}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Category selector
                Text(
                  'Type de signalement',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReportCategory.values.map((cat) {
                    final selected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryPurple.withOpacity(0.2)
                              : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryPurple
                                : border.withOpacity(0.5),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                size: 18,
                                color: selected
                                    ? AppColors.primaryPurple
                                    : textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primaryPurple
                                    : textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Subject
                _buildTextField(
                  controller: _subjectCtrl,
                  label: 'Sujet',
                  hint: 'Décrivez brièvement le problème',
                  maxLines: 1,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  cardBg: cardBg,
                  border: border,
                ),

                const SizedBox(height: 16),

                // Description
                _buildTextField(
                  controller: _descriptionCtrl,
                  label: 'Description détaillée',
                  hint:
                      'Expliquez en détail ce que vous souhaitez signaler...',
                  maxLines: 5,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  cardBg: cardBg,
                  border: border,
                ),

                const SizedBox(height: 16),

                // Image URL (for bug reports)
                if (_selectedCategory == ReportCategory.bug) ...[
                  _buildTextField(
                    controller: _imageUrlCtrl,
                    label: 'Capture d\'écran (URL)',
                    hint: 'Collez un lien vers l\'image du bug',
                    maxLines: 1,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                    border: border,
                    icon: Icons.image_rounded,
                  ),
                  const SizedBox(height: 16),
                ],

                // Error message
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      _error!,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.shadowSmall(AppColors.primaryPurple),
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Envoyer le signalement',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color border,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                prefixIcon: icon != null
                    ? Icon(icon, color: textSecondary, size: 20)
                    : null,
                filled: true,
                fillColor: cardBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: border.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: border.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassContainer extends StatelessWidget {
  const _GlassContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.borderColor.withOpacity(0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
