import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:langlex_new_app/core/appconstants.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/core/routes/approutes.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_event.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoRotateAnimation;
  late final Animation<double> _progressAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    _logoRotateAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.12, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      context.read<AuthBloc>().add(const CheckLoginStatusEvent());
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: const Color(0xFF78CFFF),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF58BFFF),
                  Color(0xFFA9ECFF),
                  Color(0xFF82D657),
                ],
                stops: [0, 0.78, 1],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _SplashArtwork(
                fadeAnimation: _fadeAnimation,
                logoSlideAnimation: _logoSlideAnimation,
                logoScaleAnimation: _logoScaleAnimation,
                logoRotateAnimation: _logoRotateAnimation,
                progressAnimation: _progressAnimation,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashArtwork extends StatelessWidget {
  const _SplashArtwork({
    required this.fadeAnimation,
    required this.logoSlideAnimation,
    required this.logoScaleAnimation,
    required this.logoRotateAnimation,
    required this.progressAnimation,
  });

  final Animation<double> fadeAnimation;
  final Animation<Offset> logoSlideAnimation;
  final Animation<double> logoScaleAnimation;
  final Animation<double> logoRotateAnimation;
  final Animation<double> progressAnimation;

  static const double _artAspectRatio = 878 / 1790;
  static const String _semanticLabel =
      'LangLex Kids. Learn languages, one adventure at a time.';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;

    if (isCompact) {
      return SizedBox.expand(
        child: _SplashScene(
          fadeAnimation: fadeAnimation,
          logoSlideAnimation: logoSlideAnimation,
          logoScaleAnimation: logoScaleAnimation,
          logoRotateAnimation: logoRotateAnimation,
          progressAnimation: progressAnimation,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: size.height),
        child: AspectRatio(
          aspectRatio: _artAspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 42,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: _SplashScene(
                fadeAnimation: fadeAnimation,
                logoSlideAnimation: logoSlideAnimation,
                logoScaleAnimation: logoScaleAnimation,
                logoRotateAnimation: logoRotateAnimation,
                progressAnimation: progressAnimation,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashScene extends StatelessWidget {
  const _SplashScene({
    required this.fadeAnimation,
    required this.logoSlideAnimation,
    required this.logoScaleAnimation,
    required this.logoRotateAnimation,
    required this.progressAnimation,
  });

  final Animation<double> fadeAnimation;
  final Animation<Offset> logoSlideAnimation;
  final Animation<double> logoScaleAnimation;
  final Animation<double> logoRotateAnimation;
  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final logoSize = (width * 0.29).clamp(100.0, 136.0);
        final topOffset = math.max(mediaPadding.top + 2, height * 0.026);
        final bottomOffset = math.max(mediaPadding.bottom + 28, height * 0.04);

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppConstants.splashPageArt,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                semanticLabel: _SplashArtwork._semanticLabel,
              ),
            ),
            Positioned(
              top: topOffset,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: logoScaleAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: fadeAnimation.value.clamp(0.0, 1.0),
                    child: SlideTransition(
                      position: logoSlideAnimation,
                      child: Transform.rotate(
                        angle: logoRotateAnimation.value,
                        child: Transform.scale(
                          scale: logoScaleAnimation.value,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: Center(child: _LogoMark(size: logoSize)),
              ),
            ),
            Positioned(
              left: width * 0.12,
              right: width * 0.12,
              bottom: bottomOffset,
              child: _LoadingFooter(
                fadeAnimation: fadeAnimation,
                progressAnimation: progressAnimation,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        AppConstants.appLogo,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.translate_rounded,
            color: Appcolors.kprimarycolor,
            size: 52,
          );
        },
      ),
    );
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter({
    required this.fadeAnimation,
    required this.progressAnimation,
  });

  final Animation<double> fadeAnimation;
  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        decoration: BoxDecoration(
          color: Appcolors.kwhitecolor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Appcolors.kblackcolor.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFC857),
                  size: 28,
                ),
                const SizedBox(width: 22),
                Flexible(
                  child: ResponsiveText(
                    'Getting your lessons ready...',
                    fontSize: 14,
                    weight: FontWeight.w700,
                    color: Appcolors.kprimarycolor.withValues(alpha: 0.82),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProgressTrack(progressAnimation: progressAnimation),
          ],
        ),
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.progressAnimation});

  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressAnimation,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 12,
            color: Appcolors.kprimaryLightColor.withValues(alpha: 0.62),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progressAnimation.value.clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB55BE8), Appcolors.kprimarycolor],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
