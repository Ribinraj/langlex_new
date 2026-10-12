import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langlex_new_app/core/storage_keys.dart';
import 'package:langlex_new_app/core/widgets/app_shimmer.dart';
import 'package:langlex_new_app/core/app_toast.dart';
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
  static final _enabled = ValueNotifier(true);
  static ValueListenable<bool> get enabled => _enabled;
  static int _revision = 0;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled.value = prefs.getBool(StorageKeys.soundEffectsEnabled) ?? true;
    _revision++;
  }

  static Future<void> setEnabled(bool value) async {
    _enabled.value = value;
    _revision++;
    if (!value) {
      // These players belong only to decorative asset effects. Lesson audio
      // uses its own players and is never muted by this preference.
      await Future.wait(_players.values.map(_silence));
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(StorageKeys.soundEffectsEnabled, value)) {
      throw StateError('Could not save sound preference');
    }
  }

  static Future<void> _silence(AudioPlayer player) async {
    try {
      await player.setVolume(0);
      await player.stop();
    } catch (_) {
      // A player that has not finished initializing must not block settings.
    }
  }

  static Future<void> play(String assetPath) async {
    if (!_enabled.value || assetPath.trim().isEmpty) return;
    final revision = _revision;
    final player = _players.putIfAbsent(assetPath, AudioPlayer.new);
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.stop();
      if (!_enabled.value || revision != _revision) return;
      await player.setVolume(1);
      if (!_enabled.value || revision != _revision) return;
      await player.play(AssetSource(assetPath));
      if (!_enabled.value) await _silence(player);
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
    this.autoplayPath = '',
    this.active = true,
  });

  final String path;
  final String? tooltip;
  final bool filled;
  final String autoplayPath;
  final bool active;

  @override
  State<LearningAudioButton> createState() => _LearningAudioButtonState();
}

class _LearningAudioButtonState extends State<LearningAudioButton> {
  // Lesson clips share ownership, while decorative asset effects stay separate.
  static _LearningAudioButtonState? _activeButton;
  static Future<void>? _audioChanges;

  // Serialize native stop/resume calls, but never wait for another button's
  // network source load. A slow old clip cannot start after a newer selection.
  static Future<void> _changeAudio(Future<void> Function() change) {
    final operation = (_audioChanges ?? Future<void>.value()).then(
      (_) => change(),
    );
    final settled = operation.then<void>((_) {}, onError: (Object _) {});
    _audioChanges = settled;
    settled.then((_) {
      if (identical(_audioChanges, settled)) _audioChanges = null;
    });
    return operation;
  }

  AudioPlayer? _player;
  StreamSubscription<void>? _completion;
  bool _playing = false;
  int _playbackRequest = 0;
  Future<void> _pendingPlayback = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active && widget.autoplayPath.isNotEmpty) {
        _playPath(widget.autoplayPath, reportError: false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant LearningAudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active ||
        oldWidget.path != widget.path ||
        oldWidget.autoplayPath != widget.autoplayPath) {
      _playPath(widget.active ? widget.autoplayPath : '', reportError: false);
    }
  }

  @override
  void dispose() {
    _playbackRequest++;
    if (identical(_activeButton, this)) _activeButton = null;
    _completion?.cancel();
    _stopPlayback();
    _pendingPlayback.then((_) async {
      try {
        await _player?.dispose();
      } catch (_) {
        // The route can close while a native player is still loading.
      }
    });
    super.dispose();
  }

  Future<void> _stopPlayback() => _changeAudio(() async {
    if (mounted && _playing) setState(() => _playing = false);
    await _player?.stop();
  }).catchError((Object _) {});

  bool _isCurrent(int request) =>
      mounted &&
      widget.active &&
      request == _playbackRequest &&
      identical(_activeButton, this);

  AudioPlayer _getPlayer() {
    if (_player != null) return _player!;
    final player = _player = AudioPlayer();
    _completion = player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    return player;
  }

  Future<void> _play() => _playPath(widget.path);

  Future<void> _playPath(String path, {bool reportError = true}) {
    final request = ++_playbackRequest;
    final url = widget.active ? Endpoints.mediaUrl(path) : '';
    if (url.isEmpty) {
      if (identical(_activeButton, this)) _activeButton = null;
      return _stopPlayback();
    }
    final previous = _activeButton;
    _activeButton = this;
    if (previous != null && !identical(previous, this)) {
      previous._playbackRequest++;
      previous._stopPlayback();
    }
    // This button still serializes its own source changes. Other buttons can
    // take over immediately, even while this source is waiting on the network.
    _pendingPlayback = _pendingPlayback.then((_) async {
      if (!_isCurrent(request)) return;
      setState(() => _playing = true);
      try {
        final player = _getPlayer();
        await _changeAudio(() => player.stop());
        if (!_isCurrent(request)) return;
        await player.setSource(UrlSource(url));
        await _changeAudio(() async {
          if (_isCurrent(request)) await player.resume();
        });
      } catch (_) {
        if (_isCurrent(request)) {
          setState(() => _playing = false);
          if (reportError && mounted) {
            AppToast.error(context, 'This audio is currently unavailable.');
          }
        }
      }
    });
    return _pendingPlayback;
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = widget.active && widget.path.trim().isNotEmpty;
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
    if (loading) {
      return LayoutBuilder(
        builder: (context, constraints) => AppShimmer(
          child: SkeletonBlock(
            height: constraints.hasBoundedHeight ? constraints.maxHeight : 60,
            width: constraints.hasBoundedWidth ? constraints.maxWidth : 60,
          ),
        ),
      );
    }
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
      ],
    );
  }
}
