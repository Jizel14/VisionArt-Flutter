import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/services/image_generation_service.dart';
import '../../../core/visioncraft_service.dart' show AIStyles;
import '../../../features/subscription/models/subscription_model.dart';
import '../../../features/subscription/services/subscription_service.dart';
import '../../../features/subscription/widgets/quota_banner_widget.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

/// Create New Art screen with two-step flow:
/// Step 1: Text Prompt or Sketch AI
/// Step 2: Style selection and generation
class CreateArtScreen extends StatefulWidget {
  const CreateArtScreen({super.key});

  @override
  State<CreateArtScreen> createState() => _CreateArtScreenState();
}

enum CreateMode { textPrompt, sketchAI }

class _CreateArtScreenState extends State<CreateArtScreen> {
  final _imageGen = ImageGenerationService();
  final _artworkService = ArtworkService();
  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();

  int _currentStep = 1;
  CreateMode _createMode = CreateMode.textPrompt;
  bool _showNegativePrompt = false;
  bool _useArtPersonality = true;

  bool _loading = false;
  bool _saving = false;
  String? _error;
  Uint8List? _generatedImage;
  String? _artworkId;
  AIStyles _selectedStyle = AIStyles.abstract;

  SubscriptionModel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = await SubscriptionService().getMySubscription();
      if (mounted) setState(() => _subscription = sub);
    } catch (_) {}
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (_promptController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe your idea');
      return;
    }
    setState(() {
      _currentStep = 2;
      _error = null;
    });
  }

  void _goToStep1() {
    setState(() => _currentStep = 1);
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'Enter a description for your art');
      return;
    }
    if (_subscription != null && _subscription!.quotaExceeded) {
      setState(() => _error = 'Quota exceeded. Upgrade your plan.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
      _generatedImage = null;
      _artworkId = null;
    });
    try {
      final result = await _imageGen.generateImage(
        prompt: prompt,
        negativePrompt: _showNegativePrompt &&
                _negativePromptController.text.trim().isNotEmpty
            ? _negativePromptController.text.trim()
            : null,
        style: _styleApiValue(_selectedStyle),
        aspectRatio: 'square',
        quality: 4,
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _generatedImage = result;
        });
        // Auto-save the artwork
        await _saveAsArtwork();
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

  Future<void> _saveAsArtwork() async {
    if (_generatedImage == null) return;
    setState(() => _saving = true);
    try {
      final base64Image = base64Encode(_generatedImage!);
      final dataUrl = 'data:image/png;base64,$base64Image';

      final artwork = await _artworkService.createArtwork(
        title: _promptController.text.trim().substring(
              0,
              _promptController.text.trim().length > 50
                  ? 50
                  : _promptController.text.trim().length,
            ),
        description: _promptController.text.trim(),
        imageUrl: dataUrl,
        prompt: {
          'text': _promptController.text.trim(),
          'style': _selectedStyle.name
        },
        isPublic: true,
      );

      if (mounted) {
        setState(() {
          _artworkId = artwork.id;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artwork saved to your gallery!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _reset() {
    setState(() {
      _currentStep = 1;
      _generatedImage = null;
      _artworkId = null;
      _error = null;
      _promptController.clear();
      _negativePromptController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final cardBg = context.cardBackgroundColor;
    final border = context.borderColor;

    return SmokeBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Art',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          'Step $_currentStep of 2 — ${_currentStep == 1 ? "Describe your idea" : "Choose style"}',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Step indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primaryPurple.withOpacity(0.3)),
                    ),
                    child: Text(
                      '$_currentStep / 2',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_subscription != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: QuotaBanner(subscription: _subscription!),
              ),
            Expanded(
              child: _currentStep == 1
                  ? _buildStep1(
                      context, textPrimary, textSecondary, cardBg, border)
                  : _buildStep2(
                      context, textPrimary, textSecondary, cardBg, border),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(BuildContext context, Color textPrimary,
      Color textSecondary, Color cardBg, Color border) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text Prompt / Sketch AI Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _createMode = CreateMode.textPrompt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _createMode == CreateMode.textPrompt
                            ? AppColors.primaryGradient
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Text Prompt',
                          style: TextStyle(
                            color: _createMode == CreateMode.textPrompt
                                ? Colors.white
                                : textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _createMode = CreateMode.sketchAI),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _createMode == CreateMode.sketchAI
                            ? AppColors.primaryGradient
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.brush_outlined,
                              size: 16,
                              color: _createMode == CreateMode.sketchAI
                                  ? Colors.white
                                  : textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sketch AI',
                              style: TextStyle(
                                color: _createMode == CreateMode.sketchAI
                                    ? Colors.white
                                    : textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Prompt Input Section
          Row(
            children: [
              Icon(Icons.auto_awesome_mosaic,
                  size: 18, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Text(
                _createMode == CreateMode.textPrompt
                    ? 'Describe your idea'
                    : 'Draw your idea',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_createMode == CreateMode.textPrompt)
            TextField(
              controller: _promptController,
              maxLines: 5,
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText:
                    'e.g. A fox sitting on a moonlit hill, fantasy style...',
                hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: border.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: AppColors.primaryPurple, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              onChanged: (_) => setState(() => _error = null),
            )
          else
            // Sketch Canvas Placeholder
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border.withOpacity(0.5)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.brush,
                        size: 48, color: textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'Draw your sketch here',
                      style: TextStyle(color: textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tip: Loose sketches work best. Gemini will turn this into a professional prompt.',
                      style: TextStyle(
                          color: textSecondary.withOpacity(0.6), fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Negative Prompt Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.block_outlined, size: 20, color: textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Negative prompt',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  'optional',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _showNegativePrompt,
                  onChanged: (v) => setState(() => _showNegativePrompt = v),
                  activeColor: AppColors.primaryPurple,
                ),
              ],
            ),
          ),

          if (_showNegativePrompt) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _negativePromptController,
              maxLines: 1,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. blur, low quality, deformed',
                hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border.withOpacity(0.5)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Art Personality Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple.withOpacity(0.1),
                  AppColors.primaryBlue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.psychology,
                      color: AppColors.primaryPurple, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use my art personality',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Based on your onboarding preferences',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _useArtPersonality,
                  onChanged: (v) => setState(() => _useArtPersonality = v),
                  activeColor: AppColors.primaryPurple,
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Next Step Button
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _goToStep2,
              icon: const Icon(Icons.arrow_forward, size: 22),
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
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, Color textPrimary,
      Color textSecondary, Color cardBg, Color border) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          GestureDetector(
            onTap: _goToStep1,
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios, size: 16, color: textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                      color: textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Prompt Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your prompt',
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  _promptController.text.trim(),
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Style Selection
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  size: 18, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Text(
                'Choose a style',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Style Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AIStyles.values.map((style) {
              final isSelected = _selectedStyle == style;
              return GestureDetector(
                onTap: () => setState(() => _selectedStyle = style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : border.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _styleLabel(style),
                    style: TextStyle(
                      color: isSelected ? Colors.white : textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Generated Image Preview or Generate Button
          if (_generatedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                _generatedImage!,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Create Another'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/gallery');
                    },
                    icon: const Icon(Icons.collections, size: 20),
                    label: const Text('View Gallery'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _loading || (_subscription?.quotaExceeded ?? false)
                    ? null
                    : _generate,
                icon: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 24),
                label: Text(
                  _loading ? 'Generating...' : 'Generate Image',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 12),
            if (_loading)
              Text(
                'This may take 10-30 seconds...',
                style: TextStyle(color: textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
          ],
        ],
      ),
    );
  }

  static String _styleLabel(AIStyles s) {
    final name = s.name;
    if (name.isEmpty) return name;
    final withSpaces = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(1)}',
    );
    return '${withSpaces[0].toUpperCase()}${withSpaces.substring(1).toLowerCase()}'
        .trim();
  }

  /// Map enum -> backend style key (matches values handled in
  /// backend ImageGenerationService.generateImage)
  static String? _styleApiValue(AIStyles s) {
    switch (s) {
      case AIStyles.anime:
        return 'anime';
      case AIStyles.digitalArt:
        return 'dreamescape';
      case AIStyles.sketch:
        return 'lineArt';
      default:
        return null;
    }
  }
}
