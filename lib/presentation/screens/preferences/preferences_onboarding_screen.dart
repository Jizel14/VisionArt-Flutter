import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../../../core/user_preferences.dart';
import '../../../core/preference_storage.dart';
import '../../../core/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

/// Single screen that changes content for each step (1-6 + summary).
/// Saves to SharedPreferences and syncs to backend on complete.
class PreferencesOnboardingScreen extends StatefulWidget {
  const PreferencesOnboardingScreen({
    super.key,
    required this.authService,
    required this.onComplete,
    this.initialPreferences,
  });

  final AuthService authService;
  final VoidCallback onComplete;
  /// When set (e.g. from profile), pre-fill and allow editing.
  final UserPreferences? initialPreferences;

  @override
  State<PreferencesOnboardingScreen> createState() => _PreferencesOnboardingScreenState();
}

class _PreferencesOnboardingScreenState extends State<PreferencesOnboardingScreen> {
  static const int _totalSteps = 7;
  late int _step;
  late List<String> _subjects;
  late List<String> _styles;
  late List<String> _colors;
  late String? _mood;
  late int _complexity;
  late PreferencePermissions _permissions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPreferences;
    _step = 0;
    _subjects = p?.subjects.toList() ?? [];
    _styles = p?.styles.toList() ?? [];
    _colors = p?.colors.toList() ?? [];
    _mood = p?.mood;
    _complexity = p?.complexity ?? 3;
    _permissions = p?.permissions ?? const PreferencePermissions();
  }

  static const List<Map<String, String>> _subjectOptions = [
    {'emoji': '🌿', 'label': 'Nature & Paysages', 'sub': 'Montagnes, forêts, mer'},
    {'emoji': '👤', 'label': 'Portraits & Personnages', 'sub': 'Visages, expressions'},
    {'emoji': '🏛️', 'label': 'Architecture', 'sub': 'Bâtiments, villes, monuments'},
    {'emoji': '🦊', 'label': 'Animaux', 'sub': 'Faune, animaux domestiques/sauvages'},
    {'emoji': '🧚', 'label': 'Fantastique', 'sub': 'Créatures, mondes imaginaires'},
    {'emoji': '🤖', 'label': 'Science-fiction', 'sub': 'Futur, technologie, robots'},
    {'emoji': '💭', 'label': 'Abstrait', 'sub': 'Formes, textures, concepts'},
    {'emoji': '🍎', 'label': 'Nature morte', 'sub': 'Objets, fleurs, compositions'},
  ];

  static const List<Map<String, String>> _styleOptions = [
    {'emoji': '🎨', 'label': 'Impressionnisme', 'sub': 'Jeux de lumière, Monet'},
    {'emoji': '🌌', 'label': 'Surréalisme', 'sub': 'Rêves, Dali, Magritte'},
    {'emoji': '🌃', 'label': 'Cyberpunk', 'sub': 'Néon, futuriste, Blade Runner'},
    {'emoji': '◻️', 'label': 'Minimalisme', 'sub': 'Épuré, formes simples'},
    {'emoji': '💧', 'label': 'Aquarelle', 'sub': 'Doux, transparent, fluide'},
    {'emoji': '🖼️', 'label': 'Peinture à l\'huile', 'sub': 'Riche texture, classique'},
    {'emoji': '💻', 'label': 'Art digital', 'sub': 'Moderne, net, graphique'},
    {'emoji': '🇯🇵', 'label': 'Anime/Manga', 'sub': 'Style japonais, expressif'},
  ];

  static const List<Map<String, String>> _colorOptions = [
    {'emoji': '🔴', 'label': 'Chaudes', 'sub': 'Rouge, orange, jaune'},
    {'emoji': '🔵', 'label': 'Froides', 'sub': 'Bleu, vert, violet'},
    {'emoji': '⚫', 'label': 'Monochrome', 'sub': 'Noir, blanc, gris'},
    {'emoji': '💗', 'label': 'Pastel', 'sub': 'Rose poudre, menthe, lavande'},
    {'emoji': '🟢', 'label': 'Néon', 'sub': 'Vert fluo, rose électrique'},
    {'emoji': '🌈', 'label': 'Arc-en-ciel', 'sub': 'Toutes les couleurs'},
  ];

  static const List<Map<String, String>> _moodOptions = [
    {'emoji': '😌', 'label': 'Calme', 'sub': 'Zen, paisible'},
    {'emoji': '⚡', 'label': 'Énergique', 'sub': 'Vibrant, dynamique'},
    {'emoji': '🌙', 'label': 'Mélancolique', 'sub': 'Nostalgique, profond'},
    {'emoji': '🌑', 'label': 'Mystérieux', 'sub': 'Sombre, intrigant'},
    {'emoji': '😊', 'label': 'Joyeux', 'sub': 'Coloré, optimiste'},
    {'emoji': '✨', 'label': 'Rêveur', 'sub': 'Fantaisie, éthéré'},
  ];

  static const List<Map<String, String>> _permissionOptions = [
    {'emoji': '📍', 'label': 'Localisation', 'sub': 'Adapter l\'art à ton lieu'},
    {'emoji': '🌤️', 'label': 'Météo', 'sub': 'Créer selon le temps qu\'il fait'},
    {'emoji': '🎵', 'label': 'Musique', 'sub': 'S\'inspirer de ce que tu écoutes'},
    {'emoji': '📅', 'label': 'Calendrier', 'sub': 'Créer pour tes événements'},
    {'emoji': '⏰', 'label': 'Heure du jour', 'sub': 'Adapter à la lumière'},
    {'emoji': '📸', 'label': 'Photos', 'sub': 'S\'inspirer de ta galerie'},
  ];

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _complete();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    final p = UserPreferences(
      subjects: _subjects,
      styles: _styles,
      colors: _colors,
      mood: _mood,
      complexity: _complexity,
      permissions: _permissions,
      onboardingComplete: true,
    );
    await PreferenceStorage.save(p);
    try {
      await widget.authService.updatePreferences(p);
    } catch (_) {}
    if (mounted) {
      setState(() => _saving = false);
      widget.onComplete();
    }
  }

  void _skip() {
    if (_step < _totalSteps - 2) {
      setState(() => _step++);
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final borderColor = context.borderColor;
    final cardBg = context.cardBackgroundColor;
    return Scaffold(
      body: SmokeBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (widget.initialPreferences != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                ),
              _progressBar(context, textSecondary, borderColor),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(context, textPrimary, textSecondary, borderColor, cardBg),
                ),
              ),
              _bottomBar(textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBar(BuildContext context, Color textSecondary, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text(
            '${_step + 1}/$_totalSteps',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_step + 1) / _totalSteps,
                backgroundColor: borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, Color textPrimary, Color textSecondary, Color borderColor, Color cardBg) {
    switch (_step) {
      case 0:
        return _buildMultiSelect(
          key: const ValueKey(0),
          title: "Qu'est-ce qui t'inspire le plus ?",
          subtitle: 'Choisis 1-3 sujets favoris',
          options: _subjectOptions,
          selected: _subjects,
          maxSelection: 3,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          cardBg: cardBg,
          onToggle: (label) {
            setState(() {
              if (_subjects.contains(label)) {
                _subjects = _subjects.where((s) => s != label).toList();
              } else if (_subjects.length < 3) {
                _subjects = [..._subjects, label];
              }
            });
          },
        );
      case 1:
        return _buildMultiSelect(
          key: const ValueKey(1),
          title: 'Quel style artistique préfères-tu ?',
          subtitle: 'Choisis 1-3 styles',
          options: _styleOptions,
          selected: _styles,
          maxSelection: 3,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          cardBg: cardBg,
          onToggle: (label) {
            setState(() {
              if (_styles.contains(label)) {
                _styles = _styles.where((s) => s != label).toList();
              } else if (_styles.length < 3) {
                _styles = [..._styles, label];
              }
            });
          },
        );
      case 2:
        return _buildColorStep(textPrimary, textSecondary, borderColor, cardBg);
      case 3:
        return _buildMoodStep(textPrimary, textSecondary, borderColor, cardBg);
      case 4:
        return _buildComplexityStep(textPrimary, textSecondary);
      case 5:
        return _buildPermissionsStep(context, textPrimary, textSecondary);
      case 6:
        return _buildSummaryStep(textPrimary, textSecondary);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMultiSelect({
    required Key key,
    required String title,
    required String subtitle,
    required List<Map<String, String>> options,
    required List<String> selected,
    required int maxSelection,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color cardBg,
    required ValueChanged<String> onToggle,
  }) {
    return FadeIn(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: textSecondary)),
            Text('${selected.length}/$maxSelection sélectionnés', style: TextStyle(fontSize: 12, color: AppColors.primaryPurple)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: options.map((opt) {
                final label = opt['label']!;
                final isSelected = selected.contains(label);
                return FadeInLeft(
                  child: _OptionCard(
                    emoji: opt['emoji']!,
                    label: label,
                    sub: opt['sub']!,
                    isSelected: isSelected,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    cardBg: cardBg,
                    onTap: () => onToggle(label),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorStep(Color textPrimary, Color textSecondary, Color borderColor, Color cardBg) {
    return FadeIn(
      key: const ValueKey(2),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text("Quelles couleurs te parlent ?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text('Choisis 1-2 palettes', style: TextStyle(fontSize: 14, color: textSecondary)),
            Text('${_colors.length}/2 sélectionnés', style: TextStyle(fontSize: 12, color: AppColors.primaryPurple)),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colorOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final opt = _colorOptions[i];
                  final label = opt['label']!;
                  final isSelected = _colors.contains(label);
                  return FadeInRight(
                    child: _ColorCard(
                      emoji: opt['emoji']!,
                      label: label,
                      sub: opt['sub']!,
                      isSelected: isSelected,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                      cardBg: cardBg,
                      onTap: () {
                        setState(() {
                          if (_colors.contains(label)) {
                            _colors = _colors.where((c) => c != label).toList();
                          } else if (_colors.length < 2) {
                            _colors = [..._colors, label];
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodStep(Color textPrimary, Color textSecondary, Color borderColor, Color cardBg) {
    return FadeIn(
      key: const ValueKey(3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text("Quelle ambiance recherche ton art ?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text('Choisis ton ambiance principale', style: TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: _moodOptions.map((opt) {
                final label = opt['label']!;
                final isSelected = _mood == label;
                return FadeInUp(
                  child: _OptionCard(
                    emoji: opt['emoji']!,
                    label: label,
                    sub: opt['sub']!,
                    isSelected: isSelected,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    cardBg: cardBg,
                    onTap: () => setState(() => _mood = isSelected ? null : label),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplexityStep(Color textPrimary, Color textSecondary) {
    const labels = ['Minimal', 'Simple', 'Équilibré', 'Détaillé', 'Très détaillé'];
    const emojis = ['⚪', '🔵', '🟢', '🟠', '🔴'];
    return FadeIn(
      key: const ValueKey(4),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text('Quel niveau de détail préfères-tu ?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text('De simple à très détaillé', style: TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 32),
            Text('${emojis[_complexity - 1]} ${labels[_complexity - 1]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryPurple)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(activeTrackColor: AppColors.primaryPurple, thumbColor: AppColors.primaryPurple),
              child: Slider(
                value: _complexity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setState(() => _complexity = v.round()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) => Text('${emojis[i]}', style: TextStyle(fontSize: 16, color: i + 1 == _complexity ? AppColors.primaryPurple : textSecondary))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsStep(BuildContext context, Color textPrimary, Color textSecondary) {
    final cardBg = context.cardBackgroundColor;
    return FadeIn(
      key: const ValueKey(5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text('Personnalisation contextuelle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text('Laisse VisionArt s\'adapter à ton moment', style: TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 24),
            ..._permissionOptions.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              bool value = false;
              if (i == 0) value = _permissions.location;
              if (i == 1) value = _permissions.weather;
              if (i == 2) value = _permissions.music;
              if (i == 3) value = _permissions.calendar;
              if (i == 4) value = _permissions.timeOfDay;
              if (i == 5) value = _permissions.gallery;
              return FadeInRight(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: cardBg,
                  child: SwitchListTile(
                    secondary: Text(opt['emoji']!, style: const TextStyle(fontSize: 24)),
                    title: Text(opt['label']!, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(opt['sub']!, style: TextStyle(fontSize: 12, color: textSecondary)),
                    value: value,
                    activeColor: AppColors.primaryPurple,
                    onChanged: (v) {
                      setState(() {
                        if (i == 0) _permissions = _permissions.copyWith(location: v);
                        if (i == 1) _permissions = _permissions.copyWith(weather: v);
                        if (i == 2) _permissions = _permissions.copyWith(music: v);
                        if (i == 3) _permissions = _permissions.copyWith(calendar: v);
                        if (i == 4) _permissions = _permissions.copyWith(timeOfDay: v);
                        if (i == 5) _permissions = _permissions.copyWith(gallery: v);
                      });
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStep(Color textPrimary, Color textSecondary) {
    return FadeIn(
      key: const ValueKey(6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text('Prêt à créer !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text('Voici ton profil artistique', style: TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 24),
            _SummaryChip(label: 'Sujets', values: _subjects, textPrimary: textPrimary, textSecondary: textSecondary),
            _SummaryChip(label: 'Styles', values: _styles, textPrimary: textPrimary, textSecondary: textSecondary),
            _SummaryChip(label: 'Couleurs', values: _colors, textPrimary: textPrimary, textSecondary: textSecondary),
            if (_mood != null) _SummaryChip(label: 'Ambiance', values: [_mood!], textPrimary: textPrimary, textSecondary: textSecondary),
            _SummaryChip(label: 'Détail', values: ['Niveau $_complexity'], textPrimary: textPrimary, textSecondary: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_saving)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
          else ...[
            Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: _back,
                    child: Text('Retour', style: TextStyle(color: textSecondary)),
                  ),
                const Spacer(),
                if (_step < _totalSteps - 1 && _step < 5)
                  TextButton(
                    onPressed: _skip,
                    child: Text('Plus tard', style: TextStyle(color: AppColors.accentPink)),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _step == _totalSteps - 2
                        ? 'Confirmer mes préférences'
                        : _step == _totalSteps - 1
                            ? (widget.initialPreferences != null ? 'Enregistrer' : 'Créer mon premier chef-d\'œuvre')
                            : 'Suivant',
                  ),
                ),
              ],
            ),
            if (_step == _totalSteps - 1)
              TextButton(
                onPressed: () => widget.onComplete(),
                child: Text('Explorer sans générer', style: TextStyle(color: textSecondary, fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.isSelected,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.cardBg,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String sub;
  final bool isSelected;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color cardBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primaryPurple : borderColor, width: isSelected ? 2 : 1),
          color: isSelected ? AppColors.primaryPurple.withOpacity(0.2) : cardBg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
            Text(sub, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  const _ColorCard({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.isSelected,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.cardBg,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String sub;
  final bool isSelected;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color cardBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primaryPurple : borderColor, width: isSelected ? 2 : 1),
          color: isSelected ? AppColors.primaryPurple.withOpacity(0.2) : cardBg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            Text(sub, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.values,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String label;
  final List<String> values;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary))),
          Expanded(child: Text(values.join(', '), style: TextStyle(color: textPrimary))),
        ],
      ),
    );
  }
}
