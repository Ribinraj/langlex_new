import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
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

class PhonicsPracticePage extends StatefulWidget {
  const PhonicsPracticePage({
    super.key,
    required this.phonics,
    required this.homeLanguage,
    this.contentKey,
    this.initialIndex,
  });

  final List<PhonicsItem> phonics;
  final String homeLanguage;
  final String? contentKey;
  final int? initialIndex;

  @override
  State<PhonicsPracticePage> createState() => _PhonicsPracticePageState();
}

class _PhonicsPracticePageState extends State<PhonicsPracticePage> {
  late final PageController _pageController;
  int _selectedIndex = 0;
  bool _interacted = false;
  bool _audioReady = false;
  int _audioSession = 0;

  String get _contentKey {
    final language = widget.phonics.isEmpty
        ? widget.homeLanguage
        : widget.phonics.first.language;
    return widget.contentKey ?? 'phonics-$language';
  }

  @override
  void initState() {
    super.initState();
    _audioReady = widget.initialIndex != null;
    _selectedIndex = widget.phonics.isEmpty
        ? 0
        : (widget.initialIndex ?? 0).clamp(0, widget.phonics.length - 1);
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSavedProgress();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (widget.phonics.isEmpty) return;
    final nextIndex = index.clamp(0, widget.phonics.length - 1);
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  String _itemKey(PhonicsItem item, int index) {
    return item.id > 0
        ? 'phonics-${item.id}'
        : 'phonics-${item.language}-${item.word.toLowerCase()}-$index';
  }

  Future<void> _loadSavedProgress() async {
    if (widget.phonics.isEmpty) return;
    if (widget.initialIndex == null) {
      try {
        final progress = await context
            .read<LearningRepository>()
            .getContentProgress(
              contentType: 'phonics',
              contentKey: _contentKey,
            );
        if (!mounted || _interacted) return;
        final resumeIndex = progress.position.clamp(
          0,
          widget.phonics.length - 1,
        );
        setState(() => _selectedIndex = resumeIndex);
        _pageController.jumpToPage(resumeIndex);
      } catch (_) {
        // Practice remains available offline.
      }
    }
    if (mounted && !_interacted) {
      setState(() => _audioReady = true);
      _recordProgress(_selectedIndex);
    }
  }

  Future<void> _recordProgress(int index) async {
    if (index < 0 || index >= widget.phonics.length) return;
    try {
      await context.read<LearningRepository>().recordContentItem(
        contentType: 'phonics',
        contentKey: _contentKey,
        itemKey: _itemKey(widget.phonics[index], index),
        position: index,
        totalItems: widget.phonics.length,
        status: index == widget.phonics.length - 1
            ? 'completed'
            : 'in_progress',
      );
    } catch (_) {
      // A failed progress sync must not interrupt reading or audio playback.
    }
  }

  Future<void> _restartPractice() async {
    _interacted = true;
    try {
      await context.read<LearningRepository>().restartContentProgress(
        contentType: 'phonics',
        contentKey: _contentKey,
      );
    } catch (_) {
      // Local restart still works if the network is unavailable.
    }
    if (!mounted) return;
    setState(() {
      _selectedIndex = 0;
      _audioReady = true;
      _audioSession++;
    });
    _pageController.jumpToPage(0);
    _recordProgress(0);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.phonics;
    final t = AppLocalizations(widget.homeLanguage);

    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,

      body: SafeArea(
        top: false,
        child: ResponsiveUtils.constrainWidth(
          context: context,
          maxWidth: 720,
          child: items.isEmpty
              ? FlowScrollView(
                  header: FlowPageHeader(
                    title: t.phonics,
                    actions: [
                      IconButton(
                        onPressed: items.isEmpty ? null : _restartPractice,
                        tooltip: t.restartPractice,
                        icon: const Icon(Icons.replay_rounded),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: _EmptyPhonicsCard(t: t),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: items.length,
                        onPageChanged: (index) {
                          _interacted = true;
                          setState(() {
                            _selectedIndex = index;
                            _audioReady = true;
                          });
                          _recordProgress(index);
                        },
                        itemBuilder: (context, index) => FlowScrollView(
                          header: FlowPageHeader(
                            title: t.phonics,
                            actions: [
                              IconButton(
                                onPressed: items.isEmpty
                                    ? null
                                    : _restartPractice,
                                tooltip: t.restartPractice,
                                icon: const Icon(Icons.replay_rounded),
                              ),
                            ],
                            footer: LearningSectionHeader(
                              title: t.soundCardProgress(
                                _selectedIndex + 1,
                                items.length,
                              ),
                            ),
                          ),
                          key: PageStorageKey(
                            'phonics-card-${items[index].id}-$index',
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: _PhonicsCard(
                            key: ValueKey(
                              'phonics-audio-$index-$_audioSession',
                            ),
                            item: items[index],
                            t: t,
                            active: _audioReady && index == _selectedIndex,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: _PhonicsControls(
                        currentIndex: _selectedIndex,
                        itemCount: items.length,
                        t: t,
                        onPrevious: () => _goTo(_selectedIndex - 1),
                        onNext: () => _goTo(_selectedIndex + 1),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PhonicsCard extends StatelessWidget {
  const _PhonicsCard({
    super.key,
    required this.item,
    required this.t,
    required this.active,
  });

  final PhonicsItem item;
  final AppLocalizations t;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    const accent = Appcolors.kdashboardTeal;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Appcolors.kauthDivider),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: LearningMediaImage(
              path: item.imagePath,
              fit: BoxFit.contain,
              accent: accent,
              width: double.infinity,
              borderRadius: 24,
            ),
          ),
          const SizedBox(height: 18),
          ResponsiveText(
            item.word,
            fontSize: isMobile ? 36 : 48,
            weight: FontWeight.w900,
            color: Appcolors.ktextdark,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 10),
          ResponsiveText(
            item.sentence,
            fontSize: isMobile ? 20 : 24,
            weight: FontWeight.w900,
            color: Appcolors.kdashboardMutedText,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = [
                _AudioAction(
                  label: t.word,
                  path: item.wordAudioPath,
                  autoplayPath: item.wordAudioPath,
                  active: active,
                  tooltip: t.playWord(item.word),
                ),
                _AudioAction(
                  label: t.sentence,
                  path: item.sentenceAudioPath,
                  active: active,
                  tooltip: t.playSentence,
                ),
              ];
              if (constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(16) > 22) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    actions[0],
                    const SizedBox(height: 10),
                    actions[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: actions[0]),
                  const SizedBox(width: 12),
                  Expanded(child: actions[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          ResponsiveText(
            [
              item.language,
              item.level,
              item.courseName,
              item.subcategory,
            ].where((value) => value.trim().isNotEmpty).toSet().join(' • '),
            fontSize: 12,
            weight: FontWeight.w800,
            color: Appcolors.kdashboardMutedText,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

class _AudioAction extends StatelessWidget {
  const _AudioAction({
    required this.label,
    required this.path,
    required this.tooltip,
    required this.active,
    this.autoplayPath = '',
  });

  final String label;
  final String path;
  final String tooltip;
  final bool active;
  final String autoplayPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Appcolors.kauthSoftGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.kdashboardTeal.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LearningAudioButton(
            path: path,
            tooltip: tooltip,
            filled: true,
            autoplayPath: autoplayPath,
            active: active,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ResponsiveText(
              label,
              fontSize: 15,
              weight: FontWeight.w900,
              color: Appcolors.kdashboardTeal,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonicsControls extends StatelessWidget {
  const _PhonicsControls({
    required this.currentIndex,
    required this.itemCount,
    required this.t,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentIndex;
  final int itemCount;
  final AppLocalizations t;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: currentIndex == 0 ? null : onPrevious,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: t.previousSound,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            label: t.soundCardProgress(currentIndex + 1, itemCount),
            child: LinearProgressIndicator(
              value: (currentIndex + 1) / itemCount,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
              color: Appcolors.kdashboardTeal,
              backgroundColor: Appcolors.kauthDivider,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: currentIndex == itemCount - 1 ? null : onNext,
          icon: const Icon(Icons.arrow_forward_rounded),
          tooltip: t.nextSound,
        ),
      ],
    );
  }
}

class _EmptyPhonicsCard extends StatelessWidget {
  const _EmptyPhonicsCard({required this.t});
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    kind: EmptyStateKind.sounds,
    title: t.nothingHereYet,
    message: t.noPhonics,
    actionLabel: Navigator.of(context).canPop() ? t.goBack : null,
    onAction: Navigator.of(context).canPop()
        ? () => Navigator.of(context).maybePop()
        : null,
  );
}
