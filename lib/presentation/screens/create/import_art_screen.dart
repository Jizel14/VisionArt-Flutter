import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/critic_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

class ImportArtScreen extends StatefulWidget {
  const ImportArtScreen({super.key});

  @override
  State<ImportArtScreen> createState() => _ImportArtScreenState();
}

class _ImportArtScreenState extends State<ImportArtScreen> {
  late final CriticService _criticService;

  Uint8List? _importedImage;
  bool _analyzing = false;
  bool _generatingCaption = false;
  Map<String, dynamic>? _generatedCaptionMap;
  String? _error;

  @override
  void initState() {
    super.initState();
    _criticService = CriticService();
  }

  Future<void> _importImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) {
          setState(() {
            _error = null;
            _importedImage = bytes;
            _generatedCaptionMap = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to import image: $e';
        });
      }
    }
  }

  Future<void> _analyzeArt() async {
    if (_importedImage == null) return;

    setState(() => _analyzing = true);
    try {
      final feedback = await _criticService.analyzeArt(
        imageBytes: _importedImage,
        prompt: 'An imported image',
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

  Future<void> _generateCaption() async {
    if (_importedImage == null) return;

    setState(() {
      _generatingCaption = true;
      _error = null;
    });

    try {
      final captionData = await _criticService.generateCaption(
        prompt: 'An imported image',
      );
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

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Art'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SmokeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_importedImage == null) ...[
                  const SizedBox(height: 48),
                  Icon(
                    Icons.image_search_rounded,
                    size: 80,
                    color: textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Import an image from your device to analyze it with our AI Critic and Autocaption.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _importImage,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text(
                        'Choose Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_importedImage!, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _importImage,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Choose another image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _analyzing ? null : _analyzeArt,
                            icon: _analyzing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.psychology_alt,
                                    color: AppColors.primaryBlue,
                                  ),
                            label: Text(
                              _analyzing ? 'Analyzing…' : 'AI Critic',
                              style: TextStyle(color: textPrimary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.primaryBlue.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
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
                              _generatingCaption ? 'Writing…' : 'Autocaption',
                              style: TextStyle(color: textPrimary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.accentPink.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
      ),
    );
  }
}
