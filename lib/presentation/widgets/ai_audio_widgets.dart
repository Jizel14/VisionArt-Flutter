import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/services/audio_service.dart';
import '../../core/app_config.dart';

class AudioGenButton extends StatefulWidget {
  const AudioGenButton({
    super.key,
    required this.artworkId,
    required this.onStarted,
    required this.onComplete,
    required this.onError,
    this.color,
    this.keywords,
  });
  final String artworkId;
  final VoidCallback onStarted;
  final Function(String) onComplete;
  final VoidCallback onError;
  final Color? color;
  /// Comma-separated keywords describing the artwork (genre, mood, instruments).
  /// If null, a generic ambient/calm prompt is used.
  final String? keywords;

  @override
  State<AudioGenButton> createState() => _AudioGenButtonState();
}

class _AudioGenButtonState extends State<AudioGenButton> {
  bool _busy = false;

  Future<void> _generateAudio() async {
    if (_busy) return;
    setState(() => _busy = true);
    widget.onStarted();
    try {
      final kw = widget.keywords ?? 'ambient, calm, atmospheric';
      final audioUrl = await AudioService().generateForImage(kw);
      if (audioUrl != null && mounted) {
        widget.onComplete(audioUrl);
      } else {
        widget.onError();
      }
    } catch (e) {
      if (mounted) {
        widget.onError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Audio error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Générer la musique IA',
      child: FilledButton(
        onPressed: _busy ? null : _generateAudio,
        style: FilledButton.styleFrom(
          backgroundColor: widget.color ?? Colors.white.withOpacity(0.16),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withOpacity(0.08),
          padding: const EdgeInsets.all(18),
          minimumSize: const Size(56, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.22)),
          ),
        ),
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.music_note_rounded, size: 26),
      ),
    );
  }
}

class AudioVisualizer extends StatefulWidget {
  const AudioVisualizer({super.key});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [0.2, 0.8, 0.4, 0.7, 0.3, 0.9, 0.5, 0.6];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_heights.length, (index) {
            final double animatedHeight = 15 *
                (0.3 +
                    (_heights[index] * _controller.value) +
                    (0.2 * (index % 3 == 0 ? 1 : 0.5)));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: animatedHeight,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class SimpleAudioPlayer extends StatefulWidget {
  const SimpleAudioPlayer({super.key, required this.url});
  final String url;

  @override
  State<SimpleAudioPlayer> createState() => _SimpleAudioPlayerState();
}

class _SimpleAudioPlayerState extends State<SimpleAudioPlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;

  String _toAbsoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = AppConfig.apiBaseUrl.endsWith('/') 
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _player.onLog.listen((msg) => debugPrint("AudioPlayer: $msg"));
    
    // Play with error handling
    _playAudio();
  }

  Future<void> _playAudio() async {
    try {
      final absoluteUrl = _toAbsoluteUrl(widget.url);
      debugPrint("Playing audio from: $absoluteUrl");
      await _player.play(UrlSource(absoluteUrl));
    } catch (e) {
      debugPrint("Audio Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Audio playback failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _isPlaying ? _player.pause() : _player.resume(),
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Musique générée par IA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (_isPlaying) ...[
                  const SizedBox(height: 8),
                  const AudioVisualizer(),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _player.stop(),
            icon: const Icon(Icons.stop, color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }
}
