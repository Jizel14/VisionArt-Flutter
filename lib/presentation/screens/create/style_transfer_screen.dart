import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/artwork_model.dart';
import '../../../core/services/artwork_service.dart';
import '../../theme/app_colors.dart';
import '../splash/widgets/smoke_background.dart';

class StyleTransferScreen extends StatefulWidget {
  const StyleTransferScreen({super.key});

  @override
  State<StyleTransferScreen> createState() => _StyleTransferScreenState();
}

class _StyleTransferScreenState extends State<StyleTransferScreen> {
  static const List<String> _artists = [
    'Van Gogh',
    'Picasso',
    'Monet',
    'Dali',
    'Da Vinci',
    'Frida Kahlo',
    'Rembrandt',
  ];

  final _artworkService = ArtworkService();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String _artist = _artists.first;
  bool _loading = false;
  String? _error;
  ArtworkModel? _result;

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _error = null;
      _result = null;
    });
  }

  Future<void> _runTransfer() async {
    final bytes = _imageBytes;
    if (bytes == null) {
      setState(() => _error = 'Choisis une image d abord.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final created = await _artworkService.styleTransfer(
        imageBytes: bytes,
        artist: _artist,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = created;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Style transfer termine.')),
      );
    } catch (e) {
      if (!mounted) return;
      final errorText = e.toString();
      final isPayloadTooLarge =
          errorText.contains('status code of 413') || errorText.contains('413');
      setState(() {
        _loading = false;
        _error = isPayloadTooLarge
            ? 'Image trop lourde. Choisis une image plus legere.'
            : errorText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SmokeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Style Transfer',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(_imageBytes == null ? 'Choisir une image' : 'Changer image'),
                ),
                const SizedBox(height: 12),
                if (_imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _artist,
                  decoration: const InputDecoration(
                    labelText: 'Artiste',
                    filled: true,
                  ),
                  items: _artists
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _artist = value);
                        },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _runTransfer,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_loading ? 'Generation...' : 'Generer le style transfer'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                if (_result?.imageUrl != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Resultat',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(_result!.imageUrl, fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
