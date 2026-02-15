import 'package:flutter/material.dart';
import '../../../core/preferences_service.dart';
import '../../../core/models/user_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

/// Privacy preferences: data retention, training, public sharing
class PreferencesPrivacy extends StatefulWidget {
  const PreferencesPrivacy({
    super.key,
    required this.preferences,
    required this.preferencesService,
    required this.onUpdated,
  });

  final UserPreferences preferences;
  final PreferencesService preferencesService;
  final Function(UserPreferences) onUpdated;

  @override
  State<PreferencesPrivacy> createState() => _PreferencesPrivacyState();
}

class _PreferencesPrivacyState extends State<PreferencesPrivacy> {
  late int? _dataRetentionPeriod;
  late bool _allowDataForTraining;
  late bool _shareGenerationsPublicly;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _dataRetentionPeriod = widget.preferences.dataRetentionPeriod;
    _allowDataForTraining = widget.preferences.allowDataForTraining;
    _shareGenerationsPublicly = widget.preferences.shareGenerationsPublicly;
  }

  Future<void> _updatePrivacyPreferences() async {
    setState(() => _updating = true);
    try {
      final updated = await widget.preferencesService.updatePrivacyPreferences(
        dataRetentionPeriod: _dataRetentionPeriod,
        allowDataForTraining: _allowDataForTraining,
        shareGenerationsPublicly: _shareGenerationsPublicly,
      );
      widget.onUpdated(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data Retention
          _buildSectionTitle('📦 Data Retention Policy'),
          Text(
            'How long to keep your generated images',
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          _buildRetentionOptions(),
          const SizedBox(height: 24),

          // Training Data
          _buildSectionTitle('🤖 AI Training Data'),
          _buildPrivacyToggle(
            title: 'Allow AI Training',
            description:
                'Help us improve generation quality by using your data',
            value: _allowDataForTraining,
            onChanged: (val) => setState(() => _allowDataForTraining = val),
            icon: '🤖',
            warningText:
                'Your images may be used to train our models (anonymized)',
          ),
          const SizedBox(height: 24),

          // Public Sharing
          _buildSectionTitle('🌐 Public Sharing'),
          _buildPrivacyToggle(
            title: 'Share Generations Publicly',
            description: 'Share your artworks in the community gallery',
            value: _shareGenerationsPublicly,
            onChanged: (val) => setState(() => _shareGenerationsPublicly = val),
            icon: '🌐',
          ),
          const SizedBox(height: 32),

          // Legal Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚖️ GDPR Compliance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We respect your privacy and comply with GDPR. You have the right to access, modify, or delete your data at any time.',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _updating ? null : _updatePrivacyPreferences,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                disabledBackgroundColor: Colors.grey,
              ),
              child: _updating
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Privacy Preferences'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildRetentionOptions() {
    final options = [
      (label: '30 Days', value: 30),
      (label: '90 Days', value: 90),
      (label: '6 Months', value: 180),
      (label: '1 Year', value: 365),
      (label: 'Indefinite', value: null),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = _dataRetentionPeriod == option.value;
        return ChoiceChip(
          label: Text(option.label),
          selected: isSelected,
          onSelected: (_) =>
              setState(() => _dataRetentionPeriod = option.value),
          selectedColor: AppColors.primaryPurple.withOpacity(0.3),
          side: BorderSide(
            color: isSelected ? AppColors.primaryPurple : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivacyToggle({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required String icon,
    String? warningText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryPurple,
              ),
            ],
          ),
          if (warningText != null) ...[
            const SizedBox(height: 12),
            Text(
              warningText,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
