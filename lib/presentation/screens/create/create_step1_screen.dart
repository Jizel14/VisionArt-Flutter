import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import '../../../core/visioncraft_service.dart';
import '../../../core/preference_storage.dart';
import '../../../core/user_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import 'package:visionart_mobile/presentation/screens/splash/widgets/app_background_wrapper.dart';
import 'art_creation_model.dart';

/// Step 1: Prompt, Negative Prompt, and Personality toggle.
class CreateStep1Screen extends StatefulWidget {
  const CreateStep1Screen({
    super.key,
    required this.config,
    required this.isVisionCraftConfigured,
    required this.onNext,
  });

  final ArtCreationConfig config;
  final bool isVisionCraftConfigured;
  final void Function(ArtCreationConfig) onNext;

  @override
  State<CreateStep1Screen> createState() => _CreateStep1ScreenState();
}

class _CreateStep1ScreenState extends State<CreateStep1Screen> {
  late final TextEditingController _promptCtrl;
  late final TextEditingController _negativeCtrl;
  late bool _useNegative;
  late bool _usePersonality;
  UserPreferences? _prefs;
  String? _validationError;
  bool _isDrawingMode = false;
  bool _isAnalyzing = false;
  late final SignatureController _sigCtrl;
  final VisionCraftService _visionService = VisionCraftService();

