import 'package:langlex_new_app/core/app_toast.dart';
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
import 'package:langlex_new_app/widgets/custom_button.dart';
import 'package:pinput/pinput.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key, required this.mobileNumber});

  final String mobileNumber;

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage>
    with SingleTickerProviderStateMixin {
  static const int _defaultResendSeconds = 30;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _resendTimer;
  Timer? _expiryTimer;
  String? _displayCode;
  bool _previewMode = false;
  DateTime? _expiresAt;
  int _resendSecondsRemaining = _defaultResendSeconds;

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
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
    final state = context.read<AuthBloc>().state;
    if (state is AuthOtpSent && state.mobileNumber == widget.mobileNumber) {
      _applyChallenge(state);
    } else {
      _startResendTimer(_defaultResendSeconds);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _applyChallenge(AuthOtpSent state) {
    _expiryTimer?.cancel();
    _displayCode = state.displayCode;
    _previewMode = state.displayCode != null;
    _expiresAt = state.expiresAt;
    _otpController.clear();
    final remaining = _expiresAt?.difference(DateTime.now());
    if (remaining != null) {
      if (remaining.isNegative) {
        _displayCode = null;
      } else {
        _expiryTimer = Timer(remaining, () {
          if (mounted) setState(() => _displayCode = null);
        });
      }
    }
    _startResendTimer(state.resendAfterSeconds);
  }

  void _verify() {
    context.read<AuthBloc>().add(
      VerifyOtpEvent(
        mobileNumber: widget.mobileNumber,
        otp: _otpController.text,
      ),
    );
  }

  void _resend() {
    if (_resendSecondsRemaining > 0) return;

    context.read<AuthBloc>().add(
      ResendOtpEvent(mobileNumber: widget.mobileNumber),
    );
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();

    setState(() {
      _resendSecondsRemaining = seconds.clamp(0, 300).toInt();
    });

    if (_resendSecondsRemaining == 0) return;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _resendSecondsRemaining -= 1;
      });

      if (_resendSecondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthOtpSent) {
          _applyChallenge(state);
          AppToast.success(context, 'A new OTP is ready.');
        } else if (state is AuthError) {
          AppToast.error(context, state.message);
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
                      final contentHeightEstimate = _displayCode != null
                          ? 620.0
                          : 386.0;
                      final desiredTopGap =
                          constraints.maxHeight *
                          (_displayCode != null ? 0.12 : 0.25);
                      final maxTopGap =
                          constraints.maxHeight - contentHeightEstimate;
                      final topGap = desiredTopGap
                          .clamp(0.0, maxTopGap.clamp(0.0, 360.0))
                          .toDouble();
                      final contentWidth = math.min(
                        constraints.maxWidth - 48,
                        460.0,
                      );

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
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
                                    _AuthHeader(
                                      title: AppConstants.verifyOtpTitle,
                                      subtitle: _previewMode
                                          ? 'Enter the code shown below to continue.'
                                          : AppConstants.verifyOtpSubtitle,
                                    ),
                                    ResponsiveSizedBox.height(3.5),
                                    _AuthCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (_previewMode) ...[
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0E7FF),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'Your temporary OTP',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Appcolors
                                                          .klibraryTitle,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _displayCode ?? 'Expired',
                                                    key: const ValueKey(
                                                      'otp-preview',
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 28,
                                                      letterSpacing: 6,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Appcolors
                                                          .kprimarycolor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _displayCode == null
                                                        ? 'This code expired. Request a new OTP.'
                                                        : 'SMS delivery is not enabled yet. Use this code to continue.',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                  if (_expiresAt != null)
                                                    Text(
                                                      'Valid until ${TimeOfDay.fromDateTime(_expiresAt!.toLocal()).format(context)}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                          ],
                                          const ResponsiveText(
                                            AppConstants.otpLabel,
                                            fontSize: 14,
                                            weight: FontWeight.w700,
                                            color: Appcolors.ktextgreycolor,
                                            overflow: TextOverflow.visible,
                                          ),
                                          ResponsiveSizedBox.height(1.5),
                                          _OtpInput(
                                            controller: _otpController,
                                            focusNode: _otpFocusNode,
                                          ),
                                          ResponsiveSizedBox.height(2.2),
                                          _ResendOtpAction(
                                            secondsRemaining:
                                                _resendSecondsRemaining,
                                            isLoading: isLoading,
                                            onPressed: _resend,
                                          ),
                                          ResponsiveSizedBox.height(3),
                                          CustomButton(
                                            onTap: isLoading ? () {} : _verify,
                                            text: isLoading
                                                ? 'Verifying...'
                                                : AppConstants.otpButtonLabel,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ResponsiveSizedBox.height(2.5),
                                    TextButton.icon(
                                      onPressed: () =>
                                          context.go(AppRoutes.login),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Appcolors.kprimarycolor,
                                        size: 18,
                                      ),
                                      label: const ResponsiveText(
                                        AppConstants.loginAction,
                                        fontSize: 14,
                                        weight: FontWeight.w800,
                                        color: Appcolors.kprimarycolor,
                                        overflow: TextOverflow.visible,
                                      ),
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

class _OtpInput extends StatelessWidget {
  const _OtpInput({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final pinSize = isMobile ? 45.0 : 58.0;
    final gap = isMobile ? 6.0 : 10.0;

    final defaultTheme = PinTheme(
      width: pinSize,
      height: pinSize,
      textStyle: ResponsiveTextStyles.montserrat(
        fontSize: 20,
        weight: FontWeight.w800,
        color: Appcolors.ktextdark,
      ),
      decoration: BoxDecoration(
        color: Appcolors.kbackgroundcolor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Appcolors.kbordercolor),
      ),
    );

    return Pinput(
      controller: controller,
      focusNode: focusNode,
      length: 6,
      keyboardType: TextInputType.number,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyWith(
        decoration: defaultTheme.decoration?.copyWith(
          border: Border.all(color: Appcolors.kprimarycolor, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Appcolors.kprimarycolor.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
      submittedPinTheme: defaultTheme.copyWith(
        decoration: defaultTheme.decoration?.copyWith(
          color: Appcolors.ksoftPrimarySurface,
          border: Border.all(color: Appcolors.kprimarycolor),
        ),
      ),
      separatorBuilder: (index) => SizedBox(width: gap),
      hapticFeedbackType: HapticFeedbackType.lightImpact,
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Appcolors.kprimarycolor, Appcolors.kdashboardTeal],
            ).createShader(bounds),
            child: ResponsiveText(
              title,
              fontSize: 30,
              weight: FontWeight.w800,
              color: Appcolors.kwhitecolor,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
            ),
          ),
          ResponsiveSizedBox.height(1),
          ResponsiveText(
            subtitle,
            fontSize: 14,
            weight: FontWeight.w600,
            color: Appcolors.ktextlight,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            height: 1.45,
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Appcolors.kauthSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Appcolors.kauthDivider),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ResendOtpAction extends StatelessWidget {
  const _ResendOtpAction({
    required this.secondsRemaining,
    required this.isLoading,
    required this.onPressed,
  });

  final int secondsRemaining;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsRemaining <= 0 && !isLoading;
    final timerText = _formatTimer(secondsRemaining);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const ResponsiveText(
          AppConstants.resendOtpPrompt,
          fontSize: 14,
          weight: FontWeight.w600,
          color: Appcolors.ktextgreycolor,
          overflow: TextOverflow.visible,
        ),
        TextButton(
          onPressed: canResend ? onPressed : null,
          child: ResponsiveText(
            canResend ? AppConstants.resendOtpAction : 'Resend in $timerText',
            fontSize: 14,
            weight: FontWeight.w800,
            color: canResend
                ? Appcolors.kprimarycolor
                : Appcolors.kdashboardMutedText,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  String _formatTimer(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutes = safeSeconds ~/ 60;
    final remainingSeconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
