import 'package:langlex_new_app/core/app_toast.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class StoryReaderPage extends StatefulWidget {
  const StoryReaderPage({
    super.key,
    required this.story,
    required this.homeLanguage,
  });

  final StoryItem story;
  final String homeLanguage;

  @override
  State<StoryReaderPage> createState() => _StoryReaderPageState();
}

class _StoryReaderPageState extends State<StoryReaderPage> {
  final ScrollController _scrollController = ScrollController();
  Future<void>? _startProgressFuture;
  bool _isCompleting = false;

  String get _contentKey => widget.story.id > 0
      ? 'story-${widget.story.id}'
      : 'story-${widget.story.title.toLowerCase()}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startProgressFuture = _markStartedIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<ContentProgress> _saveProgress({required String status}) {
    return context.read<LearningRepository>().saveContentProgress(
      contentType: 'story',
      contentKey: _contentKey,
      position: status == 'completed' ? 1 : 0,
      totalItems: 1,
      status: status,
    );
  }

  Future<void> _markStartedIfNeeded() async {
    try {
      final progress = await context
          .read<LearningRepository>()
          .getContentProgress(contentType: 'story', contentKey: _contentKey);
      if (!mounted || progress.isCompleted) return;
    } catch (_) {
      if (!mounted) return;
    }

    try {
      await _saveProgress(status: 'in_progress');
    } catch (_) {
      // Opening a story should still work if progress sync is temporarily unavailable.
    }
  }

  Future<void> _completeReading() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      await _startProgressFuture;
      await _saveProgress(status: 'completed');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      AppToast.error(
        context,
        'Could not save story progress. Please try again.',
      );
    }
  }

  Future<void> _restartReading() async {
    try {
      await context.read<LearningRepository>().restartContentProgress(
        contentType: 'story',
        contentKey: _contentKey,
      );
    } catch (_) {
      // Local restart still works if the network is unavailable.
    }
    if (!mounted) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    await _saveProgress(status: 'in_progress');
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final t = AppLocalizations(widget.homeLanguage);

    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,

      body: FlowScrollView(
        header: FlowPageHeader(
          title: t.story,
          actions: [
            IconButton(
              onPressed: _restartReading,
              tooltip: t.restartPractice,
              icon: const Icon(Icons.replay_rounded),
            ),
          ],
        ),
        controller: _scrollController,
        padding: ResponsiveUtils.pagePadding(
          context,
          mobileHorizontalPercent: 6,
          tabletHorizontal: 42,
          desktopHorizontal: 56,
          top: 10,
          bottom: 36,
        ),
        child: ResponsiveUtils.constrainWidth(
          context: context,
          maxWidth: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Appcolors.kwhitecolor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Appcolors.kauthDivider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LearningMediaImage(
                      path: story.imagePath,
                      accent: Appcolors.kmetricInventory,
                      height: 190,
                      width: double.infinity,
                      borderRadius: 24,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Appcolors.kmetricInventorySurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Appcolors.kmetricInventory,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ResponsiveText(
                                story.title,
                                fontSize: 22,
                                weight: FontWeight.w900,
                                color: Appcolors.ktextdark,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 5),
                              ResponsiveText(
                                '${story.language} • ${story.grade} • ${story.minutes} min',
                                fontSize: 12,
                                weight: FontWeight.w800,
                                color: Appcolors.kdashboardMutedText,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LearningAccessPill(access: story.access),
                    const SizedBox(height: 18),
                    for (final section
                        in story.sections.isEmpty
                            ? [
                                StorySection(
                                  text: story.text,
                                  imagePath: story.imagePath,
                                  audioPath: story.audioPath,
                                ),
                              ]
                            : story.sections) ...[
                      if (section.imagePath.isNotEmpty &&
                          section.imagePath != story.imagePath)
                        LearningMediaImage(
                          path: section.imagePath,
                          accent: Appcolors.kmetricInventory,
                          height: 190,
                          width: double.infinity,
                        ),
                      if (section.audioPath.isNotEmpty)
                        LearningAudioButton(
                          path: section.audioPath,
                          filled: true,
                          tooltip: t.playStory,
                        ),
                      const SizedBox(height: 12),
                      ResponsiveText(
                        section.text,
                        fontSize: 17,
                        weight: FontWeight.w700,
                        color: Appcolors.ktextdark,
                        height: 1.55,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 22),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isCompleting ? null : _completeReading,
                        icon: _isCompleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(t.doneReading),
                      ),
                    ),
                  ],
                ),
              ),
              ResponsiveSizedBox.height(2.2),
              LearningSectionHeader(title: t.vocabulary),
              ResponsiveSizedBox.height(1),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final word in _vocabularyWords(story.text))
                    Chip(label: Text(word)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _vocabularyWords(String text) {
    final words = text
        .split(RegExp(r'[^A-Za-z]+'))
        .map((word) => word.trim().toLowerCase())
        .where((word) => word.length > 3)
        .toSet()
        .take(6)
        .toList();

    return words.isEmpty ? [widget.story.title] : words;
  }
}
