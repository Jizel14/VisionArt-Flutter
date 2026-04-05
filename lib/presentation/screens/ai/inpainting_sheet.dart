import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../../../core/ai_service.dart';

class InpaintingSheet extends StatefulWidget {
  const InpaintingSheet({super.key});

  @override
  State<InpaintingSheet> createState() => _InpaintingSheetState();
}

class _InpaintingSheetState extends State<InpaintingSheet> {
  final _aiService = AiService();
  final _promptController = TextEditingController();
  
  File? _selectedImage;
  String? _resultBase64;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source, 
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _resultBase64 = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de galerie : $e')),
        );
      }
    }
  }

  Future<void> _applyEdit() async {
    if (_selectedImage == null) return;
    
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = "Veuillez préciser la modification souhaitée.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _resultBase64 = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
      
      // On passe la même image comme masque temporairement
      final result = await _aiService.inpaint(base64Image, base64Image, prompt);
      
      if (mounted) {
        setState(() => _resultBase64 = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "Impossible de générer les modifications (l'API de modification est saturée).");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Uint8List? _decodeBase64(String base64String) {
    try {
      final clean = base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
      return base64Decode(clean);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: context.surfaceColor.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: context.textSecondaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Row(
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
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(Icons.auto_fix_high, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Édition Intelligente',
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
                        icon: Icon(Icons.close_rounded, size: 22, color: context.textPrimaryColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_resultBase64 != null) ...[
                    Text('Résultat :', style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _decodeBase64(_resultBase64!)!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_resultBase64 == null) ...[
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: _selectedImage == null ? AppColors.bgDark.withOpacity(0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _selectedImage == null ? AppColors.primaryPurple.withOpacity(0.25) : Colors.transparent, 
                            width: 2
                          ),
                          boxShadow: _selectedImage == null ? [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ] : null,
                        ),
                        child: _selectedImage == null
                            ? Column(
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
                                    'Choisir une image de base',
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 16,
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
                                      'Format idéal: JPG / PNG',
                                      style: TextStyle(color: context.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5), width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryPurple.withOpacity(0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          )
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(26),
                                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                    ),
                                  )
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _promptController,
                      decoration: InputDecoration(
                        hintText: "Ex: 'Ajouter un coucher de soleil'",
                        hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5)),
                        filled: true,
                        fillColor: context.cardBackgroundColor.withOpacity(0.5),
                        contentPadding: const EdgeInsets.all(20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.primaryPurple.withOpacity(0.5), width: 1.5),
                        ),
                      ),
                      style: TextStyle(color: context.textPrimaryColor),
                      maxLines: 2,
                      minLines: 1,
                    ),
                    const SizedBox(height: 24),
                    
                    if (_error != null)
                       Container(
                         margin: const EdgeInsets.only(bottom: 16),
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
                       ),
                       
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: (_isLoading || _selectedImage == null)
                            ? null
                            : [
                                BoxShadow(color: AppColors.primaryPurple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                                BoxShadow(color: AppColors.lightBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: _isLoading || _selectedImage == null || _promptController.text.trim().isEmpty ? null : _applyEdit,
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: (_isLoading || _selectedImage == null || _promptController.text.trim().isEmpty)
                                  ? null
                                  : const LinearGradient(
                                      colors: [AppColors.primaryPurple, AppColors.lightBlue],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                              color: (_isLoading || _selectedImage == null || _promptController.text.trim().isEmpty)
                                  ? context.cardBackgroundColor.withOpacity(0.5)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              border: (_isLoading || _selectedImage == null || _promptController.text.trim().isEmpty)
                                  ? Border.all(color: Colors.white.withOpacity(0.05))
                                  : null,
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: (_selectedImage == null || _promptController.text.trim().isEmpty) ? context.textSecondaryColor.withOpacity(0.5) : Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Générer l\'édition',
                                          style: TextStyle(
                                            color: (_selectedImage == null || _promptController.text.trim().isEmpty) ? context.textSecondaryColor.withOpacity(0.5) : Colors.white,
                                            fontSize: 17,
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
                  ],
                  if (_resultBase64 != null)
                     TextButton(
                        onPressed: () {
                          setState(() {
                            _resultBase64 = null;
                            _selectedImage = null;
                            _promptController.clear();
                          });
                        },
                        child: Text('Recommencer avec une nouvelle image', style: TextStyle(color: context.textSecondaryColor)),
                     ),
                ],
              ),
            ),
          ),
        ],
      ),
     ),
    ),
   ),
  );
 }
}
