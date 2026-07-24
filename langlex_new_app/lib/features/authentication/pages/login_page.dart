import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/appconstants.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/core/routes/approutes.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_event.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _mobileNumberController = TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.045), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.1, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _mobileNumberController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(
      CheckUserEvent(mobileNumber: _mobileNumberController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUserNotExists) {
          context.go(AppRoutes.signup, extra: state.mobileNumber);
        } else if (state is AuthOtpSent) {
          context.go(AppRoutes.verifyOtp, extra: state.mobileNumber);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            extendBody: true,
            backgroundColor: const Color(0xFFEAF0FF),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    AppConstants.loginImage,
                    fit: BoxFit.fill,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const contentHeightEstimate = 488.0;
                      final desiredTopGap = constraints.maxHeight * 0.25;
                      final maxTopGap =
                          constraints.maxHeight - contentHeightEstimate;
                      final topGap = desiredTopGap
                          .clamp(0.0, maxTopGap.clamp(0.0, 360.0))
                          .toDouble();
                      final contentWidth = math.min(
                        constraints.maxWidth - 48,
                        430.0,
                      );

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: contentWidth,
                              child: AnimatedBuilder(
                                animation: _entranceController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeAnimation.value.clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: topGap),
                                    const _LoginHeading(),
                                    const SizedBox(height: 28),
                                    _LoginFormCard(
                                      controller: _mobileNumberController,
                                      isLoading: isLoading,
                                      onSubmit: _submit,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoginHeading extends StatelessWidget {
  const _LoginHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF8B5CF6), Appcolors.kdashboardTeal],
          ).createShader(bounds),
          child: Text(
            AppConstants.loginTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Appcolors.kwhitecolor,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ResponsiveText(
          AppConstants.loginSubtitle,
          fontSize: 17,
          weight: FontWeight.w700,
          color: const Color(0xFF77718F),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
          height: 1.28,
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 24, 21, 24),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Appcolors.kwhitecolor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.13),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhoneNumberField(controller: controller),
          const SizedBox(height: 20),
          _ContinueButton(isLoading: isLoading, onTap: onSubmit),
          const SizedBox(height: 22),
          const _DividerLabel(label: 'or continue with'),
          const SizedBox(height: 18),
          const _SocialAuthButton(
            label: 'Continue with Google',
            child: _GoogleMark(),
          ),
          const SizedBox(height: 12),
          const _SocialAuthButton(
            label: 'Continue with Apple',
            child: Icon(Icons.apple_rounded, color: Appcolors.kblackcolor),
          ),
        ],
      ),
    );
  }
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFF0E8FC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_outlined,
              color: Appcolors.kprimarycolor,
              size: 21,
            ),
          ),
          const SizedBox(width: 15),
          const ResponsiveText(
            '+91',
            fontSize: 16,
            weight: FontWeight.w800,
            color: Color(0xFF6E6888),
          ),
          const SizedBox(width: 16),
          Container(width: 1.4, height: 28, color: const Color(0xFFE2D9F2)),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Appcolors.ktextdark,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: AppConstants.mobileNumberLabel,
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF817A99),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: !isLoading,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLoading
                    ? const [
                        Appcolors.kheroStartButtonDisabledTop,
                        Appcolors.kheroStartButtonDisabledBottom,
                      ]
                    : const [Color(0xFF915CE9), Color(0xFF69B286)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kprimarycolor.withValues(
                    alpha: isLoading ? 0.10 : 0.30,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ResponsiveText(
                    isLoading
                        ? 'Please wait...'
                        : AppConstants.loginButtonLabel,
                    fontSize: 18,
                    weight: FontWeight.w900,
                    color: Appcolors.kwhitecolor,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 22),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Appcolors.kwhitecolor,
                  size: 31,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFFE3DCEF), thickness: 1.2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: ResponsiveText(
            label,
            fontSize: 13,
            weight: FontWeight.w800,
            color: const Color(0xFF756E8C),
            maxLines: 1,
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFFE3DCEF), thickness: 1.2),
        ),
      ],
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE9E1F4), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Appcolors.kprimarycolor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 28, height: 28, child: Center(child: child)),
            const SizedBox(width: 16),
            Flexible(
              child: ResponsiveText(
                label,
                fontSize: 15,
                weight: FontWeight.w800,
                color: const Color(0xFF6E6888),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: GoogleFonts.montserrat(
        fontSize: 25,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF4285F4),
      ),
    );
  }
}
