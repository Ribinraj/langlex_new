import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoRotateAnimation;

  late final AnimationController _floatController;
  late final AnimationController _dotsController;

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

    _slideAnimation =
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

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

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
    _floatController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    final isMobile = ResponsiveUtils.isMobile(context);
    final logoSize = isMobile ? ResponsiveUtils.wp(30) : 148.0;
    final horizontalPadding = isMobile ? ResponsiveUtils.wp(7) : 48.0;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: Appcolors.kauthBackground,
        body: Stack(
          children: [
            // Floating decorative shapes echoing the logo's bubble motif
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, _) {
                  return _FloatingShapes(progress: _floatController.value);
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: ResponsiveUtils.pagePadding(
                  context,
                  mobileHorizontalPercent: 7,
                  tabletHorizontal: horizontalPadding,
                  desktopHorizontal: horizontalPadding,
                  top: isMobile ? ResponsiveUtils.hp(3) : 40,
                  bottom: isMobile ? ResponsiveUtils.hp(3) : 40,
                ),
                child: ResponsiveUtils.constrainWidth(
                  context: context,
                  maxWidth: 560,
                  child: Column(
                    children: [
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Transform.rotate(
                                angle: _logoRotateAnimation.value,
                                child: Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LogoMark(size: logoSize.clamp(104.0, 148.0)),
                            ResponsiveSizedBox.height(3),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Appcolors.kprimarycolor,
                                  Appcolors.kdashboardTeal,
                                ],
                              ).createShader(bounds),
                              child: const ResponsiveText(
                                'LangLex',
                                fontSize: 44,
                                weight: FontWeight.w800,
                                color: Appcolors.kwhitecolor,
                                textAlign: TextAlign.center,
                                height: 1.05,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            ResponsiveSizedBox.height(0.6),
                            const ResponsiveText(
                              'KIDS',
                              fontSize: 14,
                              weight: FontWeight.w800,
                              color: Appcolors.ksecondarycolor,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.visible,
                            ),
                            ResponsiveSizedBox.height(1.2),
                            const ResponsiveText(
                              'Learn languages, one adventure at a time! 🎈',
                              fontSize: 15,
                              weight: FontWeight.w600,
                              color: Appcolors.ktextlight,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _LoadingFooter(
                        fadeAnimation: _fadeAnimation,
                        dotsController: _dotsController,
                      ),
                    ],
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

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: Appcolors.kauthSurface,
        borderRadius: BorderRadiusStyles.kradius30(),
        border: Border.all(color: Appcolors.kauthDivider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Appcolors.kdashboardTeal.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
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

/// Soft floating blobs in the background, referencing the logo's
/// purple / teal / orange bubble palette, gently drifting up and down.
class _FloatingShapes extends StatelessWidget {
  const _FloatingShapes({required this.progress});

  final double progress;

  double _bob(double phase, double amplitude) {
    return math.sin((progress * 2 * math.pi) + phase) * amplitude;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned(
          top: -size.width * 0.22 + _bob(0, 10),
          left: -size.width * 0.22,
          child: _Blob(
            diameter: size.width * 0.7,
            color: Appcolors.ksecondarycolor.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          top: size.height * 0.08 + _bob(1.8, 8),
          right: -size.width * 0.28,
          child: _Blob(
            diameter: size.width * 0.55,
            color: Appcolors.kprimarycolor.withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          bottom: -size.width * 0.2 + _bob(3.2, 12),
          left: -size.width * 0.18,
          child: _Blob(
            diameter: size.width * 0.6,
            color: Appcolors.kmetricInventory.withValues(alpha: 0.13),
          ),
        ),
        Positioned(
          bottom: size.height * 0.15 + _bob(4.6, 9),
          right: -size.width * 0.15,
          child: _Blob(
            diameter: size.width * 0.4,
            color: Appcolors.ksecondarycolor.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter({
    required this.fadeAnimation,
    required this.dotsController,
  });

  final Animation<double> fadeAnimation;
  final AnimationController dotsController;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BouncingDots(controller: dotsController),
          ResponsiveSizedBox.height(1.6),
          const ResponsiveText(
            'Getting your lessons ready...',
            fontSize: 12,
            weight: FontWeight.w600,
            color: Appcolors.ktextlight,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

/// Three playful bouncing dots — echoing the three dots inside the
/// logo's speech bubble — used instead of a plain progress bar.
class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.controller});

  final AnimationController controller;

  static const _dotColors = [
    Appcolors.kprimarycolor,
    Appcolors.kdashboardTeal,
    Appcolors.kmetricInventory,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final t = ((controller.value - delay) % 1.0 + 1.0) % 1.0;
            final bounce = t < 0.5
                ? Curves.easeOut.transform(t * 2)
                : 1 - Curves.easeIn.transform((t - 0.5) * 2);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -10 * bounce),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _dotColors[index],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
