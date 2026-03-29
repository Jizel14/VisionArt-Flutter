import 'package:flutter/material.dart';
import '../../../core/preferences_service.dart';
import '../../../core/models/user_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

/// Context permissions: location, weather, calendar, music, time (GDPR-compliant)
class PreferencesContext extends StatefulWidget {
  const PreferencesContext({
    super.key,
    required this.preferences,
    required this.preferencesService,
    required this.onUpdated,
  });

  final UserPreferences preferences;
  final PreferencesService preferencesService;
  final Function(UserPreferences) onUpdated;

  @override
  State<PreferencesContext> createState() => _PreferencesContextState();
}

class _PreferencesContextState extends State<PreferencesContext> {
  late bool _enableLocation;
  late bool _enableWeather;
  late bool _enableCalendar;
  late bool _enableMusic;
  late bool _enableTime;
  late String _locationPrecision;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _enableLocation = widget.preferences.enableLocationContext;
    _enableWeather = widget.preferences.enableWeatherContext;
    _enableCalendar = widget.preferences.enableCalendarContext;
    _enableMusic = widget.preferences.enableMusicContext;
    _enableTime = widget.preferences.enableTimeContext;
    _locationPrecision = widget.preferences.locationPrecision;
  }

  Future<void> _updateContextPermissions() async {
    setState(() => _updating = true);
    try {
      final updated = await widget.preferencesService.updateContextPermissions(
        enableLocationContext: _enableLocation,
        enableWeatherContext: _enableWeather,
        enableCalendarContext: _enableCalendar,
        enableMusicContext: _enableMusic,
        enableTimeContext: _enableTime,
        locationPrecision: _locationPrecision,
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
          // GDPR Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text(
              '🔐 Your privacy matters. We only use context data you explicitly consent to. All permissions default to OFF (opt-in).',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 24),

          // Location Context
          _buildPermissionToggle(
            title: '📍 Location Context',
            description: 'Use your location to influence art generation',
            value: _enableLocation,
            onChanged: (val) => setState(() => _enableLocation = val),
            child: _enableLocation ? _buildPrecisionDropdown() : null,
          ),
          const SizedBox(height: 20),

          // Weather Context
          _buildPermissionToggle(
            title: '🌤️ Weather Context',
            description: 'Use current weather to inspire generation',
            value: _enableWeather,
            onChanged: (val) => setState(() => _enableWeather = val),
          ),
          const SizedBox(height: 20),

          // Calendar Context
          _buildPermissionToggle(
            title: '📅 Calendar Context',
            description: 'Use calendar events for context-aware generation',
            value: _enableCalendar,
            onChanged: (val) => setState(() => _enableCalendar = val),
          ),
          const SizedBox(height: 20),

          // Music Context
          _buildPermissionToggle(
            title: '🎵 Music Context',
            description: 'Use your music preferences to influence style',
            value: _enableMusic,
            onChanged: (val) => setState(() => _enableMusic = val),
          ),
          const SizedBox(height: 20),

          // Time Context (always available, user shown for transparency)
          _buildPermissionToggle(
            title: '⏰ Time Context',
            description: 'Use time of day to influence generation',
            value: _enableTime,
            onChanged: (val) => setState(() => _enableTime = val),
            note: 'Non-sensitive, helps create day/night themed art',
          ),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _updating ? null : _updateContextPermissions,
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
                  : const Text('Save Context Permissions'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPermissionToggle({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    Widget? child,
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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
        if (child != null) ...[
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.only(left: 12), child: child),
        ],
      ],
    );
  }

  Widget _buildPrecisionDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        value: _locationPrecision,
        onChanged: (val) {
          if (val != null) setState(() => _locationPrecision = val);
        },
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text('Select precision'),
        items: [
          DropdownMenuItem(
            value: 'city',
            child: Row(
              children: const [
                Icon(Icons.location_city, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('City Level (Privacy-friendly)')),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'district',
            child: Row(
              children: const [
                Icon(Icons.location_on, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('District Level')),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'precise',
            child: Row(
              children: const [
                Icon(Icons.gps_fixed, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Precise GPS')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
