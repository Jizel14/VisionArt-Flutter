import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import 'art_creation_model.dart';

/// Step 2: Visual style picker, aspect ratio, quality, then Generate.
class CreateStep2Screen extends StatefulWidget {
  const CreateStep2Screen({
    super.key,
    required this.config,
    required this.generating,
    required this.error,
    required this.onBack,
    required this.onGenerate,
  });

  final ArtCreationConfig config;
  final bool generating;
  final String? error;
  final VoidCallback onBack;
  final void Function(ArtCreationConfig) onGenerate;

  @override
  State<CreateStep2Screen> createState() => _CreateStep2ScreenState();
}

class _CreateStep2ScreenState extends State<CreateStep2Screen> {
  VisualStyleOption? _selectedStyle;
  ArtAspectRatio _aspectRatio = ArtAspectRatio.square;
  int _quality = 3;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.config.selectedVisualStyle ?? kVisualStyles.first;
    _aspectRatio = widget.config.aspectRatio;
    _quality = widget.config.quality;
  }

  void _onGenerate() {
    final config = widget.config
      ..selectedVisualStyle = _selectedStyle
      ..aspectRatio = _aspectRatio
      ..quality = _quality;
    widget.onGenerate(config);
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final cardBg = context.cardBackgroundColor;
    final borderCol = context.borderColor;

    return SmokeBackground(
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.generating ? null : widget.onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Your Style',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          'Step 2 of 2 — Select visual style',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.4)),
                    ),
                    child: Text(
                      '2 / 2',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar (full) ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: borderCol,
                  color: AppColors.primaryPurple,
                  minHeight: 4,
                ),
              ),
            ),

            // ── Prompt preview chip ────────────────────────────
            FadeInDown(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote_rounded, size: 16, color: AppColors.primaryPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.config.prompt,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.generating ? null : widget.onBack,
                        child: Icon(Icons.edit_rounded, size: 14, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Visual Style Cards (3 large) ────────────
                    _SectionLabel(
                      icon: Icons.palette_rounded,
                      text: 'Visual Style',
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: kVisualStyles.asMap().entries.map((entry) {
                        final i = entry.key;
                        final style = entry.value;
                        final isSelected = _selectedStyle?.label == style.label;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 6,
                              right: i == kVisualStyles.length - 1 ? 0 : 6,
                            ),
                            child: FadeInUp(
                              delay: Duration(milliseconds: i * 80),
                              duration: const Duration(milliseconds: 350),
                              child: AspectRatio(
                                aspectRatio: 0.85,
                                child: _StyleCard(
                                  style: style,
                                  isSelected: isSelected,
                                  cardBg: cardBg,
                                  borderCol: borderCol,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  onTap: () => setState(() => _selectedStyle = style),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Aspect Ratio ─────────────────────────────
                    _SectionLabel(
                      icon: Icons.crop_rounded,
                      text: 'Aspect Ratio',
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ArtAspectRatio.values.map((r) {
                        final isSelected = _aspectRatio == r;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _aspectRatio = r),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.primaryPurple,
                                          AppColors.primaryBlue.withAlpha(200),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected ? null : cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? Colors.transparent : borderCol,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryPurple.withOpacity(0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.15 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(r.icon, style: TextStyle(fontSize: 20, color: isSelected ? Colors.white : textPrimary)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    r.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Quality Slider ───────────────────────────
                    _SectionLabel(
                      icon: Icons.high_quality_rounded,
                      text: 'Quality',
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Draft', style: TextStyle(color: textSecondary, fontSize: 11)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primaryPurple,
                              thumbColor: AppColors.primaryPurple,
                              inactiveTrackColor: borderCol,
                              overlayColor: AppColors.primaryPurple.withOpacity(0.15),
                            ),
                            child: Slider(
                              value: _quality.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              onChanged: (v) => setState(() => _quality = v.round()),
                            ),
                          ),
                        ),
                        Text('Ultra', style: TextStyle(color: textSecondary, fontSize: 11)),
                      ],
                    ),
                    Center(
                      child: _QualityBadge(quality: _quality, textPrimary: textPrimary),
                    ),

                    const SizedBox(height: 24),

                    // ── Error ────────────────────────────────────
                    if (widget.error != null)
                      FadeIn(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withOpacity(0.4)),
                          ),
                          child: Text(
                            widget.error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ),

                    // ── Generate button ──────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: SizedBox(
                        height: 58,
                        child: widget.generating
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Creating your masterpiece…',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: _selectedStyle == null ? null : _onGenerate,
                                icon: const Icon(Icons.auto_awesome, size: 22),
                                label: const Text(
                                  '✨  Generate Image',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    if (_selectedStyle != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          '${_selectedStyle!.emoji} ${_selectedStyle!.label} · ${_aspectRatio.label} · Quality ${_quality}/5',
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Style Card ──────────────────────────────────────────────────────────────

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.cardBg,
    required this.borderCol,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final VisualStyleOption style;
  final bool isSelected;
  final Color cardBg;
  final Color borderCol;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.2),
                    AppColors.primaryBlue.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple.withOpacity(0.8) : borderCol.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.25),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(style.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 6),
            Text(
              style.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.primaryPurple : textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                style.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 28,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryBlue]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Quality Badge ───────────────────────────────────────────────────────────

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.quality, required this.textPrimary});

  final int quality;
  final Color textPrimary;

  static const _labels = ['Draft', 'Basic', 'Balanced', 'High', 'Ultra'];
  static const _emojis = ['⚪', '🔵', '🟢', '🟠', '🌟'];

  @override
  Widget build(BuildContext context) {
    final idx = quality - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_emojis[idx]} ${_labels[idx]} Quality',
        style: TextStyle(
          color: AppColors.primaryPurple,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Section label helper ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.text,
    required this.textSecondary,
  });

  final IconData icon;
  final String text;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
