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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, this.initialMobileNumber});

  final String? initialMobileNumber;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _mobileNumberController.text = widget.initialMobileNumber ?? '';

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
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(
      RegisterEvent(
        fullName: _usernameController.text,
        mobileNumber: _mobileNumberController.text,
        school: _schoolController.text,
        city: _cityController.text,
        state: _stateController.text,
        email: _emailController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
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
                      final contentWidth = math.min(
                        constraints.maxWidth - 40,
                        460.0,
                      );

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomCenter,
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
                                    const _AuthHeader(
                                      title: AppConstants.signupTitle,
                                      subtitle: AppConstants.signupSubtitle,
                                    ),
                                    const SizedBox(height: 14),
                                    _AuthCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _AuthTextField(
                                            controller: _usernameController,
                                            label: AppConstants.usernameLabel,
                                            hintText: AppConstants.usernameHint,
                                            icon: Icons.person_outline,
                                            iconColor: Appcolors.kprimarycolor,
                                            iconSurface:
                                                Appcolors.ksoftPrimarySurface,
                                          ),
                                          const SizedBox(height: 8),
                                          _AuthTextField(
                                            controller: _mobileNumberController,
                                            label:
                                                AppConstants.mobileNumberLabel,
                                            hintText:
                                                AppConstants.mobileNumberHint,
                                            keyboardType: TextInputType.phone,
                                            icon: Icons.phone_outlined,
                                            iconColor: Appcolors.kdashboardTeal,
                                            iconSurface: Appcolors
                                                .kdashboardOnlineSurface,
                                          ),
                                          const SizedBox(height: 8),
                                          _AuthTextField(
                                            controller: _emailController,
                                            label: AppConstants.emailLabel,
                                            hintText: AppConstants.emailHint,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            icon: Icons.email_outlined,
                                            iconColor:
                                                Appcolors.kmetricInventory,
                                            iconSurface: Appcolors
                                                .kmetricInventorySurface,
                                          ),
                                          const SizedBox(height: 8),
                                          _AuthTextField(
                                            controller: _schoolController,
                                            label: AppConstants.schoolLabel,
                                            hintText: AppConstants.schoolHint,
                                            keyboardType: TextInputType.name,
                                            icon: Icons.school_outlined,
                                            iconColor: Appcolors.kprimarycolor,
                                            iconSurface:
                                                Appcolors.ksoftPrimarySurface,
                                          ),
                                          const SizedBox(height: 8),
                                          _AuthTextField(
                                            controller: _cityController,
                                            label: AppConstants.cityLabel,
                                            hintText: AppConstants.cityHint,
                                            keyboardType:
                                                TextInputType.streetAddress,
                                            icon: Icons.location_city_outlined,
                                            iconColor: Appcolors.kdashboardTeal,
                                            iconSurface: Appcolors
                                                .kdashboardOnlineSurface,
                                          ),
                                          const SizedBox(height: 8),
                                          _AuthTextField(
                                            controller: _stateController,
                                            label: AppConstants.stateLabel,
                                            hintText: AppConstants.stateHint,
                                            keyboardType:
                                                TextInputType.streetAddress,
                                            icon: Icons.map_outlined,
                                            iconColor:
                                                Appcolors.kmetricInventory,
                                            iconSurface: Appcolors
                                                .kmetricInventorySurface,
                                          ),
                                          const SizedBox(height: 14),
                                          CustomButton(
                                            onTap: isLoading ? () {} : _submit,
                                            text: isLoading
                                                ? 'Please wait...'
                                                : AppConstants
                                                      .signupButtonLabel,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _AuthFooterAction(
                                      prompt: AppConstants.loginPrompt,
                                      actionLabel: AppConstants.loginAction,
                                      onPressed: () =>
                                          context.go(AppRoutes.login),
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

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Appcolors.kprimarycolor, Appcolors.kdashboardTeal],
          ).createShader(bounds),
          child: ResponsiveText(
            title,
            fontSize: 28,
            weight: FontWeight.w800,
            color: Appcolors.kwhitecolor,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
        ),
        ResponsiveSizedBox.height(1),
        ResponsiveText(
          subtitle,
          fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
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
        fontSize: 13,
        weight: FontWeight.w600,
        color: Appcolors.ktextdark,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 46, maxHeight: 48),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: iconSurface,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 44,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Appcolors.kbackgroundcolor,
        labelStyle: ResponsiveTextStyles.montserrat(
          fontSize: 12,
          weight: FontWeight.w600,
          color: Appcolors.ktextgreycolor,
        ),
        hintStyle: ResponsiveTextStyles.montserrat(
          fontSize: 12,
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

class _AuthFooterAction extends StatelessWidget {
  const _AuthFooterAction({
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ResponsiveText(
          prompt,
          fontSize: 14,
          weight: FontWeight.w600,
          color: Appcolors.kblackcolor,
          overflow: TextOverflow.visible,
        ),
        TextButton(
          onPressed: onPressed,
          child: ResponsiveText(
            actionLabel,
            fontSize: 14,
            weight: FontWeight.w800,
            color: Appcolors.kwhitecolor,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}
