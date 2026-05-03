import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:io';
import '../../../core/user_preferences.dart';
import '../../../core/visioncraft_service.dart';
import '../../../core/app_config.dart';
import '../../../core/preference_storage.dart';
import '../../theme/app_colors.dart';

class FocusPlayerScreen extends StatefulWidget {
  const FocusPlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  final SonicPlaylist playlist;
  final int initialIndex;

  @override
  State<FocusPlayerScreen> createState() => _FocusPlayerScreenState();
}

class _FocusPlayerScreenState extends State<FocusPlayerScreen> with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  late SonicPlaylist _currentPlaylist;
  List<SonicPlaylist> _allPlaylists = [];
  bool _isPlaying = false;
  bool _isDownloading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentPlaylist = widget.playlist;
    _audioPlayer = AudioPlayer();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _initAudio();
    _loadAllPlaylists();
  }

  Future<void> _loadAllPlaylists() async {
    final prefs = await PreferenceStorage.load();
    if (mounted) {
      setState(() {
        _allPlaylists = prefs.playlists;
      });
    }
  }

  Future<void> _initAudio() async {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
        if (_isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      }
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      _nextTrack();
    });

    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentPlaylist.urls.isEmpty) return;
    try {
      await _audioPlayer.play(UrlSource(_currentPlaylist.urls[_currentIndex]));
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _nextTrack() async {
    if (_currentPlaylist.urls.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _currentPlaylist.urls.length;
    });
    await _playCurrent();
  }

  Future<void> _prevTrack() async {
    if (_currentPlaylist.urls.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 < 0)
          ? _currentPlaylist.urls.length - 1
          : _currentIndex - 1;
    });
    await _playCurrent();
  }

  Future<void> _showPlaylistSelection() async {
    final prefs = await PreferenceStorage.load();
    final playlists = prefs.playlists;
    final currentUrl = _currentPlaylist.urls[_currentIndex];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ajouter à la playliste',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: AppColors.primaryPurple),
                  ),
                  title: const Text(
                    'Nouvelle playliste',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    final nameController = TextEditingController();
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.bgDark,
                        title: const Text('Nouvelle playliste', style: TextStyle(color: Colors.white)),
                        content: TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Nom de la playliste',
                            hintStyle: TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPurple)),
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, nameController.text),
                            child: const Text('Créer', style: TextStyle(color: AppColors.primaryPurple)),
                          ),
                        ],
                      ),
                    );

                    if (newName != null && newName.isNotEmpty) {
                      final newPlaylist = SonicPlaylist(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: newName,
                        urls: [currentUrl],
                      );
                      
                      final updatedPlaylists = List<SonicPlaylist>.from(prefs.playlists)..add(newPlaylist);
                      await PreferenceStorage.save(prefs.copyWith(playlists: updatedPlaylists));
                      await _loadAllPlaylists(); // Refresh column
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Close bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Ajouté à "$newName"'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(color: Colors.white12, height: 32),
                const Text(
                  'Mes Playlists',
                  style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: playlists.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune playliste trouvée',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            final alreadyExists = playlist.urls.contains(currentUrl);
                            
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.playlist_play, color: Colors.white70),
                              ),
                              title: Text(
                                playlist.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${playlist.urls.length} titres',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              trailing: alreadyExists 
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : null,
                              onTap: alreadyExists ? null : () async {
                                final updatedUrls = List<String>.from(playlist.urls)..add(currentUrl);
                                final updatedPlaylist = playlist.copyWith(urls: updatedUrls);
                                
                                final updatedPlaylists = prefs.playlists.map((p) => p.id == playlist.id ? updatedPlaylist : p).toList();
                                await PreferenceStorage.save(prefs.copyWith(playlists: updatedPlaylists));
                                await _loadAllPlaylists(); // Refresh column
                                
                                if (context.mounted) {
                                  Navigator.pop(context); // Close bottom sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ Ajouté à "${playlist.name}"'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadAudio() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      String url = _currentPlaylist.urls[_currentIndex];
      
      // Ensure absolute URL
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        final base = AppConfig.apiBaseUrl.endsWith('/') 
            ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
            : AppConfig.apiBaseUrl;
        url = url.startsWith('/') ? '$base$url' : '$base/$url';
      }

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/visionart_audio_$timestamp.mp3';

      // Download the file
      await dio.download(url, filePath);

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveFile(filePath);
      
      if (mounted) {
        final success = result['isSuccess'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '🎵 Audio enregistré dans la galerie !' : '❌ Échec de l\'enregistrement.'),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _switchPlaylist(SonicPlaylist playlist) {
    if (_currentPlaylist.id == playlist.id) return;
    setState(() {
      _currentPlaylist = playlist;
      _currentIndex = 0;
    });
    _playCurrent();
  }

  Widget _buildPlaylistColumn() {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(top: 60, bottom: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.playlist_play_rounded, color: Colors.white60, size: 20),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _allPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = _allPlaylists[index];
                final isSelected = playlist.id == _currentPlaylist.id;
                
                return GestureDetector(
                  onTap: () => _switchPlaylist(playlist),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white24 : Colors.white10,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        playlist.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white60),
            onPressed: _showPlaylistSelection,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient/Image based on mood/styles
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.4),
                    AppColors.accentPink.withOpacity(0.2),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                _buildPlaylistColumn(),
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Column(
                              children: [
                                const Text(
                                  'PLAYING FROM UNIVERSE',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  _currentPlaylist.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                              onSelected: (value) {
                                if (value == 'add_to_playlist') {
                                  _showPlaylistSelection();
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'add_to_playlist',
                                  child: Row(
                                    children: [
                                      Icon(Icons.playlist_add, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Ajouter à la playliste', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                              color: AppColors.bgDark, // Couleur de fond du menu
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Vinyl/Art rotation
                      RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.width * 0.6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                            gradient: const SweepGradient(
                              colors: [
                                AppColors.primaryPurple,
                                AppColors.accentPink,
                                AppColors.lightBlue,
                                AppColors.primaryPurple,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Title & Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Track ${_currentIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI Generated • ${_currentPlaylist.mood ?? "Custom Mood"}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Progress Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: _position.inSeconds.toDouble(),
                                max: _duration.inSeconds.toDouble() > 0 
                                     ? _duration.inSeconds.toDouble() 
                                     : 1.0,
                                onChanged: (value) async {
                                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _isDownloading 
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white),
                                  onPressed: _downloadAudio,
                                  tooltip: 'Télécharger',
                                ),
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                              onPressed: _prevTrack,
                            ),
                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 40,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                              onPressed: _nextTrack,
                            ),
                            IconButton(
                              icon: const Icon(Icons.repeat_rounded, color: Colors.white60),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}