import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/services/image_generation_service.dart';
import '../../../core/visioncraft_service.dart' show AIStyles;
import '../../../features/subscription/models/subscription_model.dart';
import '../../../features/subscription/services/subscription_service.dart';
import '../../../features/subscription/widgets/quota_banner_widget.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

/// Create New Art screen — sends prompt to backend (`/image-generation/generate`)
/// which proxies to HuggingFace FLUX.1-schnell. No client-side AI key needed.
class CreateArtScreen extends StatefulWidget {
  const CreateArtScreen({super.key});

  @override
  State<CreateArtScreen> createState() => _CreateArtScreenState();
}

class _CreateArtScreenState extends State<CreateArtScreen> {
  final _imageGen = ImageGenerationService();
  final _promptController = TextEditingController();
  final _negativePromptController = TextEditingController();

  bool _loading = false;
  String? _error;
  Uint8List? _generatedImage;
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
    } catch (_) {
      // Non-critical — server-side enforcement still applies.
    }
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
    if (_subscription != null && _subscription!.quotaExceeded) {
      setState(() {
        _error = null;
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
      final result = await _imageGen.generateImage(
        prompt: prompt,
        negativePrompt: _negativePromptController.text.trim().isEmpty
            ? null
            : _negativePromptController.text.trim(),
        style: _styleApiValue(_selectedStyle),
        aspectRatio: 'square',
        quality: 4,
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _generatedImage = result;
        });
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
            if (_subscription != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: QuotaBanner(subscription: _subscription!),
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
                        items: AIStyles.values.map((s) {
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
                        onPressed: _loading ||
                                (_subscription?.quotaExceeded ?? false)
                            ? null
                            : _generate,
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
