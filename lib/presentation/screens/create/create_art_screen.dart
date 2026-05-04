import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/preference_storage.dart';
import '../../../core/services/image_generation_service.dart';
import '../../../core/visioncraft_service.dart';
import '../../../features/subscription/models/subscription_model.dart';
import '../../../features/subscription/services/subscription_service.dart';
import '../../../features/subscription/widgets/quota_banner_widget.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import '../../widgets/ai_audio_widgets.dart';
import 'art_creation_model.dart';
import 'create_step1_screen.dart';
import 'create_step2_screen.dart';

/// Two-step create flow (prompt / style) then image via backend
/// [`/image-generation/generate`]. Result screen offers **one-tap** sonic
/// generation (`AudioGenButton` → `/audio/for-image`).
class CreateArtScreen extends StatefulWidget {
  const CreateArtScreen({super.key});

  @override
  State<CreateArtScreen> createState() => _CreateArtScreenState();
}

class _CreateArtScreenState extends State<CreateArtScreen> {
  final _imageGen = ImageGenerationService();
  final _config = ArtCreationConfig();
  final _visionCraft = VisionCraftService();

  int _step = 0;
  bool _generating = false;
  String? _error;
  Uint8List? _result;

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

  void _goToStep2(ArtCreationConfig updated) {
    _config.prompt = updated.prompt;
    _config.negativePrompt = updated.negativePrompt;
    _config.useNegativePrompt = updated.useNegativePrompt;
    _config.useUserPersonality = updated.useUserPersonality;
    setState(() {
      _step = 1;
      _result = null;
      _error = null;
    });
  }

  void _goBack() {
    setState(() {
      _step = 0;
      _result = null;
      _error = null;
    });
  }

  void _resetToStep1() {
    setState(() {
      _config.prompt = '';
      _config.negativePrompt = '';
      _step = 0;
      _result = null;
      _error = null;
    });
  }

  Future<void> _generate(ArtCreationConfig updated) async {
    _config.selectedVisualStyle = updated.selectedVisualStyle;
    _config.aspectRatio = updated.aspectRatio;
    _config.quality = updated.quality;

    if (_subscription != null && _subscription!.quotaExceeded) {
      setState(() {
        _error =
            'You have reached your generation limit. Upgrade or wait for renewal.';
      });
      return;
    }

    final style = _config.selectedVisualStyle ?? kVisualStyles.first;
    final prefs = await PreferenceStorage.load();
    final enhanced = _config.buildEnhancedPrompt(
      userSubjects: prefs.subjects,
      userStyles: prefs.styles,
      userColors: prefs.colors,
      userMood: prefs.mood,
      userComplexity: prefs.complexity,
    );
    final neg = _config.buildNegativePrompt(
      styleHint: style.negativePromptHint,
    );

    setState(() {
      _generating = true;
      _error = null;
      _result = null;
    });

    try {
      final bytes = await _imageGen.generateImage(
        prompt: enhanced,
        negativePrompt: neg.isEmpty ? null : neg,
        style: style.styleName,
        aspectRatio: _config.aspectRatio.name,
        quality: _config.quality,
      );
      if (mounted) {
        setState(() {
          _generating = false;
          _result = bytes;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return SmokeBackground(
        child: _CreateResultView(
          imageBytes: _result!,
          sonicKeywords: _sonicKeywordsFromConfig(_config),
          onCreateAnother: _resetToStep1,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_subscription != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: QuotaBanner(subscription: _subscription!),
          ),
        Expanded(
          child: _step == 0
              ? CreateStep1Screen(
                  config: _config,
                  isVisionCraftConfigured: _visionCraft.isConfigured,
                  onNext: _goToStep2,
                )
              : CreateStep2Screen(
                  config: _config,
                  generating: _generating,
                  error: _error,
                  onBack: _goBack,
                  onGenerate: _generate,
                ),
        ),
      ],
    );
  }
}

String _sonicKeywordsFromConfig(ArtCreationConfig c) {
  final style = c.selectedVisualStyle?.label ?? 'ambient';
  final raw = c.prompt.trim();
  final snippet = raw.length > 160 ? '${raw.substring(0, 160)}…' : raw;
  if (snippet.isEmpty) {
    return '$style, ambient, atmospheric, calm';
  }
  return '$style, $snippet';
}

class _CreateResultView extends StatefulWidget {
  const _CreateResultView({
    required this.imageBytes,
    required this.sonicKeywords,
    required this.onCreateAnother,
  });

  final Uint8List imageBytes;
  final String sonicKeywords;
  final VoidCallback onCreateAnother;

  @override
  State<_CreateResultView> createState() => _CreateResultViewState();
}

class _CreateResultViewState extends State<_CreateResultView> {
  bool _isGeneratingAudio = false;
  String? _audioUrl;

  @override
  Widget build(BuildContext context) {
    final textSecondary = context.textSecondaryColor;

    return Stack(
      children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onCreateAnother,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Your creation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Univers sonore',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Un seul appui sur l’icône lance la génération audio.',
                        style: TextStyle(
                          color: textSecondary.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: widget.onCreateAnother,
                              icon: const Icon(Icons.add_photo_alternate_rounded,
                                  size: 20),
                              label: const Text(
                                'Create another',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.14),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AudioGenButton(
                            artworkId: 'local',
                            keywords: widget.sonicKeywords,
                            onStarted: () => setState(() {
                              _isGeneratingAudio = true;
                              _audioUrl = null;
                            }),
                            onComplete: (url) => setState(() {
                              _isGeneratingAudio = false;
                              _audioUrl = url;
                            }),
                            onError: () => setState(() {
                              _isGeneratingAudio = false;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isGeneratingAudio)
          ColoredBox(
            color: Colors.black.withOpacity(0.82),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Composition de votre univers sonore…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ceci peut prendre une minute.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        if (_audioUrl != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SimpleAudioPlayer(url: _audioUrl!),
          ),
      ],
    );
  }
}
