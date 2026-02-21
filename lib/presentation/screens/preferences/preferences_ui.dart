import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/preferences_service.dart';
import '../../../core/models/user_preferences.dart';
import '../../../main.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

/// UI/UX preferences: language, theme, notifications
class PreferencesUI extends StatefulWidget {
  const PreferencesUI({
    super.key,
    required this.preferences,
    required this.preferencesService,
    required this.onUpdated,
    this.onThemeChanged,
  });

  final UserPreferences preferences;
  final PreferencesService preferencesService;
  final Function(UserPreferences) onUpdated;
  final Function(String)? onThemeChanged;

  @override
  State<PreferencesUI> createState() => _PreferencesUIState();
}

class _PreferencesUIState extends State<PreferencesUI> {
  late String _preferredLanguage;
  late String _theme;
  late bool _notificationsEnabled;
  late bool _emailNotificationsEnabled;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _preferredLanguage = widget.preferences.preferredLanguage;
    _theme = widget.preferences.theme;
    _notificationsEnabled = widget.preferences.notificationsEnabled;
    _emailNotificationsEnabled = widget.preferences.emailNotificationsEnabled;
  }

  Future<void> _updateUIPreferences() async {
    setState(() => _updating = true);
    try {
      final updated = await widget.preferencesService.updateUIPreferences(
        preferredLanguage: _preferredLanguage,
        theme: _theme,
        notificationsEnabled: _notificationsEnabled,
        emailNotificationsEnabled: _emailNotificationsEnabled,
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
          // Language Settings
          _buildSectionTitle('🌍 Language'),
          _buildLanguageSelector(),
          const SizedBox(height: 24),

          // Theme Settings
          _buildSectionTitle('🎨 Theme'),
          _buildThemeSelector(),
          const SizedBox(height: 24),

          // Notifications
          _buildSectionTitle('🔔 Notifications'),
          _buildNotificationToggle(
            title: 'Push Notifications',
            description: 'Receive in-app notifications',
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            icon: '📱',
          ),
          const SizedBox(height: 16),
          _buildNotificationToggle(
            title: 'Email Notifications',
            description: 'Receive email updates and news',
            value: _emailNotificationsEnabled,
            onChanged: (val) =>
                setState(() => _emailNotificationsEnabled = val),
            icon: '📧',
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _updating ? null : _updateUIPreferences,
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
                  : const Text('Save UI/UX Preferences'),
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

  Widget _buildLanguageSelector() {
    final languages = [
      (code: 'fr', name: 'Français', flag: '🇫🇷'),
      (code: 'en', name: 'English', flag: '🇺🇸'),
      (code: 'ar', name: 'العربية', flag: '🇸🇦'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages.map((lang) {
        final isSelected = _preferredLanguage == lang.code;
        return ChoiceChip(
          label: Text('${lang.flag} ${lang.name}'),
          selected: isSelected,
          onSelected: (_) => setState(() => _preferredLanguage = lang.code),
          selectedColor: AppColors.primaryPurple.withOpacity(0.3),
          side: BorderSide(
            color: isSelected ? AppColors.primaryPurple : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeSelector() {
    final themes = [
      (mode: 'light', name: 'Light', icon: Icons.light_mode),
      (mode: 'dark', name: 'Dark', icon: Icons.dark_mode),
      (mode: 'auto', name: 'Auto', icon: Icons.brightness_auto),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: themes.map((theme) {
        final isSelected = _theme == theme.mode;
        return Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryPurple : context.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                setState(() => _theme = theme.mode);
                // Save theme to SharedPreferences for persistence
                await _saveThemeToPrefs(theme.mode);
                // Change app theme immediately
                _changeAppTheme(theme.mode);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    theme.icon,
                    size: 32,
                    color: isSelected
                        ? AppColors.primaryPurple
                        : context.textPrimaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    theme.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primaryPurple
                          : context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
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
    );
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', themeMode);
    } catch (e) {
      debugPrint('Error saving theme to prefs: $e');
    }
  }

  /// Change app theme using the root VisionArtApp state
  void _changeAppTheme(String theme) {
    try {
      // Use the static method from VisionArtApp to access its state
      final appState = VisionArtApp.of(context);
      appState?.changeTheme(theme);
    } catch (e) {
      debugPrint('Error changing app theme: $e');
    }
  }

  /// Convert theme string to ThemeMode
  ThemeMode _stringToThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'auto':
      default:
        return ThemeMode.system;
    }
  }

  /// Convert ThemeMode to theme string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'auto';
    }
  }
}
