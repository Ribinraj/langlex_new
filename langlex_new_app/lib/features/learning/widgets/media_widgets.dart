import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/urls.dart';

class KidsLearningAssets {
  const KidsLearningAssets._();

  static const learnMascotImage = 'assets/images/kids_learning_rocket.png';
  static const magicBooksImage = 'assets/images/kids_open_book.png';
  static const wordStarsImage = 'assets/images/kids_word_star.png';
  static const schoolBackgroundImage =
      'assets/images/kids_school_background.png';
  static const kidsImage = 'assets/images/kids_image.png';
  static const pencilIcon = 'assets/icons/pencil_icon.svg';
  static const profileLionIcon = 'assets/icons/in-love.svg';
  static const crownIcon = 'assets/icons/crown.svg';
  static const trophyIcon = 'assets/icons/trophy.svg';
  static const rainbowIcon = 'assets/icons/rainbow.svg';
  static const questionIcon = 'assets/icons/question.svg';
  static const mentalHealthIcon = 'assets/icons/mental-health.svg';
  static const openBookIcon = 'assets/icons/open-book.svg';
  static const starIcon = 'assets/icons/star.svg';
  static const cloudIcon = 'assets/icons/cloud.svg';

  static const tapPopSound = 'sounds/kids_tap_pop.wav';
  static const successChimeSound = 'sounds/kids_lesson_success.wav';
  static const wordRevealSound = 'sounds/kids_word_reveal.wav';
  static const quizOptionSelectSound = 'sounds/quiz_option_select.wav';
  static const quizCorrectSound = 'sounds/quiz_correct.wav';
  static const quizWrongSound = 'sounds/quiz_wrong.wav';
  static const quizNextSound = 'sounds/quiz_next.wav';
  static const quizFinishSound = 'sounds/quiz_finish.wav';
  static const navLearnSound = 'sounds/nav_learn.wav';
  static const navLibrarySound = 'sounds/nav_library.wav';
  static const navPracticeSound = 'sounds/nav_practice.wav';
  static const navProfileSound = 'sounds/nav_profile.wav';
}

class LearningMediaImage extends StatelessWidget {
  const LearningMediaImage({
    super.key,
    required this.path,
    required this.accent,
    this.width,
    this.height,
    this.borderRadius = 18,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_rounded,
  });

  final String? path;
  final Color accent;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final url = Endpoints.mediaUrl(path ?? '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: accent.withValues(alpha: 0.18),
        child: url.isEmpty
            ? _FallbackImage(accent: accent, icon: fallbackIcon)
            : Image.network(
                url,
                fit: fit,
                errorBuilder: (_, _, _) =>
                    _FallbackImage(accent: accent, icon: fallbackIcon),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  if (frame == null) {
                    return _FallbackImage(
                      accent: accent,
                      icon: fallbackIcon,
                      loading: true,
                    );
                  }
                  return AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: child,
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _FallbackImage(
                    accent: accent,
                    icon: fallbackIcon,
                    loading: true,
                  );
                },
              ),
      ),
    );
  }
}

class LearningOptionalAssetImage extends StatelessWidget {
  const LearningOptionalAssetImage({
    super.key,
    required this.assetPath,
    required this.accent,
    required this.fallbackIcon,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final Color accent;
  final IconData fallbackIcon;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) {
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(fallbackIcon, color: accent, size: 36),
        );
      },
    );
  }
}

class LearningAssetSound {
  const LearningAssetSound._();

  static final Map<String, AudioPlayer> _players = {};

  static Future<void> play(String assetPath) async {
    if (assetPath.trim().isEmpty) return;

    final player = _players.putIfAbsent(assetPath, AudioPlayer.new);
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1);
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Asset sounds are decorative and should never interrupt learning.
    }
  }

  static Future<void> playTap() => play(KidsLearningAssets.tapPopSound);

  static Future<void> playReveal() => play(KidsLearningAssets.wordRevealSound);

  static Future<void> playQuizOptionSelect() =>
      play(KidsLearningAssets.quizOptionSelectSound);

  static Future<void> playQuizCorrect() =>
      play(KidsLearningAssets.quizCorrectSound);

  static Future<void> playQuizWrong() =>
      play(KidsLearningAssets.quizWrongSound);

  static Future<void> playQuizNext() => play(KidsLearningAssets.quizNextSound);

  static Future<void> playQuizFinish() =>
      play(KidsLearningAssets.quizFinishSound);

  static Future<void> playNavTab(int index) {
    final sounds = [
      KidsLearningAssets.successChimeSound,
      KidsLearningAssets.navLibrarySound,
      KidsLearningAssets.navPracticeSound,
      KidsLearningAssets.navProfileSound,
    ];
    final safeIndex = index.clamp(0, sounds.length - 1);
    return play(sounds[safeIndex]);
  }
}

class LearningAudioButton extends StatefulWidget {
  const LearningAudioButton({
    super.key,
    required this.path,
    this.tooltip,
    this.filled = false,
  });

  final String path;
  final String? tooltip;
  final bool filled;

  @override
  State<LearningAudioButton> createState() => _LearningAudioButtonState();
}

class _LearningAudioButtonState extends State<LearningAudioButton> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final url = Endpoints.mediaUrl(widget.path);
    if (url.isEmpty || _playing) return;

    setState(() => _playing = true);
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = widget.path.trim().isNotEmpty;
    final icon = _playing
        ? Icons.graphic_eq_rounded
        : hasAudio
        ? Icons.volume_up_rounded
        : Icons.volume_off_rounded;

    if (widget.filled) {
      return IconButton.filled(
        onPressed: hasAudio ? _play : null,
        icon: Icon(icon),
        tooltip: widget.tooltip ?? 'Play sound',
      );
    }

    return IconButton.filledTonal(
      onPressed: hasAudio ? _play : null,
      icon: Icon(icon),
      tooltip: widget.tooltip ?? 'Play sound',
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({
    required this.accent,
    required this.icon,
    this.loading = false,
  });

  final Color accent;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Appcolors.kwhitecolor.withValues(alpha: 0.72),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: accent, size: 34),
        ),
        if (loading)
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent.withValues(alpha: 0.72),
            ),
          ),
      ],
    );
  }
}
