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
import 'package:langlex_new_app/widgets/custom_background.dart';
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
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoRotateAnimation;

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

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.4,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_entranceController);

    _logoRotateAnimation = Tween<double>(begin: -0.12, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _entranceController.dispose();
    super.dispose();
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
    context.read<AuthBloc>().add(
      SendOtpEvent(mobileNumber: widget.mobileNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    final isMobile = ResponsiveUtils.isMobile(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthOtpSent) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('OTP generated again.')),
            );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: Appcolors.kauthBackground,
          body: KidsBubbleBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: ResponsiveUtils.pagePadding(
                  context,
                  mobileHorizontalPercent: 7,
                  tabletHorizontal: 48,
                  desktopHorizontal: 48,
                  top: isMobile ? ResponsiveUtils.hp(5) : 56,
                  bottom: isMobile ? ResponsiveUtils.hp(5) : 56,
                ),
                child: ResponsiveUtils.constrainWidth(
                  context: context,
                  maxWidth: 460,
                  child: AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuthHeader(
                          title: AppConstants.verifyOtpTitle,
                          subtitle: AppConstants.verifyOtpSubtitle,
                          logoScale: _logoScaleAnimation,
                          logoRotate: _logoRotateAnimation,
                        ),
                        ResponsiveSizedBox.height(3.5),
                        _AuthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                onPressed: isLoading ? () {} : _resend,
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
                          onPressed: () => context.go(AppRoutes.login),
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
  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.logoScale,
    required this.logoRotate,
  });

  final String title;
  final String subtitle;
  final Animation<double> logoScale;
  final Animation<double> logoRotate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: logoScale,
          builder: (context, child) {
            return Transform.rotate(
              angle: logoRotate.value,
              child: Transform.scale(scale: logoScale.value, child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Appcolors.kauthSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kprimarycolor.withValues(alpha: 0.22),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Image.asset(
              AppConstants.appLogo,
              height: ResponsiveUtils.isMobile(context) ? 76 : 92,
              fit: BoxFit.contain,
            ),
          ),
        ),
        ResponsiveSizedBox.height(2.6),
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
  const _ResendOtpAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
          onPressed: onPressed,
          child: const ResponsiveText(
            AppConstants.resendOtpAction,
            fontSize: 14,
            weight: FontWeight.w800,
            color: Appcolors.kprimarycolor,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}
