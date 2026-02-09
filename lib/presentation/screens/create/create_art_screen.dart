import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vision_craft/flutter_vision_craft.dart';

import '../../../core/visioncraft_service.dart';
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
  late final VisionCraftService _visionCraft;
  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();

  bool _loading = false;
  String? _error;
  Uint8List? _generatedImage;
  AIStyles _selectedStyle = AIStyles.abstract;

  @override
  void initState() {
    super.initState();
    _visionCraft = VisionCraftService();
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
    if (!_visionCraft.isConfigured) {
      setState(() {
        _error = 'VisionCraft API key not set. Use --dart-define=VISIONCRAFT_API_KEY=your_key';
        _generatedImage = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
      _generatedImage = null;
    });
    try {
      final result = await _visionCraft.generateImage(
        prompt: prompt,
        aiStyle: _selectedStyle,
        negativePrompt: _negativePromptController.text.trim().isEmpty
            ? null
            : _negativePromptController.text.trim(),
        nsfwFilter: true,
        watermark: false,
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _generatedImage = result;
          _error = result == null ? 'Failed to generate image' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _generatedImage = null;
          _error = e.toString();
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
                    if (!_visionCraft.isConfigured)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.error, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Set VISIONCRAFT_API_KEY (from VisionCraft Telegram bot) to generate images.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: textPrimary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        hintText: 'e.g. A serene mountain at sunset, digital art',
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                        ),
                        dropdownColor: cardBg,
                        items: VisionCraftService.availableStyles.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              _styleLabel(s),
                              style: TextStyle(color: textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (s) => setState(() => _selectedStyle = s ?? AIStyles.abstract),
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
                        onPressed: _loading || !_visionCraft.isConfigured ? null : _generate,
                        icon: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome, size: 22),
                        label: Text(_loading ? 'Generating…' : 'Generate image'),
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
    return '${withSpaces[0].toUpperCase()}${withSpaces.substring(1).toLowerCase()}'.trim();
  }
}
