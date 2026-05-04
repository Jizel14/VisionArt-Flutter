import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/video_player_widget.dart';

import '../../../core/models/artwork_model.dart';
import '../../../core/visioncraft_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

class GenerateVideoScreen extends StatefulWidget {
  final ArtworkModel artwork;
  final ValueChanged<String>? onVideoGenerated;

  const GenerateVideoScreen({
    Key? key, 
    required this.artwork,
    this.onVideoGenerated,
  }) : super(key: key);

  @override
  State<GenerateVideoScreen> createState() => _GenerateVideoScreenState();
}

class _GenerateVideoScreenState extends State<GenerateVideoScreen> {
  final _visionCraft = VisionCraftService();
  final _promptController = TextEditingController();
  bool _isGenerating = false;
  
  // Progress Simulation
  double _progress = 0.0;
  String _statusMessage = 'Initializing...';
  Timer? _progressTimer;

  final List<String> _statusMessages = [
    'Initializing AI Model...',
    'Analyzing artwork details...',
    'Dreaming up motion vectors...',
    'Generating cinematic frames...',
    'Refining textures & lighting...',
    'Almost there, finalizing video...',
    'Optimizing for playback...',
  ];

  @override
  void initState() {
    super.initState();
    _promptController.text = widget.artwork.description ?? '';
  }

  @override
  void dispose() {
    _promptController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressSimulation() {
    setState(() {
      _progress = 0.0;
      _statusMessage = _statusMessages[0];
    });

    // Simulated progress: 0 to 95% over ~90 seconds
    const duration = Duration(seconds: 90);
    const interval = Duration(milliseconds: 100);
    final totalSteps = duration.inMilliseconds / interval.inMilliseconds;
    final increment = 0.95 / totalSteps;

    _progressTimer = Timer.periodic(interval, (timer) {
      if (mounted && _isGenerating) {
        setState(() {
          if (_progress < 0.95) {
            _progress += increment;
            
            // Update status message based on progress
            int msgIndex = ((_progress / 0.95) * (_statusMessages.length - 1)).floor();
            _statusMessage = _statusMessages[msgIndex];
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _generateVideo() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });
    _startProgressSimulation();

    try {
      final videoUrl = await _visionCraft.generateVideo(
        widget.artwork.id,
        prompt: _promptController.text.trim(),
      );

      if (mounted) {
        if (videoUrl != null) {
          setState(() {
            _progress = 1.0;
            _statusMessage = 'Generation Complete!';
            _generatedVideoUrl = videoUrl;
          });
          
          widget.onVideoGenerated?.call(videoUrl);
          
          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎬 Video generated successfully!'),
              backgroundColor: AppColors.primaryBlue,
            ),
          );
        } else {
          throw Exception('Video URL was null');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Video generation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted && _generatedVideoUrl == null) {
        setState(() {
          _isGenerating = false;
        });
        _progressTimer?.cancel();
      }
    }
  }

  // Add this field to state
  String? _generatedVideoUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageProvider = _imageProviderFor(widget.artwork);

    // If video is generated, show the player view
    if (_generatedVideoUrl != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Generated Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Stack(
          children: [
            Center(
              child: VideoPlayerWidget(videoUrl: _generatedVideoUrl!),
            ),
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: FadeInUp(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Back to Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppThemeColors.surfaceColor(context),
      appBar: AppBar(
        title: const Text('Generate Video', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInDown(
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppThemeColors.borderColor(context).withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageProvider != null
                        ? Image(image: imageProvider, fit: BoxFit.cover)
                        : Container(color: AppColors.border),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Video Generation Prompt',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.textPrimaryColor(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: TextField(
                    controller: _promptController,
                    maxLines: 4,
                    style: TextStyle(color: AppThemeColors.textPrimaryColor(context)),
                    decoration: InputDecoration(
                      hintText: 'Describe how the video should animate...',
                      hintStyle: TextStyle(color: AppThemeColors.textSecondaryColor(context).withOpacity(0.5)),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded),
                          SizedBox(width: 12),
                          Text(
                            'Dream Video with Wan2.1', 
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Premium Generation Overlay
          if (_isGenerating)
            FadeIn(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  width: double.infinity,
                  height: double.infinity,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Preview Window
                          Pulse(
                            infinite: true,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryPurple, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryPurple.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: imageProvider != null
                                  ? Image(image: imageProvider, fit: BoxFit.cover)
                                  : const Icon(Icons.movie_rounded, color: Colors.white, size: 60),
                            ),
                          ),
                          const SizedBox(height: 60),
                          
                          // Progress Text
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeIn(
                            key: ValueKey(_statusMessage),
                            child: Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Modern Glassmorphic Progress Bar
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: MediaQuery.of(context).size.width * 0.8 * _progress,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primaryPurple, AppColors.primaryBlue],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPurple.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Interactive Tip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'AI video generation takes about 1-2 minutes',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider? _imageProviderFor(ArtworkModel artwork) {
    if (artwork.imageUrl.startsWith('data:image')) {
      final b64 = artwork.imageUrl.split(',').last;
      return MemoryImage(base64Decode(b64));
    } else if (artwork.imageUrl.startsWith('http')) {
      return NetworkImage(artwork.imageUrl);
    }
    return null;
  }
}


