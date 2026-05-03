import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/visioncraft_service.dart';
import '../../theme/app_colors.dart';
import 'create_art_screen.dart'; // To reuse _ResultView if possible, or create a similar one.

class StyleTransferScreen extends StatefulWidget {
  const StyleTransferScreen({super.key});

  @override
  State<StyleTransferScreen> createState() => _StyleTransferScreenState();
}

class _StyleTransferScreenState extends State<StyleTransferScreen> {
  File? _selectedImage;
  String? _selectedArtist;
  bool _isProcessing = false;
  Uint8List? _resultBytes;
  String? _artworkId;
  String? _error;

  final List<Map<String, String>> _artists = [
    {'name': 'Van Gogh', 'style': 'Post-Impressionism', 'image': '🌻'},
    {'name': 'Pablo Picasso', 'style': 'Cubism', 'image': '🎨'},
    {'name': 'Claude Monet', 'style': 'Impressionism', 'image': '🌊'},
    {'name': 'Salvador Dalí', 'style': 'Surrealism', 'image': '🕰️'},
    {'name': 'Leonardo da Vinci', 'style': 'Renaissance', 'image': '📜'},
    {'name': 'Frida Kahlo', 'style': 'Surrealism/Portrait', 'image': '🌺'},
    {'name': 'Rembrandt', 'style': 'Baroque', 'image': '🕯️'},
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _resultBytes = null;
        _error = null;
      });
    }
  }

  Future<void> _applyTransfer() async {
    if (_selectedImage == null || _selectedArtist == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await VisionCraftService().applyStyleTransfer(
        imageB64: base64Image,
        artistName: _selectedArtist!,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (result != null) {
            _resultBytes = result['imageBytes'];
            _artworkId = result['artworkId'];
          } else {
            _error = "Failed to process image. Please try again.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resultBytes != null) {
      // Reusing the result view from create_art_screen is tricky due to privacy, 
      // but I can navigate to a similar result display.
      // For now, let's show it here or create a dedicated Result view.
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Artistic Masterpiece', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _resultBytes = null),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(_resultBytes!, fit: BoxFit.contain),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _resultBytes = null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Try Another Artist', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Style Artist Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: const Text(
                'Transform your photo into a masterpiece',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: const Text(
                'Select a photo and choose an artist style',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            
            // Image Picker Section
            GestureDetector(
              onTap: _pickImage,
              child: FadeInScale(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 48, color: AppColors.primaryPurple),
                            const SizedBox(height: 12),
                            const Text('Select from Gallery', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Choose an Artist Style', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Artist Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _artists.length,
              itemBuilder: (context, index) {
                final artist = _artists[index];
                final isSelected = _selectedArtist == artist['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedArtist = artist['name']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryPurple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryPurple : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(artist['image']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 8),
                        Text(
                          artist['name']!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          artist['style']!,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_selectedImage == null || _selectedArtist == null || _isProcessing)
                    ? null
                    : _applyTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Apply Style Transfer',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class FadeInScale extends StatelessWidget {
  const FadeInScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      child: ZoomIn(
        child: child,
      ),
    );
  }
}
