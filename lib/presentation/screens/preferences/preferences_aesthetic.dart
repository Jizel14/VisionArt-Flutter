import 'package:flutter/material.dart';
import '../../../core/preferences_service.dart';
import '../../../core/models/user_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

/// Aesthetic preferences: styles, colors, mood, complexity
class PreferencesAesthetic extends StatefulWidget {
  const PreferencesAesthetic({
    super.key,
    required this.preferences,
    required this.preferencesService,
    required this.onUpdated,
  });

  final UserPreferences preferences;
  final PreferencesService preferencesService;
  final Function(UserPreferences) onUpdated;

  @override
  State<PreferencesAesthetic> createState() => _PreferencesAestheticState();
}

class _PreferencesAestheticState extends State<PreferencesAesthetic> {
  late List<String> _selectedStyles;
  late List<String> _selectedColors;
  late String? _selectedMood;
  late String _selectedComplexity;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _selectedStyles = List.from(widget.preferences.favoriteStyles);
    _selectedColors = List.from(widget.preferences.favoriteColors);
    _selectedMood = widget.preferences.preferredMood;
    _selectedComplexity = widget.preferences.artComplexity;
  }

  Future<void> _updateStyles() async {
    setState(() => _updating = true);
    try {
      final updated = await widget.preferencesService.updateStyles(
        favoriteStyles: _selectedStyles,
        favoriteColors: _selectedColors,
        preferredMood: _selectedMood,
        artComplexity: _selectedComplexity,
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

  void _toggleStyle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  void _toggleColor(String color) {
    setState(() {
      if (_selectedColors.contains(color)) {
        _selectedColors.remove(color);
      } else {
        _selectedColors.add(color);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Favorite Styles
          _buildSectionTitle('🎨 Favorite Art Styles'),
          _buildChipGrid(
            options: StyleOptions.availableStyles,
            selected: _selectedStyles,
            onToggle: _toggleStyle,
          ),
          const SizedBox(height: 24),

          // Favorite Colors
          _buildSectionTitle('🎯 Favorite Colors'),
          _buildChipGrid(
            options: StyleOptions.availableColors,
            selected: _selectedColors,
            onToggle: _toggleColor,
          ),
          const SizedBox(height: 24),

          // Preferred Mood
          _buildSectionTitle('💭 Preferred Mood'),
          _buildDropdown(
            value: _selectedMood,
            options: StyleOptions.availableMoods,
            onChanged: (val) => setState(() => _selectedMood = val),
            hintText: 'Select mood (optional)',
          ),
          const SizedBox(height: 24),

          // Art Complexity
          _buildSectionTitle('📊 Art Complexity Level'),
          _buildRadioGroup(
            value: _selectedComplexity,
            options: StyleOptions.complexityLevels,
            onChanged: (val) => setState(() => _selectedComplexity = val),
            labels: {
              'minimal': 'Minimal - Simple & Clean',
              'moderate': 'Moderate - Balanced',
              'detailed': 'Detailed - Complex & Rich',
            },
          ),
          const SizedBox(height: 32),

          // Update Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _updating ? null : _updateStyles,
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
                  : const Text('Save Aesthetic Preferences'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildChipGrid({
    required List<String> options,
    required List<String> selected,
    required Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onToggle(option),
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.primaryPurple.withOpacity(0.3),
          side: BorderSide(
            color: isSelected ? AppColors.primaryPurple : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
          labelStyle: TextStyle(
            color: isSelected
                ? AppColors.primaryPurple
                : context.textPrimaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(
          hintText,
          style: TextStyle(color: context.textSecondaryColor),
        ),
        items: [
          ...options.map(
            (option) => DropdownMenuItem(value: option, child: Text(option)),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioGroup({
    required String value,
    required List<String> options,
    required Function(String) onChanged,
    required Map<String, String> labels,
  }) {
    return Column(
      children: options.map((option) {
        return RadioListTile(
          value: option,
          groupValue: value,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          title: Text(labels[option] ?? option),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 4,
          ),
        );
      }).toList(),
    );
  }
}
