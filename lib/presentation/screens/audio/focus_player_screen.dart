import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/user_preferences.dart';
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
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _audioPlayer = AudioPlayer();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _initAudio();
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
    if (widget.playlist.urls.isEmpty) return;
    try {
      await _audioPlayer.play(UrlSource(widget.playlist.urls[_currentIndex]));
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
    if (widget.playlist.urls.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.playlist.urls.length;
    });
    await _playCurrent();
  }

  Future<void> _prevTrack() async {
    if (widget.playlist.urls.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 < 0)
          ? widget.playlist.urls.length - 1
          : _currentIndex - 1;
    });
    await _playCurrent();
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
                            widget.playlist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Vinyl/Art rotation
                RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
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
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Title & Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track ${_currentIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI Generated • ${widget.playlist.mood ?? "Custom Mood"}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle_rounded, color: Colors.white60),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                        onPressed: _prevTrack,
                      ),
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 48,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                        onPressed: _nextTrack,
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat_rounded, color: Colors.white60),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}