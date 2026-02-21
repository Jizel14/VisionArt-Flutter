import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/preferences_service.dart';
import '../../../core/models/user_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import 'preferences_aesthetic.dart';
import 'preferences_context.dart';
import 'preferences_privacy.dart';
import 'preferences_ui.dart';

/// Main preferences screen with tabbed navigation
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({
    super.key,
    this.apiClient,
    required this.onPreferencesUpdated,
    this.onThemeChanged,
  });

  final ApiClient? apiClient;
  final VoidCallback? onPreferencesUpdated;
  final Function(String)? onThemeChanged;

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with TickerProviderStateMixin {
  late PreferencesService _preferencesService;
  late TabController _tabController;
  UserPreferences? _preferences;
  bool _loading = true;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _preferencesService = PreferencesService();
    _tabController = TabController(length: 4, vsync: this);
    _loadPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _preferencesService.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = prefs;
          _loading = false;
          _error = null;
        });
      }
    } on SessionExpiredException {
      if (mounted) {
        setState(() => _loading = false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    setState(() => _successMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _successMessage = null);
    });
  }

  void _handlePreferencesUpdated(UserPreferences updated) {
    setState(() => _preferences = updated);
    _showSuccessMessage('Preferences updated successfully!');
    widget.onPreferencesUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingScreen(context);
    }

    if (_error != null) {
      return _buildErrorScreen(context);
    }

    if (_preferences == null) {
      return _buildErrorScreen(context);
    }

    return SmokeBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Preferences'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: context.textSecondaryColor,
            indicatorColor: AppColors.primaryPurple,
            tabs: const [
              Tab(text: '🎨 Aesthetic'),
              Tab(text: '🌍 Context'),
              Tab(text: '🔒 Privacy'),
              Tab(text: '⚙️ UI/UX'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_successMessage != null)
              Container(
                color: Colors.green.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  PreferencesAesthetic(
                    preferences: _preferences!,
                    preferencesService: _preferencesService,
                    onUpdated: _handlePreferencesUpdated,
                  ),
                  PreferencesContext(
                    preferences: _preferences!,
                    preferencesService: _preferencesService,
                    onUpdated: _handlePreferencesUpdated,
                  ),
                  PreferencesPrivacy(
                    preferences: _preferences!,
                    preferencesService: _preferencesService,
                    onUpdated: _handlePreferencesUpdated,
                  ),
                  PreferencesUI(
                    preferences: _preferences!,
                    preferencesService: _preferencesService,
                    onUpdated: _handlePreferencesUpdated,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error ?? 'Failed to load preferences',
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadPreferences,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
