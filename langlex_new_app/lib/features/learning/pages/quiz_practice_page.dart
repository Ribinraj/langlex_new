import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';
import 'package:langlex_new_app/widgets/custom_background.dart';

class QuizPracticePage extends StatefulWidget {
  const QuizPracticePage({
    super.key,
    required this.questions,
    required this.homeLanguage,
    this.contentKey,
  });

  final List<QuizQuestion> questions;
  final String homeLanguage;
  final String? contentKey;

  @override
  State<QuizPracticePage> createState() => _QuizPracticePageState();
}

class _QuizPracticePageState extends State<QuizPracticePage> {
  final Set<String> _dailyRecordedQuestionKeys = {};
  int _questionIndex = 0;
  int _celebrationTrigger = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _isComplete = false;

  String get _contentKey =>
      widget.contentKey ?? 'quiz-${widget.homeLanguage.toLowerCase()}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSavedProgress();
    });
  }

  String _questionKey(QuizQuestion question) {
    return question.id > 0
        ? 'quiz-${question.id}'
        : 'quiz-${question.language}-${question.topic}-${question.question.hashCode}';
  }

  void _recordQuizProgress(QuizQuestion question, String option) {
    final questionKey = _questionKey(question);

    if (_dailyRecordedQuestionKeys.add(questionKey)) {
      context.read<LearningBloc>().add(
        RecordDailyProgressEvent(
          activityType: 'quiz',
          activityKey: questionKey,
          estimatedMinutes: 2,
        ),
      );
    }

    context.read<LearningRepository>().recordContentItem(
      contentType: 'quiz',
      contentKey: _contentKey,
      itemKey: questionKey,
      position: _questionIndex,
      totalItems: widget.questions.length,
      status: _questionIndex == widget.questions.length - 1
          ? 'completed'
          : 'in_progress',
      isCorrect: option == question.correctAnswer,
    );
  }

  void _answerQuestion(QuizQuestion question, String option) {
    if (_selectedAnswer != null) return;

    LearningAssetSound.playQuizOptionSelect();
    _recordQuizProgress(question, option);
    final answeredCorrectly = option == question.correctAnswer;
    setState(() {
      _selectedAnswer = option;
      if (answeredCorrectly) {
        _score++;
        _celebrationTrigger++;
      }
    });
    Future<void>.delayed(
      const Duration(milliseconds: 140),
      () => LearningAssetSound.play(
        answeredCorrectly
            ? KidsLearningAssets.quizCorrectSound
            : KidsLearningAssets.quizWrongSound,
      ),
    );
  }

  Future<void> _loadSavedProgress() async {
    if (widget.questions.isEmpty) return;
    try {
      final progress = await context
          .read<LearningRepository>()
          .getContentProgress(contentType: 'quiz', contentKey: _contentKey);
      if (!mounted) return;

      if (progress.restartSession) {
        setState(() {
          _score = 0;
          _questionIndex = 0;
          _isComplete = false;
        });
        return;
      }

      final firstUnanswered = widget.questions.indexWhere(
        (question) =>
            !progress.completedItemKeys.contains(_questionKey(question)),
      );
      setState(() {
        _score = progress.score;
        if (firstUnanswered == -1 && widget.questions.isNotEmpty) {
          _isComplete = true;
        } else if (firstUnanswered > 0) {
          _questionIndex = firstUnanswered;
        }
      });
    } catch (_) {
      // Resume should never block practice.
    }
  }

  void _goNext() {
    final isLastQuestion = _questionIndex == widget.questions.length - 1;
    LearningAssetSound.play(
      isLastQuestion
          ? KidsLearningAssets.quizFinishSound
          : KidsLearningAssets.quizNextSound,
    );
    setState(() {
      if (isLastQuestion) {
        _isComplete = true;
        return;
      }
      _selectedAnswer = null;
      _questionIndex++;
    });
  }

  void _restartQuiz() {
    LearningAssetSound.playTap();
    context.read<LearningRepository>().restartContentProgress(
      contentType: 'quiz',
      contentKey: _contentKey,
    );
    setState(() {
      _dailyRecordedQuestionKeys.clear();
      _questionIndex = 0;
      _celebrationTrigger = 0;
      _score = 0;
      _selectedAnswer = null;
      _isComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(widget.homeLanguage);

    if (widget.questions.isEmpty) {
      return Scaffold(
        backgroundColor: Appcolors.kscreenWarmBackground,
        body: KidsBubbleBackground(
          baseColor: Appcolors.kscreenWarmBackground,
          child: SafeArea(
            child: Padding(
              padding: ResponsiveUtils.pagePadding(
                context,
                mobileHorizontalPercent: 5,
                tabletHorizontal: 42,
                desktopHorizontal: 56,
                top: 12,
                bottom: 36,
              ),
              child: Column(
                children: [
                  _QuizTopControls(t: t, onRestart: _restartQuiz),
                  const Spacer(),
                  ResponsiveText(
                    t.noQuizQuestions,
                    fontSize: 15,
                    weight: FontWeight.w800,
                    color: Appcolors.kdashboardMutedText,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isComplete) {
      return _QuizCompleteView(
        t: t,
        score: _score,
        total: widget.questions.length,
        onPracticeAgain: _restartQuiz,
      );
    }

    final question = widget.questions[_questionIndex];
    final isAnswered = _selectedAnswer != null;
    final isCorrect = _selectedAnswer == question.correctAnswer;
    final currentQuestionNumber = _questionIndex + 1;
    final totalQuestions = widget.questions.length;
    final progressValue = currentQuestionNumber / totalQuestions;
    final nextLabel = _questionIndex == widget.questions.length - 1
        ? t.quizComplete
        : t.nextQuestion;

    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      body: KidsBubbleBackground(
        baseColor: Appcolors.kscreenWarmBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveUtils.pagePadding(
              context,
              mobileHorizontalPercent: 5,
              tabletHorizontal: 42,
              desktopHorizontal: 56,
              top: 12,
              bottom: 36,
            ),
            child: ResponsiveUtils.constrainWidth(
              context: context,
              maxWidth: 680,
              child: AnimatedSwitcher(
                duration: AppMotion.slow,
                switchInCurve: AppMotion.standardCurve,
                switchOutCurve: Curves.easeInCubic,
                child: Column(
                  key: ValueKey(_questionIndex),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuizTopControls(t: t, onRestart: _restartQuiz),
                    const SizedBox(height: 10),
                    StaggeredEntrance(
                      index: 1,
                      child: _QuizQuestionCard(
                        question: question,
                        progressValue: progressValue,
                        currentQuestionNumber: currentQuestionNumber,
                        totalQuestions: totalQuestions,
                        isAnswered: isAnswered,
                        isCorrect: isCorrect,
                        selectedAnswer: _selectedAnswer,
                        onAnswer: (option) => _answerQuestion(question, option),
                        onNext: _goNext,
                        nextLabel: nextLabel,
                        feedbackMessage: isCorrect
                            ? question.feedback
                            : question.wrongFeedback,
                        celebrationTrigger: _celebrationTrigger,
                        t: t,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizTopControls extends StatelessWidget {
  const _QuizTopControls({required this.t, required this.onRestart});

  final AppLocalizations t;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundQuizButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            LearningAssetSound.playTap();
            Navigator.of(context).maybePop();
          },
        ),
        Expanded(
          child: ResponsiveText(
            t.quizPractice,
            fontSize: 18,
            weight: FontWeight.w900,
            color: Appcolors.ktextdark,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        _RoundQuizButton(
          tooltip: t.restartPractice,
          icon: Icons.replay_rounded,
          onPressed: onRestart,
        ),
      ],
    );
  }
}

class _RoundQuizButton extends StatelessWidget {
  const _RoundQuizButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Appcolors.kwhitecolor.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Appcolors.ktextdark, size: 23),
          ),
        ),
      ),
    );
  }
}

class _QuizQuestionCard extends StatelessWidget {
  const _QuizQuestionCard({
    required this.question,
    required this.progressValue,
    required this.currentQuestionNumber,
    required this.totalQuestions,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedAnswer,
    required this.onAnswer,
    required this.onNext,
    required this.nextLabel,
    required this.feedbackMessage,
    required this.celebrationTrigger,
    required this.t,
  });

  final QuizQuestion question;
  final double progressValue;
  final int currentQuestionNumber;
  final int totalQuestions;
  final bool isAnswered;
  final bool isCorrect;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswer;
  final VoidCallback onNext;
  final String nextLabel;
  final String feedbackMessage;
  final int celebrationTrigger;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Appcolors.kwhitecolor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.10),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TopicChip(
                      icon: Icons.school_rounded,
                      label: question.language,
                      color: Appcolors.kdashboardTeal,
                      backgroundColor: Appcolors.kauthSoftGreen,
                    ),
                    _TopicChip(
                      icon: Icons.category_rounded,
                      label: question.topic,
                      color: Appcolors.kprimarycolor,
                      backgroundColor: Appcolors.ksoftPrimarySurface,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _QuestionCountPill(
                label: t.questionProgress(
                  currentQuestionNumber,
                  totalQuestions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AnimatedProgressTrack(value: progressValue),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Appcolors.kdashboardSoftSurface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Appcolors.kauthDivider),
            ),
            child: ResponsiveText(
              question.question,
              fontSize: 20,
              weight: FontWeight.w900,
              color: Appcolors.ktextdark,
              overflow: TextOverflow.visible,
              height: 1.14,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < question.options.length; index++) ...[
            StaggeredEntrance(
              index: index + 2,
              offset: const Offset(0, 0.04),
              child: _QuizOptionTile(
                option: question.options[index],
                optionIndex: index,
                selected: selectedAnswer == question.options[index],
                correct:
                    isAnswered &&
                    question.options[index] == question.correctAnswer,
                answered: isAnswered,
                onTap: () => onAnswer(question.options[index]),
              ),
            ),
            if (index != question.options.length - 1) const SizedBox(height: 8),
          ],
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.standardCurve,
            child: isAnswered
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: CelebrationBurst(
                      trigger: isCorrect ? celebrationTrigger : 0,
                      color: Appcolors.kmetricInventory,
                      child: _QuizFeedbackPanel(
                        isCorrect: isCorrect,
                        message: feedbackMessage,
                        onNext: onNext,
                        nextLabel: nextLabel,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _QuestionCountPill extends StatelessWidget {
  const _QuestionCountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Appcolors.ksoftCoralSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Appcolors.kmetricInventory.withValues(alpha: 0.24),
        ),
      ),
      child: ResponsiveText(
        label,
        fontSize: 10,
        weight: FontWeight.w900,
        color: Appcolors.kmetricInventory,
      ),
    );
  }
}

class _AnimatedProgressTrack extends StatelessWidget {
  const _AnimatedProgressTrack({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOffset = constraints.maxWidth > 24
            ? constraints.maxWidth - 24
            : 0.0;
        final starOffset = (constraints.maxWidth * value - 12).clamp(
          0.0,
          maxOffset,
        );

        return SizedBox(
          height: 24,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor: Appcolors.ksoftPrimarySurface,
                  valueColor: const AlwaysStoppedAnimation(
                    Appcolors.kprimarycolor,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: AppMotion.normal,
                curve: AppMotion.playfulCurve,
                left: starOffset,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Appcolors.kmetricInventory,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Appcolors.kwhitecolor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuizCompleteView extends StatelessWidget {
  const _QuizCompleteView({
    required this.t,
    required this.score,
    required this.total,
    required this.onPracticeAgain,
  });

  final AppLocalizations t;
  final int score;
  final int total;
  final VoidCallback onPracticeAgain;

  @override
  Widget build(BuildContext context) {
    final percentScore = total == 0 ? 0.0 : score / total;

    return Scaffold(
      backgroundColor: Appcolors.kscreenWarmBackground,
      appBar: AppBar(title: Text(t.quizComplete)),
      body: KidsBubbleBackground(
        baseColor: Appcolors.kscreenWarmBackground,
        child: SingleChildScrollView(
          padding: ResponsiveUtils.pagePadding(
            context,
            mobileHorizontalPercent: 6,
            tabletHorizontal: 42,
            desktopHorizontal: 56,
            top: 32,
            bottom: 36,
          ),
          child: ResponsiveUtils.constrainWidth(
            context: context,
            maxWidth: 640,
            child: CelebrationBurst(
              trigger: score + total + 1,
              color: Appcolors.kmetricInventory,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Appcolors.kwhitecolor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Appcolors.kprimarycolor.withValues(alpha: 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GentleFloat(
                      distance: 7,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Appcolors.kmetricInventorySurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Appcolors.kmetricInventory.withValues(
                              alpha: 0.24,
                            ),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Appcolors.kmetricInventory,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ResponsiveText(
                      t.greatJob,
                      fontSize: 27,
                      weight: FontWeight.w900,
                      color: Appcolors.ktextdark,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 8),
                    ResponsiveText(
                      t.quizScore(score, total),
                      fontSize: 15,
                      weight: FontWeight.w800,
                      color: Appcolors.kdashboardMutedText,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 20),
                    _CompletionMeter(value: percentScore),
                    ResponsiveSizedBox.height(2.8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () {
                          LearningAssetSound.playTap();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.home_rounded),
                        label: Text(t.backHome),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: onPracticeAgain,
                        icon: const Icon(Icons.replay_rounded),
                        label: Text(t.practiceAgain),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.option,
    required this.optionIndex,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onTap,
  });

  final String option;
  final int optionIndex;
  final bool selected;
  final bool correct;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColors = [
      Appcolors.kprimarycolor,
      Appcolors.kdashboardTeal,
      Appcolors.kmetricInventory,
      Appcolors.kredcolor,
    ];
    final surfaceColors = [
      Appcolors.ksoftPrimarySurface,
      Appcolors.kauthSoftGreen,
      Appcolors.ksoftCoralSurface,
      Appcolors.kmetricLowStockSurface,
    ];
    final accent = accentColors[optionIndex % accentColors.length];
    final restingSurface = surfaceColors[optionIndex % surfaceColors.length]
        .withValues(alpha: 0.48);
    final wrong = answered && selected && !correct;
    final borderColor = correct
        ? Appcolors.kdashboardTeal
        : wrong
        ? Appcolors.kredcolor
        : selected
        ? accent
        : accent.withValues(alpha: 0.34);
    final icon = correct
        ? Icons.check_circle_rounded
        : wrong
        ? Icons.cancel_rounded
        : selected
        ? Icons.radio_button_checked_rounded
        : Icons.radio_button_unchecked_rounded;

    return PressableScale(
      enabled: !answered,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: answered ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.standardCurve,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: correct
                  ? Appcolors.kauthSoftGreen
                  : wrong
                  ? Appcolors.kmetricLowStockSurface
                  : selected
                  ? restingSurface.withValues(alpha: 0.9)
                  : restingSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: selected || correct ? 2 : 1.2,
              ),
              boxShadow: selected || correct
                  ? [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedScale(
                  duration: AppMotion.normal,
                  curve: AppMotion.playfulCurve,
                  scale: selected || correct ? 1.12 : 1,
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.78),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: borderColor, size: 21),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ResponsiveText(
                    option,
                    fontSize: 13.5,
                    weight: FontWeight.w800,
                    color: Appcolors.ktextdark,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizFeedbackPanel extends StatelessWidget {
  const _QuizFeedbackPanel({
    required this.isCorrect,
    required this.message,
    required this.onNext,
    required this.nextLabel,
  });

  final bool isCorrect;
  final String message;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Appcolors.kdashboardTeal : Appcolors.kredcolor;
    final surface = isCorrect
        ? Appcolors.kauthSoftGreen
        : Appcolors.kmetricLowStockSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedScale(
                duration: AppMotion.normal,
                curve: AppMotion.playfulCurve,
                scale: isCorrect && !motionDisabled(context) ? 1.12 : 1,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Appcolors.kwhitecolor.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_rounded : Icons.lightbulb_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResponsiveText(
                  message,
                  fontSize: 12.5,
                  weight: FontWeight.w800,
                  color: Appcolors.ktextdark,
                  overflow: TextOverflow.visible,
                  height: 1.22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                nextLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: ResponsiveText(
              label,
              fontSize: 10.5,
              weight: FontWeight.w900,
              color: color,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionMeter extends StatelessWidget {
  const _CompletionMeter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Appcolors.kdashboardSoftSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: List.generate(5, (index) {
          final filled = value >= (index + 1) / 5;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 4 ? 0 : 8),
              child: AnimatedContainer(
                duration: AppMotion.normal,
                curve: AppMotion.standardCurve,
                height: 12,
                decoration: BoxDecoration(
                  color: filled
                      ? Appcolors.kmetricInventory
                      : Appcolors.kwhitecolor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