  @override
  void initState() {
    super.initState();
    _promptCtrl = TextEditingController(text: widget.config.prompt);
    _negativeCtrl = TextEditingController(text: widget.config.negativePrompt);
    _useNegative = widget.config.useNegativePrompt;
    _usePersonality = widget.config.useUserPersonality;
    _loadPrefs();
    _sigCtrl = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.white,
      exportBackgroundColor: Colors.black,
    );
  }

  Future<void> _loadPrefs() async {
    final p = await PreferenceStorage.load();
    if (mounted) setState(() => _prefs = p);
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _negativeCtrl.dispose();
    _sigCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyzeSketch() async {
    if (_sigCtrl.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await _sigCtrl.toPngBytes();
      if (bytes != null) {
        final base64Image = base64Encode(bytes);
        final analyzedPrompt = await _visionService.analyzeDrawing(base64Image);
        
        if (analyzedPrompt != null && analyzedPrompt.isNotEmpty) {
           _promptCtrl.text = analyzedPrompt;
           setState(() {
             _isDrawingMode = false;
             _validationError = null;
           });
        }
      }
    } catch (e) {
      setState(() => _validationError = "Failed to interpret drawing. Use text instead.");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _onNext() {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() => _validationError = 'Please describe your idea first!');
      return;
    }
    final config = ArtCreationConfig()
      ..prompt = prompt
      ..negativePrompt = _negativeCtrl.text.trim()
      ..useNegativePrompt = _useNegative
      ..useUserPersonality = _usePersonality;
    widget.onNext(config);
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);
    final cardBg = AppThemeColors.cardBackgroundColor(context);
    final borderCol = AppThemeColors.borderColor(context);

    return AppBackgroundWrapper(
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Art',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          'Step 1 of 2 — Describe your idea',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Step indicator pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.4)),
                    ),
                    child: Text(
                      '1 / 2',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Mode Toggle (Text vs Sketch) ──────────────────
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
               child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: borderCol.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                       Expanded(
                         child: GestureDetector(
                           onTap: () => setState(() => _isDrawingMode = false),
                           child: Container(
                              decoration: BoxDecoration(
                                color: !_isDrawingMode ? AppColors.primaryPurple : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Text Prompt',
                                style: TextStyle(
                                  color: !_isDrawingMode ? Colors.white : textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13
                                ),
                              ),
                           ),
                         ),
                       ),
                       Expanded(
                         child: GestureDetector(
                           onTap: () => setState(() => _isDrawingMode = true),
                           child: Container(
                              decoration: BoxDecoration(
                                color: _isDrawingMode ? AppColors.primaryPurple : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.brush_rounded, 
                                    size: 14, 
                                    color: _isDrawingMode ? Colors.white : textSecondary
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sketch AI',
                                    style: TextStyle(
                                      color: _isDrawingMode ? Colors.white : textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13
                                    ),
                                  ),
                                ],
                              ),
                           ),
                         ),
                       ),
                    ],
                  ),
               ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Mode Content ───────────────────────────
                    if (!_isDrawingMode) ...[
                      FadeInLeft(
                        duration: const Duration(milliseconds: 350),
                        child: _SectionLabel(
                          icon: Icons.edit_note_rounded,
                          text: 'Describe your idea',
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 400),
                        child: _StyledTextField(
                          controller: _promptCtrl,
                          hint: 'e.g. A fox sitting on a moonlit hill, fantasy style…',
                          maxLines: 4,
                          cardBg: cardBg,
                          borderCol: borderCol,
                          textPrimary: textPrimary,
                          onChanged: (_) => setState(() => _validationError = null),
                        ),
                      ),
                    ] else ...[
                      // ── Sketch Board ─────────────────────────
                      _SectionLabel(
                        icon: Icons.auto_fix_high_rounded,
                        text: 'Draw your idea',
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 10),
                      FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderCol),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                                child: Signature(
                                  controller: _sigCtrl,
                                  height: 220,
                                  backgroundColor: Colors.black,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                   color: borderCol.withOpacity(0.3),
                                   borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.undo_rounded, size: 20, color: Colors.white),
                                      onPressed: () => _sigCtrl.undo(),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white),
                                      onPressed: () => _sigCtrl.clear(),
                                    ),
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _isAnalyzing 
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple))
                                        : TextButton.icon(
                                            onPressed: _analyzeSketch,
                                            icon: const Icon(Icons.psychology_rounded, size: 16, color: AppColors.primaryPurple),
                                            label: const Text('AI Interpret', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tip: Loose sketches work best. Gemini will turn this drawing into a professional prompt.',
                        style: TextStyle(color: textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    if (_validationError != null) ...[
                      const SizedBox(height: 8),
                      FadeIn(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Negative prompt toggle ───────────────────
                    FadeInLeft(
                      duration: const Duration(milliseconds: 450),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          children: [
                            // Toggle row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.block_rounded, color: textSecondary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Negative prompt',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'optional',
                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: _useNegative,
                                    activeThumbColor: AppColors.primaryPurple,
                                    onChanged: (v) => setState(() => _useNegative = v),
                                  ),
                                ],
                              ),
                            ),

                            // Animated expansion
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _useNegative
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                      child: TextField(
                                        controller: _negativeCtrl,
                                        maxLines: 2,
                                        style: TextStyle(color: textPrimary, fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'e.g. blur, ugly, distorted, text, watermark…',
                                          hintStyle: TextStyle(
                                            color: textSecondary.withOpacity(0.5),
                                            fontSize: 12,
                                          ),
                                          filled: true,
                                          fillColor: borderCol.withOpacity(0.3),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.all(12),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Personality toggle ───────────────────────
                    if (_prefs != null && _prefs!.onboardingComplete)
                      FadeInLeft(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacity(0.1),
                                AppColors.primaryBlue.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primaryPurple.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.psychology_rounded,
                                  color: AppColors.primaryPurple,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Use my art personality',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      _buildPersonalitySummary(_prefs!),
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _usePersonality,
                                activeThumbColor: AppColors.primaryPurple,
                                onChanged: (v) => setState(() => _usePersonality = v),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Next button ──────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _onNext,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                          label: const Text(
                            'Choose Style & Generate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildPersonalitySummary(UserPreferences p) {
    final parts = <String>[];
    if (p.subjects.isNotEmpty) parts.add(p.subjects.first);
    if (p.styles.isNotEmpty) parts.add(p.styles.first);
    if (p.mood != null) parts.add(p.mood!);
    return parts.isEmpty ? 'Based on your onboarding preferences' : parts.join(' · ');
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.text,
    required this.textSecondary,
  });

  final IconData icon;
  final String text;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.cardBg,
    required this.borderCol,
    required this.textPrimary,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final Color cardBg;
  final Color borderCol;
  final Color textPrimary;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textPrimary, fontSize: 14),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: textPrimary.withOpacity(0.5),
          fontSize: 13,
        ),
        filled: true,
        fillColor: cardBg.withOpacity(0.5), // Glass-like blend
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderCol.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderCol.withOpacity(0.5)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide(color: AppColors.primaryPurple, width: 2.0),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }
}
