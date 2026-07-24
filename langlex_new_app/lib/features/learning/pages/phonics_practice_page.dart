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
  });

  final List<PhonicsItem> phonics;
  final String homeLanguage;

  @override
  State<PhonicsPracticePage> createState() => _PhonicsPracticePageState();
}

class _PhonicsPracticePageState extends State<PhonicsPracticePage> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  String get _contentKey {
    final language = widget.phonics.isEmpty
        ? widget.homeLanguage
        : widget.phonics.first.language;
    return 'phonics-$language';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSavedProgress();
      _recordProgress(0);
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
    try {
      final progress = await context
          .read<LearningRepository>()
          .getContentProgress(contentType: 'phonics', contentKey: _contentKey);
      if (!mounted || progress.position <= 0) return;
      final resumeIndex = progress.position.clamp(0, widget.phonics.length - 1);
      setState(() => _selectedIndex = resumeIndex);
      _pageController.jumpToPage(resumeIndex);
      _recordProgress(resumeIndex);
    } catch (_) {
      // Resume should never block practice.
    }
  }

  void _recordProgress(int index) {
    if (index < 0 || index >= widget.phonics.length) return;
    context.read<LearningRepository>().recordContentItem(
      contentType: 'phonics',
      contentKey: _contentKey,
      itemKey: _itemKey(widget.phonics[index], index),
      position: index,
      totalItems: widget.phonics.length,
      status: index == widget.phonics.length - 1 ? 'completed' : 'in_progress',
    );
  }

  Future<void> _restartPractice() async {
    try {
      await context.read<LearningRepository>().restartContentProgress(
        contentType: 'phonics',
        contentKey: _contentKey,
      );
    } catch (_) {
      // Local restart still works if the network is unavailable.
    }
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
    _pageController.jumpToPage(0);
    _recordProgress(0);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.phonics;
    final t = AppLocalizations(widget.homeLanguage);

    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      appBar: AppBar(
        title: Text(t.phonics),
        actions: [
          IconButton(
            onPressed: items.isEmpty ? null : _restartPractice,
            tooltip: t.restartPractice,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
          maxWidth: 720,
          child: items.isEmpty
              ? _EmptyPhonicsCard(t: t)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LearningSectionHeader(
                      title: t.soundCardProgress(
                        _selectedIndex + 1,
                        items.length,
                      ),
                    ),
                    ResponsiveSizedBox.height(1.2),
                    SizedBox(
                      height: ResponsiveUtils.isMobile(context) ? 540 : 610,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: items.length,
                        onPageChanged: (index) {
                          setState(() => _selectedIndex = index);
                          _recordProgress(index);
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _PhonicsCard(item: items[index], t: t),
                          );
                        },
                      ),
                    ),
                    ResponsiveSizedBox.height(1.4),
                    _PhonicsControls(
                      currentIndex: _selectedIndex,
                      itemCount: items.length,
                      t: t,
                      onPrevious: () => _goTo(_selectedIndex - 1),
                      onNext: () => _goTo(_selectedIndex + 1),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PhonicsCard extends StatelessWidget {
  const _PhonicsCard({required this.item, required this.t});

  final PhonicsItem item;
  final AppLocalizations t;

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
          Expanded(
            child: LearningMediaImage(
              path: item.imagePath,
              accent: accent,
              width: double.infinity,
              borderRadius: 24,
            ),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: ResponsiveText(
              item.word,
              fontSize: isMobile ? 50 : 66,
              weight: FontWeight.w900,
              color: Appcolors.ktextdark,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(height: 10),
          ResponsiveText(
            item.sentence,
            fontSize: isMobile ? 22 : 27,
            weight: FontWeight.w900,
            color: Appcolors.kdashboardMutedText,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            maxLines: 3,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _AudioAction(
                  label: t.word,
                  path: item.wordAudioPath,
                  tooltip: t.playWord(item.word),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AudioAction(
                  label: t.sentence,
                  path: item.sentenceAudioPath,
                  tooltip: t.playSentence,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ResponsiveText(
            '${item.language} • ${item.level} • ${item.subcategory}',
            fontSize: 12,
            weight: FontWeight.w800,
            color: Appcolors.kdashboardMutedText,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            maxLines: 2,
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
  });

  final String label;
  final String path;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
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
          LearningAudioButton(path: path, tooltip: tooltip, filled: true),
          const SizedBox(width: 8),
          Flexible(
            child: ResponsiveText(
              label,
              fontSize: 15,
              weight: FontWeight.w900,
              color: Appcolors.kdashboardTeal,
              overflow: TextOverflow.visible,
              maxLines: 1,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(itemCount, (index) {
              final selected = index == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Appcolors.kdashboardTeal
                      : Appcolors.kauthDivider,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Appcolors.kauthDivider),
      ),
      child: ResponsiveText(
        t.noPhonics,
        fontSize: 15,
        weight: FontWeight.w800,
        color: Appcolors.kdashboardMutedText,
        textAlign: TextAlign.center,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
