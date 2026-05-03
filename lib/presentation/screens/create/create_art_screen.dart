import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/artwork_model.dart';
import '../../../core/preference_storage.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/visioncraft_service.dart';
import '../../../core/web_download.dart';
import '../../widgets/ai_audio_widgets.dart';
import '../../theme/app_colors.dart';
import 'art_creation_model.dart';
import 'create_step1_screen.dart';
import 'create_step2_screen.dart';

/// Multi-step art creation flow controller.
/// Manages the 2-step process: [CreateStep1Screen] → [CreateStep2Screen] → result.
class CreateArtScreen extends StatefulWidget {
  const CreateArtScreen({super.key});

  @override
  State<CreateArtScreen> createState() => _CreateArtScreenState();
}

class _CreateArtScreenState extends State<CreateArtScreen> {
  int _step = 0; // 0 = step1, 1 = step2
  final _config = ArtCreationConfig();
  bool _generating = false;
  String? _error;
  Uint8List? _result;
  String? _artworkId;
  late final VisionCraftService _visionCraft;

  @override
  void initState() {
    super.initState();
    _visionCraft = VisionCraftService();
  }

  void _goToStep2(ArtCreationConfig updatedConfig) {
    _config.prompt = updatedConfig.prompt;
    _config.negativePrompt = updatedConfig.negativePrompt;
    _config.useNegativePrompt = updatedConfig.useNegativePrompt;
    _config.useUserPersonality = updatedConfig.useUserPersonality;
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

  Future<void> _generate(ArtCreationConfig updatedConfig) async {
    _config.selectedVisualStyle = updatedConfig.selectedVisualStyle;
    _config.aspectRatio = updatedConfig.aspectRatio;
    _config.quality = updatedConfig.quality;

    if (!_visionCraft.isConfigured) {
      setState(() {
        _error = 'Set your VISIONCRAFT_API_KEY in the .env file to generate images.';
      });
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
      _result = null;
    });

    try {
      final prefs = await PreferenceStorage.load();
      final style = _config.selectedVisualStyle;
      final enhancedPrompt = _config.buildEnhancedPrompt(
        userSubjects: prefs.subjects,
        userStyles: prefs.styles,
        userColors: prefs.colors,
        userMood: prefs.mood,
        userComplexity: prefs.complexity,
      );

      final negPpt = _config.buildNegativePrompt(
        styleHint: style?.negativePromptHint,
      );

      final styleName = style?.styleName ?? kVisualStyles.first.styleName;

      final response = await _visionCraft.generateImage(
        prompt: enhancedPrompt,
        styleName: styleName,
        negativePrompt: negPpt,
        aspectRatio: _config.aspectRatio.name,
        quality: _config.quality,
        generateSimilar: _config.generateSimilar,
      );

      if (mounted) {
        setState(() {
          _generating = false;
          if (response != null) {
            _result = response['imageBytes'];
            _artworkId = response['artworkId'];
          }
          _error = response == null ? 'Failed to generate image. Try again.' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = 'Error: ${e.toString()}';
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _ResultView(
        imageBytes: _result!,
        artworkId: _artworkId,
        onCreateAnother: _resetToStep1,
      );
    }

    if (_step == 0) {
      return CreateStep1Screen(
        config: _config,
        isVisionCraftConfigured: _visionCraft.isConfigured,
        onNext: _goToStep2,
      );
    }

    return CreateStep2Screen(
      config: _config,
      generating: _generating,
      error: _error,
      onBack: _goBack,
      onGenerate: _generate,
    );
  }
}

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.imageBytes,
    required this.onCreateAnother,
    this.artworkId,
  });

  final Uint8List imageBytes;
  final VoidCallback onCreateAnother;
  final String? artworkId;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  bool _isSaving = false;
  bool _isGeneratingAudio = false;
  String? _audioUrl;

  // NEW: Critique & Storytelling State
  bool _isAnalyzing = false;
  Map<String, dynamic>? _critique;
  bool _isGeneratingScenarios = false;
  List<String>? _scenarios;

