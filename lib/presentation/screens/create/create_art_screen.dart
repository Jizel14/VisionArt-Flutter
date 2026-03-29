import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vision_craft/flutter_vision_craft.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/critic_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

/// Create New Art screen: prompt input, style picker, generate via VisionCraft API.
class CreateArtScreen extends StatefulWidget {
  const CreateArtScreen({super.key});

  @override
  State<CreateArtScreen> createState() => _CreateArtScreenState();
}

class _CreateArtScreenState extends State<CreateArtScreen> {
  late final CriticService _criticService;
  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();

  bool _loading = false;
  bool _analyzing = false;
  bool _generatingCaption = false;
  Map<String, dynamic>? _generatedCaptionMap;
  String? _error;
  Uint8List? _generatedImage;
  String? _generatedImageUrl; // Needed by the critic service which accepts URLs
  AIStyles _selectedStyle = AIStyles.abstract;

  @override
  void initState() {
    super.initState();
    _criticService = CriticService();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _error = 'Enter a description for your art';
        _generatedImage = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
      _generatedImage = null;
      _generatedImageUrl = null;
      _generatedCaptionMap = null;
    });
    try {
      final styleString = _styleLabel(_selectedStyle);
      final finalPrompt = '$prompt, in the style of $styleString';

      final result = await _criticService.generateArt(
        prompt: finalPrompt,
        negativePrompt: _negativePromptController.text.trim().isEmpty
            ? null
            : _negativePromptController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _generatedImage = result;
          _error = result.isEmpty ? 'Failed to generate image' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _generatedImage = null;
          _generatedImageUrl = null;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _generateCaption() async {
    final promptText = _promptController.text.trim();
    final prompt = promptText.isEmpty ? 'An imported image' : promptText;

    setState(() {
      _generatingCaption = true;
      _error = null;
    });

    try {
      final captionData = await _criticService.generateCaption(prompt: prompt);
      if (mounted) {
        setState(() {
          _generatingCaption = false;
          _generatedCaptionMap = captionData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatingCaption = false;
          _error = 'Failed to generate caption: $e';
        });
      }
    }
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryPurple,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Create New Art',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Describe your idea',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. A serene mountain at sunset, digital art',
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                      ),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Negative prompt (optional)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _negativePromptController,
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'e.g. blur, low quality',
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Style',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: DropdownButtonFormField<AIStyles>(
                        value: _selectedStyle,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                        ),
                        dropdownColor: cardBg,
                        items: AIStyles.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              _styleLabel(s),
                              style: TextStyle(color: textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (s) => setState(
                          () => _selectedStyle = s ?? AIStyles.abstract,
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        // Reverting back to original simple button
                        onPressed: _loading ? null : _generate,
                        icon: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 22),
                        label: Text(
                          _loading ? 'Generating…' : 'Generate image',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_generatedImage != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Result',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _generatedImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _generatingCaption
                              ? null
                              : _generateCaption,
                          icon: _generatingCaption
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.edit_note_rounded,
                                  color: AppColors.accentPink,
                                ),
                          label: Text(
                            _generatingCaption
                                ? 'Writing…'
                                : 'Autocaption',
                            style: TextStyle(color: textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.accentPink.withOpacity(
                                0.5,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_generatedCaptionMap != null) ...[
                        const SizedBox(height: 24),
                        _buildCaptionResult(context),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Future<void> _analyzeArt() async {
    if (_generatedImage == null) return;

    setState(() => _analyzing = true);
    try {
      final feedback = await _criticService.analyzeArt(
        imageUrl: _generatedImageUrl,
        imageBytes: _generatedImage,
        prompt: _promptController.text.trim(),
      );
      if (mounted) {
        setState(() => _analyzing = false);
        _showFeedbackSheet(feedback);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Critic failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showFeedbackSheet(String feedback) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: context.borderColor.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textSecondaryColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology_alt,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI Art Critic',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    feedback,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptionResult(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final map = _generatedCaptionMap!;
    final title = map['title']?.toString() ?? 'Untitled';
    final desc = map['description']?.toString() ?? '';
    final tagsRaw = map['tags'];
    final phrase = map['phrase']?.toString() ?? '';

    List<String> tags = [];
    if (tagsRaw is List) {
      tags = tagsRaw.map((e) => e.toString()).toList();
    } else if (tagsRaw is String) {
      tags = tagsRaw.split(' ').where((s) => s.startsWith('#')).toList();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentPink.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accentPink, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Published Ready',
                style: TextStyle(
                  color: AppColors.accentPink,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(color: textSecondary, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            phrase,
            style: TextStyle(
              color: textPrimary,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryPurple.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
