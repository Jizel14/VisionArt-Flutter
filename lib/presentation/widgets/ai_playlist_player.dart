import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/preference_storage.dart';
import '../../core/user_preferences.dart';
import '../theme/app_colors.dart';

import '../screens/audio/focus_player_screen.dart';

class AiPlaylistPlayer extends StatefulWidget {
  const AiPlaylistPlayer({super.key});

  @override
  State<AiPlaylistPlayer> createState() => _AiPlaylistPlayerState();
}

class _AiPlaylistPlayerState extends State<AiPlaylistPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _playlistUrls = [];
  SonicPlaylist? _currentPlaylist;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isExpanded = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlaylist();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        _nextTrack();
      }
    });
  }

  Future<void> _initPlaylist() async {
    final prefs = await PreferenceStorage.load();
    if (mounted) {
      setState(() {
        if (prefs.playlists.isNotEmpty) {
          _currentPlaylist = prefs.playlists.first;
          _playlistUrls = _currentPlaylist!.urls;
        } else {
          _playlistUrls = prefs.playlistUrls;
          _currentPlaylist = SonicPlaylist(
            id: 'legacy',
            name: 'AI Sonic Universe',
            urls: _playlistUrls,
          );
        }
        _isLoading = false;
      });
      if (_playlistUrls.isNotEmpty) {
        try {
          await _audioPlayer.setSource(UrlSource(_playlistUrls[_currentIndex]));
        } catch (e) {
          print('Error setting audio source: $e');
        }
      }
    }
  }

  void _openFocusMode() {
    if (_currentPlaylist == null) return;
    
    // Stop current audio before opening full screen to avoid overlap
    _audioPlayer.stop();
    setState(() => _isPlaying = false);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusPlayerScreen(
          playlist: _currentPlaylist!,
          initialIndex: _currentIndex,
        ),
      ),
    );
  }

  Future<void> _togglePlay() async {
    if (_playlistUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: La playlist est vide. Veuillez regénérer la musique !')),
        );
      }
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.source == null) {
          try {
            await _audioPlayer.setSource(UrlSource(_playlistUrls[_currentIndex]));
          } catch (e) {
            print('Error setting source: $e');
          }
        }
        await _audioPlayer.resume();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur audio: $e')),
        );
      }
    }
  }

  Future<void> _nextTrack() async {
    if (_playlistUrls.isEmpty) return;
    if (mounted) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _playlistUrls.length;
      });
    }
    try {
      await _audioPlayer.play(UrlSource(_playlistUrls[_currentIndex]));
    } catch (e) {
      print('Error playing next track: $e');
    }
  }

  Future<void> _prevTrack() async {
    if (_playlistUrls.isEmpty) return;
    if (mounted) {
      setState(() {
        _currentIndex = (_currentIndex - 1 < 0)
            ? _playlistUrls.length - 1
            : _currentIndex - 1;
      });
    }
    try {
      await _audioPlayer.play(UrlSource(_playlistUrls[_currentIndex]));
    } catch (e) {
      print('Error playing prev track: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _playlistUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _openFocusMode,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          _openFocusMode();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.primaryPurple,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentPlaylist?.name ?? 'AI Sonic Universe',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Track ${_currentIndex + 1} of ${_playlistUrls.length}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, color: Colors.white),
                          onPressed: _prevTrack,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlay,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: _nextTrack,
                        ),
                      ],
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
