import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../../../core/ai_service.dart';

class PromptEnhancerSheet extends StatefulWidget {
  const PromptEnhancerSheet({super.key});

  @override
  State<PromptEnhancerSheet> createState() => _PromptEnhancerSheetState();
}

class _PromptEnhancerSheetState extends State<PromptEnhancerSheet> {
  final _inputController = TextEditingController();
  final _aiService = AiService();
  bool _isLoading = false;
  String? _enhancedPrompt;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _enhance() async {
    if (_inputController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _enhancedPrompt = null;
    });

    try {
      final result = await _aiService.enhancePrompt(_inputController.text.trim());
      if (mounted) {
        setState(() {
          _enhancedPrompt = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Une erreur s'est produite lors de l'amélioration du prompt.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyToClipboard() {
    if (_enhancedPrompt != null) {
      Clipboard.setData(ClipboardData(text: _enhancedPrompt!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Prompt copié dans le presse-papier !"),
          backgroundColor: AppColors.primaryPurple,
        ),
      );
      Navigator.pop(context, _enhancedPrompt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: context.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assistant de Prompt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Obtenez un prompt riche pour Stable Diffusion',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _inputController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Exemple: 'un chat dans l'espace'",
              hintStyle: TextStyle(color: context.textSecondaryColor.withOpacity(0.5)),
              filled: true,
              fillColor: context.cardBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
              ),
            ),
            style: TextStyle(color: context.textPrimaryColor),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          if (_enhancedPrompt != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
              ),
              child: SelectableText(
                _enhancedPrompt!,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : (_enhancedPrompt == null ? _enhance : _copyToClipboard),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_enhancedPrompt == null ? Icons.auto_awesome : Icons.copy),
              label: Text(_enhancedPrompt == null ? 'Améliorer le prompt' : 'Copier et utiliser'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_enhancedPrompt != null)
            TextButton(
              onPressed: _enhance,
              child: Text(
                'Générer une autre variante',
                style: TextStyle(color: context.textSecondaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
