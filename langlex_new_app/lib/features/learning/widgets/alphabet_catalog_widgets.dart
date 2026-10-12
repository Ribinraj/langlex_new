import 'package:langlex_new_app/features/progress/alphabet_practice_action.dart';
import 'package:langlex_new_app/features/progress/progress_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/urls.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class AlphabetSearchResults extends StatelessWidget {
  const AlphabetSearchResults({
    super.key,
    required this.rows,
    required this.total,
    required this.language,
  });

  final List<Map<String, dynamic>> rows;
  final int total;
  final String language;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                t.lettersAndSounds,
                style: GoogleFonts.montserrat(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Appcolors.ktextdark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Appcolors.kwhitecolor.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t.letterCount(total),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Appcolors.klibrarySubtitle,
                  ),
                ),
              ),
            ],
          ),
        ),
        AlphabetGroups(rows: rows, showPreviews: true, language: language),
      ],
    );
  }
}

class AlphabetGroups extends StatelessWidget {
  const AlphabetGroups({
    super.key,
    required this.rows,
    this.showPreviews = false,
    this.language = 'English',
  });
  final List<Map<String, dynamic>> rows;
  final bool showPreviews;
  final String language;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final course = row['coursename']?.toString().trim() ?? '';
      groups.putIfAbsent(course, () => []).add(row);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups.entries) ...[
          if (group.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Appcolors.kprimarycolor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.key,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Appcolors.kheroGreetingText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final minTileWidth = 130 * textScale.clamp(1.0, 1.6);
              final columns =
                  ((constraints.maxWidth + 12) / (minTileWidth + 12))
                      .floor()
                      .clamp(1, 4);
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (index, row) in group.value.indexed)
                    SizedBox(
                      width: width,
                      child: _AlphabetLetter(
                        row: row,
                        index: index,
                        showPreview: showPreviews,
                        language: language,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _AlphabetLetter extends StatelessWidget {
  const _AlphabetLetter({
    required this.row,
    required this.index,
    required this.showPreview,
    required this.language,
  });
  final bool showPreview;
  final String language;
  final int index;
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final letter = row['letter']?.toString() ?? '';
    final examples = (row['examples'] as List? ?? [row])
        .whereType<Map>()
        .toList();
    const surfaces = [
      Appcolors.kauthSoftBlue,
      Appcolors.kauthSoftGreen,
      Appcolors.kgoalChipGoldSurface,
    ];
    const accents = [
      Appcolors.klibraryTitle,
      Appcolors.kdashboardOnlineText,
      Appcolors.kheroStartButtonText,
    ];
    final accent = accents[index % accents.length];
    final surface = surfaces[index % surfaces.length];
    void openExamples() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Appcolors.kscreenWarmBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor:
            ((280 +
                        examples.length *
                            108 *
                            (MediaQuery.textScalerOf(context).scale(16) / 16)) /
                    MediaQuery.sizeOf(context).height)
                .clamp(.35, .8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          letter,
                          style: GoogleFonts.montserrat(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations(
                            language,
                          ).exampleCount(examples.length),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Appcolors.ktextgreycolor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LearningAudioButton(
                    path: row['letter_sound']?.toString() ?? '',
                    tooltip: 'Play letter $letter',
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: examples.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final example = examples[index];
                  final word = example['ill_word']?.toString() ?? '';
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LearningMediaImage(
                        path: example['ill_image']?.toString() ?? '',
                        accent: Appcolors.kdashboardTeal,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          word,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Appcolors.ktextdark,
                          ),
                        ),
                      ),
                      LearningAudioButton(
                        path: example['word_audio']?.toString() ?? '',
                        tooltip: 'Play $word',
                      ),
                    ],
                  );
                },
              ),
            ),
            AlphabetPracticeAction(
              contentKey: '${row['progress_key'] ?? 'alphabet-${row['id']}'}',
              language: '${row['language'] ?? language}',
              exampleIds: examples
                  .map((e) => int.tryParse('${e['id']}'))
                  .whereType<int>()
                  .where((id) => id > 0)
                  .toSet()
                  .toList(),
            ),
          ],
        ),
      ),
    );
    if (showPreview) {
      return _AlphabetPreviewCard(
        row: row,
        examples: examples,
        letter: letter,
        accent: accent,
        surface: surface,
        language: language,
        onTap: openExamples,
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accent.withValues(alpha: .14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openExamples,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
          child: Column(
            children: [
              Text(
                letter,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              TopicProgressBadge(
                type: 'alphabet',
                contentKey: '${row['progress_key'] ?? 'alphabet-${row['id']}'}',
                language: '${row['language'] ?? language}',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${examples.length} ${examples.length == 1 ? 'example' : 'examples'}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 17, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlphabetPreviewCard extends StatelessWidget {
  const _AlphabetPreviewCard({
    required this.row,
    required this.examples,
    required this.letter,
    required this.accent,
    required this.surface,
    required this.language,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final List<Map> examples;
  final String letter;
  final Color accent;
  final Color surface;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(language);
    final preview = examples.firstOrNull ?? row;
    final word = preview['ill_word']?.toString().trim() ?? '';
    final image = Endpoints.mediaUrl(preview['ill_image']?.toString() ?? '');
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Material(
      color: Appcolors.kwhitecolor,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 96,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: GoogleFonts.montserrat(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    if (image.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 48,
                        height: 68,
                        child: Image.network(
                          image,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.image_outlined,
                            color: accent.withValues(alpha: .45),
                            size: 28,
                          ),
                          frameBuilder: (_, child, frame, loaded) =>
                              loaded || frame != null
                              ? child
                              : Icon(
                                  Icons.image_outlined,
                                  color: accent.withValues(alpha: .25),
                                  size: 28,
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44 * scale,
                child: Text(
                  word.isEmpty ? t.alphabets : word,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: Appcolors.ktextdark,
                  ),
                ),
              ),
              TopicProgressBadge(
                type: 'alphabet',
                contentKey: '${row['progress_key'] ?? 'alphabet-${row['id']}'}',
                language: '${row['language'] ?? language}',
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.exampleCount(examples.length),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Appcolors.klibrarySubtitle,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        iconButtonTheme: IconButtonThemeData(
                          style: IconButton.styleFrom(
                            foregroundColor: accent,
                            backgroundColor: surface,
                          ),
                        ),
                      ),
                      child: LearningAudioButton(
                        path: row['letter_sound']?.toString() ?? '',
                        tooltip: '${t.listen} · $letter',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrowseAlphabetButton extends StatelessWidget {
  const BrowseAlphabetButton({
    super.key,
    required this.count,
    required this.language,
    required this.onPressed,
  });
  final int count;
  final String language;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: Appcolors.klibraryTitle,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Appcolors.klibraryTitle, Appcolors.kbottomNavActive],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Appcolors.klibraryTitle.withValues(alpha: .18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Appcolors.kwhitecolor.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Appcolors.kwhitecolor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse all $count letter forms',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        color: Appcolors.kwhitecolor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$language · Pictures & sounds',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Appcolors.kwhitecolor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Appcolors.kwhitecolor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
