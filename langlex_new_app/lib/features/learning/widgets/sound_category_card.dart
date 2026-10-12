import 'package:langlex_new_app/features/progress/progress_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/phonics_practice_page.dart';

class SoundCategoryCard extends StatefulWidget {
  const SoundCategoryCard({
    super.key,
    required this.category,
    required this.language,
    required this.homeLanguage,
    required this.index,
  });

  final Map<String, dynamic> category;
  final String language;
  final String homeLanguage;
  final int index;

  @override
  State<SoundCategoryCard> createState() => _SoundCategoryCardState();
}

class _SoundCategoryCardState extends State<SoundCategoryCard> {
  bool _loading = false;
  bool _failed = false;

  String get _title => widget.category['title']?.toString() ?? '';

  Future<void> _start() async {
    if (_loading || _title.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final repository = context.read<LearningRepository>();
      final items = <PhonicsItem>[];
      // Fetch only the selected category. Larger categories retain every sound
      // across API pages instead of being cut off at the catalog's page size.
      for (var page = 1; ; page++) {
        final result = await repository.fetchPage(
          'phonics',
          PhonicsItem.fromJson,
          page: page,
          limit: 100,
          filters: {'language': widget.language, 'course': _title},
        );
        if (!mounted) return;
        items.addAll(result.items);
        if (!result.hasMore || result.items.isEmpty) break;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PhonicsPracticePage(
            phonics: items,
            homeLanguage: widget.homeLanguage,
            contentKey:
                'phonics-course-${widget.category['id']}-${widget.language}',
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        context.read<LearningRepository>().progress.refresh(widget.language);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(widget.homeLanguage);
    const accents = [
      Appcolors.klibraryTitle,
      Appcolors.kdashboardOnlineText,
      Appcolors.kheroStartButtonText,
    ];
    const surfaces = [
      Appcolors.kauthSoftBlue,
      Appcolors.kauthSoftGreen,
      Appcolors.kgoalChipGoldSurface,
    ];
    final accent = accents[widget.index % accents.length];
    final count = int.tryParse('${widget.category['sound_count']}') ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: .14)),
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 460 ||
              MediaQuery.textScalerOf(context).scale(16) > 22;
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: surfaces[widget.index % surfaces.length],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: accent,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        color: Appcolors.ktextdark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.soundCount(count),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Appcolors.ktextgreycolor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = FilledButton.icon(
            onPressed: _loading || _title.trim().isEmpty ? null : _start,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Appcolors.kwhitecolor,
              minimumSize: const Size(112, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _failed ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                  ),
            label: Text(
              _loading
                  ? t.loading
                  : _failed
                  ? t.retry
                  : t.start,
              semanticsLabel:
                  '${_loading
                      ? t.loading
                      : _failed
                      ? t.retry
                      : t.start} $_title',
              textAlign: TextAlign.center,
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stacked) ...[
                title,
                const SizedBox(height: 16),
                action,
              ] else
                Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 20),
                    action,
                  ],
                ),
              TopicProgressBadge(
                type: 'phonics',
                contentKey:
                    'phonics-course-${widget.category['id']}-${widget.language}',
                language: widget.language,
              ),
              if (_failed) ...[
                const SizedBox(height: 10),
                Text(
                  t.couldNotLoadLearningContent,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