  final _artworkService = ArtworkService();
  final _visionCraft = VisionCraftService();
  List<ArtworkModel> _similarArtworks = [];
  bool _loadingSimilar = false;
  bool _similarLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.artworkId != null) {
      _fetchSimilarArtworks();
    }
  }

  Future<void> _fetchCritique() async {
    if (widget.artworkId == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final result = await _visionCraft.getCritique(widget.artworkId!);
      if (mounted) {
        setState(() {
          _critique = result;
          _isAnalyzing = false;
        });
        _showCritiqueDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'analyse : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchScenarios() async {
    if (widget.artworkId == null) return;
    setState(() => _isGeneratingScenarios = true);
    try {
      final result = await _visionCraft.getStorytellingScenarios(widget.artworkId!);
      if (mounted) {
        setState(() {
          _scenarios = result;
          _isGeneratingScenarios = false;
        });
        _showScenariosSheet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingScenarios = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Storytelling : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCritiqueDialog() {
    if (_critique == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(child: Text(_critique!['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_critique!['interpretation'], style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            const Text('Styles & Influences :', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (_critique!['suggestions'] as List).map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: Colors.white.withOpacity(0.1),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer', style: TextStyle(color: AppColors.primaryPurple))),
        ],
      ),
    );
  }

  void _showScenariosSheet() {
    if (_scenarios == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La suite de l\'histoire...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choisissez un scénario pour générer la scène suivante :', style: TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 24),
            ..._scenarios!.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  // We could trigger a new generation here with this prompt
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Génération : $s')));
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 16),
                      Expanded(child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 14))),
                      const Icon(Icons.chevron_right, color: Colors.white24),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchSimilarArtworks() async {
    setState(() => _loadingSimilar = true);
    try {
      final result = await _artworkService.getSimilarArtworks(
        widget.artworkId!,
        limit: 6,
        generate: true,
      );
      if (mounted) {
        setState(() {
          _similarArtworks = result;
          _loadingSimilar = false;
          _similarLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingSimilar = false;
          _similarLoaded = true;
        });
      }
    }
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    try {
      if (kIsWeb) {
        downloadWebImage(widget.imageBytes, 'visionart_${DateTime.now().millisecondsSinceEpoch}.png');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar('✅ Download started!', success: true),
          );
        }
      } else {
        final result = await ImageGallerySaverPlus.saveImage(
          widget.imageBytes,
          quality: 100,
          name: 'visionart_${DateTime.now().millisecondsSinceEpoch}',
        );
        final saved = result['isSuccess'] == true;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(
              saved ? '🎨 Saved to Gallery!' : '❌ Could not save. Try again.',
              success: saved,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('❌ Error saving image: $e', success: false),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  SnackBar _buildSnackBar(String msg, {required bool success}) {
    return SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  ImageProvider? _imageProviderFor(ArtworkModel art) {
    if (art.imageUrl.startsWith('data:image')) {
      return MemoryImage(base64Decode(art.imageUrl.split(',').last));
    } else if (art.imageUrl.startsWith('http')) {
      return NetworkImage(art.imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(widget.imageBytes, fit: BoxFit.cover),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withOpacity(0.55)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: widget.onCreateAnother,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Masterpiece',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.25),
                              blurRadius: 30,
                              spreadRadius: -5,
                            ),
                          ],
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: InteractiveViewer(
                            child: Image.memory(widget.imageBytes,
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryPurple.withOpacity(0.3),
                                    AppColors.primaryBlue.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.auto_awesome_mosaic_rounded,
                                  size: 14,
                                  color: Colors.white70),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'More Like This',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            if (_loadingSimilar)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white38),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: _loadingSimilar
                              ? _buildShimmer()
                              : _similarArtworks.isEmpty && _similarLoaded
                                  ? _buildEmptyHint()
                                  : _buildSimilarStrip(),
                        ),
                      ],
                    ),
                  ),
                ),

                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: widget.onCreateAnother,
                            icon: const Icon(Icons.add_photo_alternate_rounded,
                                size: 20),
                            label: const Text('Create Another',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withOpacity(0.15),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                          if (widget.artworkId != null)
                          _VideoGenButton(artworkId: widget.artworkId!),
                        const SizedBox(width: 12),
                         if (widget.artworkId != null)
                          AudioGenButton(
                            artworkId: widget.artworkId!,
                            onStarted: () => setState(() => _isGeneratingAudio = true),
                            onComplete: (url) => setState(() {
                              _isGeneratingAudio = false;
                              _audioUrl = url;
                            }),
                            onError: () => setState(() => _isGeneratingAudio = false),
                          ),
                        const SizedBox(width: 12),
                        // NEW: Critique & Storytelling Buttons
                        if (widget.artworkId != null) ...[
                          _FeatureButton(
                            icon: Icons.psychology_outlined,
                            onTap: _fetchCritique,
                            isLoading: _isAnalyzing,
                            color: Colors.amber.withOpacity(0.2),
                          ),
                          const SizedBox(width: 12),
                          _FeatureButton(
                            icon: Icons.history_edu_outlined,
                            onTap: _fetchScenarios,
                            isLoading: _isGeneratingScenarios,
                            color: Colors.blueAccent.withOpacity(0.2),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryPurple.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              splashColor: Colors.white.withOpacity(0.2),
                              onTap: _isSaving ? null : _saveImage,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 18),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Icon(Icons.download_rounded,
                                        color: Colors.white),
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
          if (_isGeneratingAudio)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      'Composition de votre univers sonore...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ceci peut prendre une minute.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_audioUrl != null)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: SimpleAudioPlayer(url: _audioUrl!),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.2, end: 0.7),
          duration: Duration(milliseconds: 700 + i * 200),
          curve: Curves.easeInOut,
          builder: (_, v, __) => Opacity(
            opacity: v,
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Icon(Icons.image_outlined,
                    size: 28, color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Center(
      child: Text(
        'Generate more art to discover similar creations',
        style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSimilarStrip() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: _similarArtworks.length,
      itemBuilder: (context, index) {
        final art = _similarArtworks[index];
        final imgProv = _imageProviderFor(art);
        return Padding(
          padding: EdgeInsets.only(
              right: index < _similarArtworks.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => _SimilarArtworkSheet(artwork: art),
              );
            },
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imgProv != null)
                    Image(image: imgProv, fit: BoxFit.cover)
                  else
                    Container(color: Colors.white10),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: const Alignment(0, -0.2),
                          colors: [
                            Colors.black.withOpacity(0.75),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 10, color: Colors.white70),
                    ),
                  ),
                  if (art.title != null)
                    Positioned(
                      bottom: 7,
                      left: 7,
                      right: 7,
                      child: Text(
                        art.title!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VideoGenButton extends StatefulWidget {
  const _VideoGenButton({required this.artworkId});
  final String artworkId;

  @override
  State<_VideoGenButton> createState() => _VideoGenButtonState();
}

class _VideoGenButtonState extends State<_VideoGenButton> {
  bool _loading = false;

  Future<void> _generateVideo() async {
    setState(() => _loading = true);
    try {
      final videoUrl = await VisionCraftService().generateVideo(widget.artworkId);
      if (videoUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✨ Video Generated! Playing now...'),
            backgroundColor: AppColors.primaryBlue,
            action: SnackBarAction(label: 'Open', onPressed: () => launchUrl(Uri.parse(videoUrl))),
          ),
        );
        await launchUrl(Uri.parse(videoUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Video error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _loading ? null : _generateVideo,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _SimilarArtworkSheet extends StatelessWidget {
  const _SimilarArtworkSheet({required this.artwork});
  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    ImageProvider? imgProv;
    if (artwork.imageUrl.startsWith('data:image')) {
      imgProv = MemoryImage(base64Decode(artwork.imageUrl.split(',').last));
    } else if (artwork.imageUrl.startsWith('http')) {
      imgProv = NetworkImage(artwork.imageUrl);
    }

    return Container(
      height: screenH * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: imgProv != null
                        ? Image(image: imgProv, fit: BoxFit.cover, width: double.infinity)
                        : Container(height: 300, color: Colors.white10),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artwork.title ?? 'Untitled Masterpiece',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _formatDate(artwork.createdAt),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (artwork.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      artwork.description!,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.6),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.icon,
    required this.onTap,
    required this.isLoading,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
