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

    final isMobile = ResponsiveUtils.isMobile(context);

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
                          title: AppConstants.loginTitle,
                          subtitle: AppConstants.loginSubtitle,
                          logoScale: _logoScaleAnimation,
                          logoRotate: _logoRotateAnimation,
                        ),
                        ResponsiveSizedBox.height(3.5),
                        _AuthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthTextField(
                                controller: _mobileNumberController,
                                label: AppConstants.mobileNumberLabel,
                                hintText: AppConstants.mobileNumberHint,
                                keyboardType: TextInputType.phone,
                                icon: Icons.phone_outlined,
                                iconColor: Appcolors.kprimarycolor,
                                iconSurface: Appcolors.ksoftPrimarySurface,
                              ),
                              ResponsiveSizedBox.height(3),
                              CustomButton(
                                onTap: isLoading ? () {} : _submit,
                                text: isLoading
                                    ? 'Please wait...'
                                    : AppConstants.loginButtonLabel,
                              ),
                            ],
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

/// Floating white card that holds the form — gives depth against the
/// animated bubble background instead of fields sitting directly on it.
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

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.iconColor,
    required this.iconSurface,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final Color iconColor;
  final Color iconSurface;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: ResponsiveTextStyles.montserrat(
        fontSize: 15,
        weight: FontWeight.w600,
        color: Appcolors.ktextdark,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: iconSurface,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
        filled: true,
        fillColor: Appcolors.kbackgroundcolor,
        labelStyle: ResponsiveTextStyles.montserrat(
          fontSize: 14,
          weight: FontWeight.w600,
          color: Appcolors.ktextgreycolor,
        ),
        hintStyle: ResponsiveTextStyles.montserrat(
          fontSize: 14,
          weight: FontWeight.w500,
          color: Appcolors.ktextlight,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Appcolors.kbordercolor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Appcolors.kprimarycolor,
            width: 1.8,
          ),
        ),
      ),
    );
  }
}
