import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../../../core/ai_service.dart';

class StyleTransferSheet extends StatefulWidget {
  const StyleTransferSheet({super.key});

  @override
  State<StyleTransferSheet> createState() => _StyleTransferSheetState();
}

class _StyleTransferSheetState extends State<StyleTransferSheet> {
  final _aiService = AiService();
  
  XFile? _selectedXFile;
  String? _resultBase64;
  bool _isLoading = false;
  String? _error;
  String? _selectedStylePrompt;

  final List<Map<String, String>> _predefinedStyles = [
    {'name': 'Manga', 'prompt': 'Japanese anime style, Studio Ghibli, detailed eyes, cel shading', 'emoji': '✨', 'color': '0xFFEC4899'},
    {'name': 'Cyberpunk', 'prompt': 'Cyberpunk aesthetic, neon futuristic city, high tech', 'emoji': '🏙️', 'color': '0xFF7C3AED'},
    {'name': 'Aquarelle', 'prompt': 'Soft watercolor painting, artistic flowing colors, wet paper', 'emoji': '🎨', 'color': '0xFF3B82F6'},
    {'name': 'Pixel Art', 'prompt': 'Retro 16-bit pixel art, video game style, carefully placed pixels', 'emoji': '👾', 'color': '0xFF10B981'},
    {'name': 'Ghibli', 'prompt': 'Studio Ghibli scenery style, lush greenery, soft lighting, anime', 'emoji': '🌳', 'color': '0xFF22D3EE'},
    {'name': 'Van Gogh', 'prompt': 'Impressionist oil painting, Vincent Van Gogh style, thick swirling brushstrokes', 'emoji': '🖼️', 'color': '0xFFF59E0B'},
    {'name': 'GTA V', 'prompt': 'Grand Theft Auto V loading screen art style, digital vector illustration', 'emoji': '🔫', 'color': '0xFFFFB800'},
    {'name': 'Disney', 'prompt': 'Disney Pixar 3D animation style, big expressive eyes, high quality render', 'emoji': '🏰', 'color': '0xFFA78BFA'},
    {'name': 'Sketch', 'prompt': 'Hand-drawn pencil sketch, graphite shading, artistic charcoal', 'emoji': '✏️', 'color': '0xFF64748B'},
    {'name': 'Oil Painting', 'prompt': 'Classical museum quality oil painting, rich colors, fine details', 'emoji': '🎭', 'color': '0xFF991B1B'},
    {'name': 'Steampunk', 'prompt': 'Steampunk Victorian aesthetic, brass, bronze, gears, machinery', 'emoji': '⚙️', 'color': '0xFFB45309'},
    {'name': 'Neon Future', 'prompt': 'Ultra-vibrant neon colors, glowing edges, hyper-futuristic', 'emoji': '🌈', 'color': '0xFFD946EF'},
    {'name': 'Ukiyo-e', 'prompt': 'Traditional Japanese woodblock print, bold outlines, ukiyo-e style', 'emoji': '🌊', 'color': '0xFF1E3A82'},
    {'name': 'Fantasy', 'prompt': 'Epic fantasy concept art, magic ethereal glow, high detail', 'emoji': '🐉', 'color': '0xFF8B5CF6'},
    {'name': 'Vintage', 'prompt': '1970s vintage film photograph, Kodak Portra, light leaks, grainy', 'emoji': '📸', 'color': '0xFF78350F'},
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source, 
        imageQuality: 90,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _selectedXFile = pickedFile;
          _resultBase64 = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _applyStyle() async {
    if (_selectedXFile == null || _selectedStylePrompt == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _resultBase64 = null;
    });

    HapticFeedback.lightImpact();

    try {
      final bytes = await _selectedXFile!.readAsBytes();
      final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
      
      final result = await _aiService.styleTransfer(base64Image, _selectedStylePrompt!);
      
      if (mounted) {
        HapticFeedback.vibrate();
        setState(() => _resultBase64 = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "Échec : $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: context.surfaceColor.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: AppColors.shadowLarge(Colors.black),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _buildImagePreview(),
                      const SizedBox(height: 24),
                      if (_resultBase64 == null) _buildStyleSelector(),
                      if (_error != null) _buildError(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.textSecondaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 16, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowMedium(AppColors.primaryPurple.withOpacity(0.5)),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style Transformer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '✨ Modèles Créatifs IA',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.lightBlue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, size: 22, color: context.textPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: _resultBase64 != null
          ? _buildResultCard()
          : _selectedXFile != null
              ? _buildPickedCard()
              : _buildUploadPlaceholder(),
    );
  }

  Widget _buildResultCard() {
    final bytes = base64Decode(_resultBase64!.split(',').last);
    return Column(
      key: const ValueKey('result'),
      children: [
        Stack(
          children: [
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.shadowLarge(AppColors.primaryPurple.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _buildResultBadge(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => setState(() {
            _resultBase64 = null;
            _selectedXFile = null;
            _selectedStylePrompt = null;
          }),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Recommencer'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
        ),
      ],
    );
  }

  Widget _buildResultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 14),
          SizedBox(width: 4),
          Text('IA GÉNÉRÉE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPickedCard() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Stack(
        key: const ValueKey('picked'),
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.file(File(_selectedXFile!.path), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return InkWell(
      onTap: () => _pickImage(ImageSource.gallery),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 220,
        key: const ValueKey('placeholder'),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.25), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.2),
                    AppColors.primaryBlue.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.4), width: 1),
              ),
              child: const Icon(Icons.add_photo_alternate_rounded, size: 36, color: AppColors.lightBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'Choisir une photo',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.surfaceColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                'JPG, PNG • Max 10MB',
                style: TextStyle(color: context.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_outlined, size: 18, color: AppColors.lightBlue),
                const SizedBox(width: 8),
                Text(
                  'SÉLECTION DE STYLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: context.textSecondaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_predefinedStyles.length} OPTIONS',
                style: const TextStyle(fontSize: 11, color: AppColors.lightBlue, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.88,
          ),
          itemCount: _predefinedStyles.length,
          itemBuilder: (context, index) {
            final style = _predefinedStyles[index];
            final isSelected = _selectedStylePrompt == style['prompt'];
            final color = Color(int.parse(style['color']!));

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedStylePrompt = style['prompt']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : context.cardBackgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? color : Colors.white.withOpacity(0.05),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                          BoxShadow(color: color.withOpacity(0.1), blurRadius: 5, spreadRadius: 1),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(Icons.check_circle, color: color, size: 16),
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isSelected ? 6 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : null,
                          ),
                          child: Text(style['emoji']!, style: TextStyle(fontSize: isSelected ? 32 : 28)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          style['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? Colors.white : context.textPrimaryColor.withOpacity(0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    if (_resultBase64 != null) return const SizedBox.shrink();

    final isReady = _selectedXFile != null && _selectedStylePrompt != null && !_isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: isReady
              ? [
                  BoxShadow(color: AppColors.primaryPurple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                  BoxShadow(color: AppColors.lightBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: isReady ? _applyStyle : null,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: isReady
                    ? const LinearGradient(
                        colors: [AppColors.primaryPurple, AppColors.lightBlue],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isReady ? null : context.cardBackgroundColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: isReady ? null : Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: isReady ? Colors.white : context.textSecondaryColor.withOpacity(0.5),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Générer l\'Art IA',
                            style: TextStyle(
                              color: isReady ? Colors.white : context.textSecondaryColor.withOpacity(0.5),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
