import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../../../core/signature_storage.dart';

/// Screen where the user draws their signature. Save stores in SharedPreferences; Use default clears it.
class SignatureEditorScreen extends StatefulWidget {
  const SignatureEditorScreen({super.key});

  @override
  State<SignatureEditorScreen> createState() => _SignatureEditorScreenState();
}

class _SignatureEditorScreenState extends State<SignatureEditorScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  final GlobalKey _canvasKey = GlobalKey();

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _currentStroke = [d.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_currentStroke != null) {
      setState(() => _currentStroke!.add(d.localPosition));
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_currentStroke != null && _currentStroke!.length > 1) {
      setState(() {
        _strokes.add(List.from(_currentStroke!));
        _currentStroke = null;
      });
    } else {
      setState(() => _currentStroke = null);
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw your signature first')),
      );
      return;
    }
    final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    try {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      await SignatureStorage.save(pngBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signature saved. It will appear on the next launch.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  Future<void> _useDefault() async {
    await SignatureStorage.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Using default logo. Restart the app to see it on splash.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('My signature', style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Draw your signature below. It will be used as your personal logo on the splash screen.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: _SignatureCanvasPainter(
                                strokes: _strokes,
                                currentStroke: _currentStroke,
                                color: textPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _strokes.isEmpty ? null : _clear,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Clear'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _useDefault,
                    child: Text('Use default', style: TextStyle(color: textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignatureCanvasPainter extends CustomPainter {
  _SignatureCanvasPainter({
    required this.strokes,
    this.currentStroke,
    required this.color,
  });

  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
    if (currentStroke != null && currentStroke!.length >= 2) {
      final path = Path()..moveTo(currentStroke![0].dx, currentStroke![0].dy);
      for (var i = 1; i < currentStroke!.length; i++) {
        path.lineTo(currentStroke![i].dx, currentStroke![i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureCanvasPainter old) {
    return old.strokes != strokes || old.currentStroke != currentStroke;
  }
}
