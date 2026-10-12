import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

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
  int _questionIndex = 0;
  int _celebrationTrigger = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _isComplete = false;
  int _interactionRevision = 0;
  final Set<String> _answeredQuestionKeys = {};

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

    context
        .read<LearningRepository>()
        .recordContentItem(
          contentType: 'quiz',
          contentKey: _contentKey,
          itemKey: questionKey,
          position: _questionIndex,
          totalItems: widget.questions.length,
          status:
              widget.questions.every(
                (item) => _answeredQuestionKeys.contains(_questionKey(item)),
              )
              ? 'completed'
              : 'in_progress',
          isCorrect: option == question.correctAnswer,
          answer: option,
        )
        .then<void>((_) {}, onError: (Object _) {});
  }

  void _answerQuestion(QuizQuestion question, String option) {
    if (_selectedAnswer != null ||
        _isComplete ||
        !identical(question, widget.questions[_questionIndex])) {
      return;
    }
    _interactionRevision++;
    _answeredQuestionKeys.add(_questionKey(question));

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
    final revision = _interactionRevision;
    try {
      final progress = await context
          .read<LearningRepository>()
          .getContentProgress(contentType: 'quiz', contentKey: _contentKey);
      if (!mounted || revision != _interactionRevision) return;

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
        _answeredQuestionKeys.addAll(progress.completedItemKeys);
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

  void _goNext(QuizQuestion question) {
    if (_selectedAnswer == null ||
        _isComplete ||
        !identical(question, widget.questions[_questionIndex])) {
      return;
    }
    _interactionRevision++;
    var nextIndex = _questionIndex + 1;
    while (nextIndex < widget.questions.length &&
        _answeredQuestionKeys.contains(
          _questionKey(widget.questions[nextIndex]),
        )) {
      nextIndex++;
    }
    final isLastQuestion = nextIndex == widget.questions.length;
    LearningAssetSound.play(
      isLastQuestion
          ? KidsLearningAssets.quizFinishSound
          : KidsLearningAssets.quizNextSound,
    );
    setState(() {
      _selectedAnswer = null;
      if (isLastQuestion) {
        _isComplete = true;
        return;
      }
      _questionIndex = nextIndex;
    });
  }

  void _restartQuiz() {
    _interactionRevision++;
    _answeredQuestionKeys.clear();
    LearningAssetSound.playTap();
    context
        .read<LearningRepository>()
        .restartContentProgress(contentType: 'quiz', contentKey: _contentKey)
        .then<void>((_) {}, onError: (Object _) {});
    setState(() {
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
        body: Column(
          children: [
            _QuizTopControls(t: t, onRestart: _restartQuiz),
            Expanded(
              child: Padding(
                padding: ResponsiveUtils.pagePadding(
                  context,
                  mobileHorizontalPercent: 5,
                  tabletHorizontal: 42,
                  desktopHorizontal: 56,
                  bottom: 36,
                ),
                child: SingleChildScrollView(
                  child: AppEmptyState(
                    kind: EmptyStateKind.quizzes,
                    title: t.nothingHereYet,
                    message: t.noQuizQuestions,
                    actionLabel: Navigator.of(context).canPop()
                        ? t.goBack
                        : null,
                    onAction: Navigator.of(context).canPop()
                        ? () => Navigator.of(context).maybePop()
                        : null,
                  ),
                ),
              ),
            ),
          ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuizTopControls(t: t, onRestart: _restartQuiz),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: ResponsiveUtils.pagePadding(
                  context,
                  mobileHorizontalPercent: 5,
                  tabletHorizontal: 42,
                  desktopHorizontal: 56,
                ),
                child: ResponsiveUtils.constrainWidth(
                  context: context,
                  maxWidth: 680,
                  child: AnimatedSwitcher(
                    duration: AppMotion.slow,
                    switchInCurve: AppMotion.standardCurve,
                    switchOutCurve: Curves.easeInCubic,
                    child: StaggeredEntrance(
                      key: ValueKey(_questionIndex),
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
                        onNext: () => _goNext(question),
                        nextLabel: nextLabel,
                        feedbackMessage: isCorrect
                            ? question.feedback
                            : question.wrongFeedback,
                        celebrationTrigger: _celebrationTrigger,
                        t: t,
                      ),
                    ),
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

class _QuizTopControls extends StatelessWidget {
  const _QuizTopControls({required this.t, required this.onRestart});

  final AppLocalizations t;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 390;
        final contentWidth = width > 680 ? 680.0 : width;
        final sideInset = ((width - contentWidth) / 2) + (compact ? 22 : 28);
        final heroHeight = topInset + (compact ? 144.0 : 158.0);
        final tulipsWidth = compact ? 88.0 : 104.0;

        return SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Appcolors.klibrarySkyTop,
                        Appcolors.klibrarySkyMiddle,
                        Appcolors.klibrarySkyBottom,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -56,
                bottom: 36,
                child: _QuizCloudAsset(width: 104, opacity: 0.96),
              ),
              Positioned(
                right: -54,
                bottom: 38,
                child: _QuizCloudAsset(width: 112, opacity: 0.98),
              ),
              Positioned(
                right: sideInset + tulipsWidth + 16,
                top: topInset + 42,
                child: _QuizCloudAsset(width: 42, opacity: 0.52),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                height: 58,
                child: CustomPaint(painter: _QuizCloudBandPainter()),
              ),
              Positioned(
                left: sideInset,
                right: sideInset,
                top: topInset + 8,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _RoundQuizButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        icon: Icons.arrow_back_rounded,
                        onPressed: () {
                          LearningAssetSound.playTap();
                          Navigator.of(context).maybePop();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          t.quizPractice,
                          maxLines: 1,
                          style: GoogleFonts.montserrat(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Appcolors.kheroGreetingText,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _RoundQuizButton(
                        tooltip: t.restartPractice,
                        icon: Icons.restart_alt_rounded,
                        onPressed: onRestart,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: sideInset + 26,
                top: topInset + 50,
                child: SvgPicture.asset(
                  'assets/icons/tulips.svg',
                  width: tulipsWidth,
                  height: compact ? 92 : 112,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: sideInset + 40,
                top: topInset + 56,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: compact ? 11 : 13,
                  color: Appcolors.klibrarySparkle.withValues(alpha: 0.92),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                height: 42,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Appcolors.kscreenWarmBackground.withValues(alpha: 0),
                          Appcolors.kscreenWarmBackground,
                        ],
                      ),
                    ),
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

class _QuizCloudAsset extends StatelessWidget {
  const _QuizCloudAsset({required this.width, required this.opacity});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      KidsLearningAssets.cloudIcon,
      width: width,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        Appcolors.kwhitecolor.withValues(alpha: opacity),
        BlendMode.srcIn,
      ),
    );
  }
}

class _QuizCloudBandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Appcolors.kscreenWarmBackground.withValues(alpha: 0.98);
    final path = Path()
      ..moveTo(0, size.height * 0.54)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.08,
        size.width * 0.26,
        size.height * 0.78,
        size.width * 0.42,
        size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.12,
        size.width * 0.72,
        size.height * 0.70,
        size.width * 0.88,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.96,
        size.height * 0.20,
        size.width,
        size.height * 0.34,
        size.width,
        size.height * 0.40,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QuizCloudBandPainter oldDelegate) => false;
}

class _QuizSparkle extends StatelessWidget {
  const _QuizSparkle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star_rounded, color: color, size: size);
  }
}

class _QuizQuestionBubble extends StatelessWidget {
  const _QuizQuestionBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC79AFF), Appcolors.kprimarycolor],
        ),
        border: Border.all(color: Appcolors.kwhitecolor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.24),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.question_mark_rounded,
        color: Appcolors.kwhitecolor,
        size: 28,
      ),
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
      color: Appcolors.ktransparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Appcolors.kwhitecolor.withValues(alpha: 0.95),
              border: Border.all(
                color: Appcolors.kprimarycolor.withValues(alpha: 0.22),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kprimarycolor.withValues(alpha: 0.10),
                  blurRadius: 9,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Appcolors.kbottomNavActive, size: 24),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final cardPadding = compact
            ? const EdgeInsets.fromLTRB(12, 14, 12, 14)
            : const EdgeInsets.fromLTRB(18, 18, 18, 16);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: compact ? 18 : 30,
              bottom: -16,
              child: _QuizSparkle(
                color: Appcolors.kmetricInventory.withValues(alpha: 0.32),
                size: compact ? 24 : 30,
              ),
            ),
            Container(
              width: double.infinity,
              padding: cardPadding,
              decoration: BoxDecoration(
                color: Appcolors.kwhitecolor.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Appcolors.kwhitecolor, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: Appcolors.kmetricInventory.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Appcolors.kprimarycolor.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
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
                        icon: Icons.pets_rounded,
                        label: question.topic,
                        color: Appcolors.kprimarycolor,
                        backgroundColor: Appcolors.ksoftPrimarySurface,
                      ),
                      _QuestionCountPill(
                        label: t.questionProgress(
                          currentQuestionNumber,
                          totalQuestions,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 18),
                    child: _AnimatedProgressTrack(value: progressValue),
                  ),
                  const SizedBox(height: 14),
                  _QuizPromptPanel(
                    question: question,
                    selectedAnswer: selectedAnswer,
                    isAnswered: isAnswered,
                    onAnswer: onAnswer,
                  ),
                  AnimatedSize(
                    duration: AppMotion.normal,
                    curve: AppMotion.standardCurve,
                    child: isAnswered
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _QuizFeedbackPanel(
                              isCorrect: isCorrect,
                              message: feedbackMessage,
                              onNext: onNext,
                              nextLabel: nextLabel,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuizPromptPanel extends StatelessWidget {
  const _QuizPromptPanel({
    required this.question,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.onAnswer,
  });

  final QuizQuestion question;
  final String? selectedAnswer;
  final bool isAnswered;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Appcolors.ksoftPrimarySurface.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Appcolors.kprimaryLightColor.withValues(alpha: 0.92),
          width: 1.6,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _QuizQuestionBubble(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ResponsiveText(
                        question.question,
                        fontSize: 20,
                        minScale: 0.80,
                        weight: FontWeight.w900,
                        color: Appcolors.ktextdark,
                        overflow: TextOverflow.visible,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    LearningAudioButton(
                      path: question.questionAudioPath.isNotEmpty
                          ? question.questionAudioPath
                          : question.audioPath,
                      tooltip: 'Play question',
                    ),
                  ],
                ),
              ),
              if (question.imagePath.isNotEmpty) ...[
                LearningMediaImage(
                  path: question.imagePath,
                  accent: Appcolors.kprimarycolor,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
              ],
              if (question.audioPath.isNotEmpty &&
                  question.questionAudioPath.isNotEmpty)
                LearningAudioButton(
                  path: question.audioPath,
                  tooltip: 'Listen to the sound',
                ),
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
                if (index != question.options.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Appcolors.ksoftCoralSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Appcolors.kmetricInventory.withValues(alpha: 0.24),
        ),
      ),
      child: ResponsiveText(
        label,
        fontSize: 9.8,
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
        const knobSize = 21.0;
        final maxOffset = constraints.maxWidth > knobSize
            ? constraints.maxWidth - knobSize
            : 0.0;
        final starOffset = (constraints.maxWidth * value - (knobSize / 2))
            .clamp(0.0, maxOffset);

        return SizedBox(
          height: 21,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
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
                  width: knobSize,
                  height: knobSize,
                  decoration: const BoxDecoration(
                    color: Appcolors.kmetricInventory,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Appcolors.kwhitecolor,
                    size: 14,
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

      body: FlowScrollView(
        header: FlowPageHeader(title: t.quizComplete),
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
                  Container(
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
    const optionLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final accent = accentColors[optionIndex % accentColors.length];
    final restingSurface = surfaceColors[optionIndex % surfaceColors.length]
        .withValues(alpha: 0.56);
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
    final letter = optionIndex < optionLetters.length
        ? optionLetters[optionIndex]
        : '${optionIndex + 1}';

    return PressableScale(
      enabled: !answered,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: answered ? null : onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.standardCurve,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: correct
                  ? Appcolors.kauthSoftGreen
                  : wrong
                  ? Appcolors.kmetricLowStockSurface
                  : selected
                  ? restingSurface.withValues(alpha: 0.9)
                  : restingSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor,
                width: selected || correct || wrong ? 2 : 1.4,
              ),
              boxShadow: selected || correct
                  ? [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
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
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent.withValues(alpha: 0.86), accent],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Appcolors.kwhitecolor.withValues(alpha: 0.86),
                        width: 2.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ResponsiveText(
                        letter,
                        fontSize: 20,
                        weight: FontWeight.w900,
                        color: Appcolors.kwhitecolor,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ResponsiveText(
                    RegExp(
                          r'\.(mp3|wav|ogg|m4a)(\?.*)?$',
                          caseSensitive: false,
                        ).hasMatch(option)
                        ? 'Audio option $letter'
                        : option,
                    fontSize: 16,
                    minScale: 0.80,
                    weight: FontWeight.w900,
                    color: Appcolors.ktextdark,
                    overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(width: 8),
                if (RegExp(
                  r'\.(mp3|wav|ogg|m4a)(\?.*)?$',
                  caseSensitive: false,
                ).hasMatch(option))
                  LearningAudioButton(
                    path: option,
                    tooltip: 'Listen to option $letter',
                  ),
                Icon(icon, color: borderColor, size: 26),
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Appcolors.kwhitecolor.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_rounded : Icons.lightbulb_rounded,
                    color: color,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResponsiveText(
                  message,
                  fontSize: 12.2,
                  weight: FontWeight.w800,
                  color: Appcolors.ktextdark,
                  overflow: TextOverflow.visible,
                  height: 1.22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
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
    this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData? icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
              fontSize: 10,
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
