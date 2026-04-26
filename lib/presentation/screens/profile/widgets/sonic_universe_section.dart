import 'package:flutter/material.dart';
import '../../../../core/preference_storage.dart';
import '../../../../core/user_preferences.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../../audio/focus_player_screen.dart';

class SonicUniverseSection extends StatefulWidget {
  const SonicUniverseSection({super.key});

  @override
  State<SonicUniverseSection> createState() => _SonicUniverseSectionState();
}

class _SonicUniverseSectionState extends State<SonicUniverseSection> {
  List<SonicPlaylist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final prefs = await PreferenceStorage.load();
    if (mounted) {
      setState(() {
        if (prefs.playlists.isNotEmpty) {
          _playlists = prefs.playlists;
        } else if (prefs.playlistUrls.isNotEmpty) {
          // Migrer l'ancienne playlist vers le nouveau format
          _playlists = [
            SonicPlaylist(
              id: 'initial',
              name: 'My First Universe',
              urls: prefs.playlistUrls,
              mood: prefs.mood,
              styles: prefs.styles,
              colors: prefs.colors,
            )
          ];
        }
        _isLoading = false;
      });
    }
  }

  void _renamePlaylist(SonicPlaylist playlist) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer l\'Univers'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nom de l'univers"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _updatePlaylistName(playlist.id, newName);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePlaylistName(String id, String newName) async {
    final prefs = await PreferenceStorage.load();
    final updatedPlaylists = prefs.playlists.map((p) {
      if (p.id == id) return p.copyWith(name: newName);
      return p;
    }).toList();
    
    final newPrefs = prefs.copyWith(playlists: updatedPlaylists);
    await PreferenceStorage.save(newPrefs);
    _loadPlaylists();
  }

  Future<void> _deletePlaylist(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'Univers'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet univers sonore ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await PreferenceStorage.load();
      final updatedPlaylists = prefs.playlists.where((p) => p.id != id).toList();
      final newPrefs = prefs.copyWith(playlists: updatedPlaylists);
      await PreferenceStorage.save(newPrefs);
      _loadPlaylists();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppThemeColors.textPrimaryColor(context);
    final textSecondary = AppThemeColors.textSecondaryColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppColors.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Mes Univers Sonores',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucun univers généré. Complétez votre profil pour créer votre première ambiance sonore.',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _playlists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final playlist = _playlists[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white),
                  ),
                  title: Text(
                    playlist.name,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${playlist.urls.length} morceaux • ${playlist.mood ?? "Ambiance IA"}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: textSecondary, size: 20),
                    onSelected: (value) {
                      if (value == 'rename') _renamePlaylist(playlist);
                      if (value == 'delete') _deletePlaylist(playlist.id);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Renommer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FocusPlayerScreen(
                          playlist: playlist,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}