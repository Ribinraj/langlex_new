import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';
import 'package:langlex_new_app/features/progress/progress_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/app_toast.dart';
import 'package:langlex_new_app/features/learning/pages/quiz_practice_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';

class QuizSetCard extends StatefulWidget {
  const QuizSetCard({
    super.key,
    required this.topic,
    required this.homeLanguage,
    required this.index,
  });
  final Map<String, dynamic> topic;
  final String homeLanguage;
  final int index;

  @override
  State<QuizSetCard> createState() => _QuizSetCardState();
}

class _QuizSetCardState extends State<QuizSetCard> {
  bool _loading = false;
  bool _premiumUnlocked = false;
  bool get _premium =>
      widget.topic['show_plan']?.toString().toLowerCase() == 'premium';
  bool get _locked =>
      _premium && !_premiumUnlocked && widget.topic['locked'] != false;

  Future<bool> _ensurePremium(LearningRepository repository) async {
    if (await repository.hasPremiumAccess()) {
      if (mounted) setState(() => _premiumUnlocked = true);
      return mounted;
    }
    final plans = await repository.fetchPlans();
    if (!mounted) return false;
    final upgraded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentCheckoutPage(
          plans: plans,
          homeLanguage: widget.homeLanguage,
        ),
      ),
    );
    if (upgraded != true || !mounted) return false;
    final allowed = await repository.hasPremiumAccess();
    if (mounted) setState(() => _premiumUnlocked = allowed);
    return allowed && mounted;
  }

  Future<void> _start() async {
    if (_loading) return;
    setState(() => _loading = true);
    final t = AppLocalizations(widget.homeLanguage);
    try {
      final repository = context.read<LearningRepository>();
      Future<List<QuizQuestion>> loadQuestions() =>
          repository.fetchQuizTopicQuestions(
            language: widget.topic['language'].toString(),
            topic: widget.topic['topic'].toString(),
          );
      List<QuizQuestion> questions;
      try {
        questions = await loadQuestions();
      } on ApiException catch (error) {
        // The administrator may have changed access since this card loaded.
        if (error.statusCode != 403 ||
            !error.message.toLowerCase().contains('premium')) {
          rethrow;
        }
        if (!await _ensurePremium(repository)) return;
        questions = await loadQuestions();
      }
      if (!mounted) return;
      // The server is authoritative, including when a Premium topic becomes Free.
      if (_premium) setState(() => _premiumUnlocked = true);
      if (questions.isEmpty) {
        AppToast.error(context, t.noQuizQuestions);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuizPracticePage(
            questions: questions,
            homeLanguage: widget.homeLanguage,
            contentKey: 'quiz-topic-${widget.topic['id']}',
          ),
        ),
      );
    } catch (_) {
      if (mounted) AppToast.error(context, t.couldNotLoadLearningContent);
    } finally {
      if (mounted) {
        context.read<LearningRepository>().progress.refresh(
          widget.homeLanguage,
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(widget.homeLanguage);
    final title = widget.topic['topic']?.toString().trim() ?? '';
    final count = widget.topic['question_count'] ?? 0;
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
    final accent = accents[widget.index % accents.length];
    final surface = surfaces[widget.index % surfaces.length];
    return Container(
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: .14)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      (widget.index + 1).toString().padLeft(2, '0'),
                      textScaler: TextScaler.noScaling,
                      style: GoogleFonts.montserrat(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.topic['language']}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title.isEmpty ? t.quizPractice : title,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: Appcolors.ktextdark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  '$count questions${_premium ? ' · ${t.premium}' : ''}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Appcolors.ktextgreycolor,
                  ),
                ),
              ],
            ),
            TopicProgressBadge(
              type: 'quiz',
              contentKey: 'quiz-topic-${widget.topic['id']}',
              language: '${widget.topic['language']}',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading || title.isEmpty ? null : _start,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Appcolors.kwhitecolor,
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loading
                          ? t.loading
                          : _locked
                          ? t.premium
                          : 'Start quiz · $count questions',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
