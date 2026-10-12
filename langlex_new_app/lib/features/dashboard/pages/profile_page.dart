import 'package:langlex_new_app/features/dashboard/widgets/sound_effects_setting.dart';
import 'package:langlex_new_app/features/progress/progress_widgets.dart';
import 'package:langlex_new_app/features/progress/progress_page.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_event.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';
import 'package:langlex_new_app/features/dashboard/pages/edit_profile_page.dart';
import 'package:langlex_new_app/features/dashboard/widgets/dashboard_page_layout.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/learning_setup_page.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.showBack = true});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        final homeLanguage = state is LearningLoaded
            ? state.catalog.setup.primaryLanguage
            : 'English';
        final t = AppLocalizations(homeLanguage);
        final catalog = state is LearningLoaded ? state.catalog : null;

        return FlowScrollView(
          header: FlowPageHeader(
            title: t.profile,
            showBack: showBack,
            subtitle: t.profileSubtitle,
            artwork: KidsLearningAssets.profileLionIcon,
          ),
          padding: const EdgeInsets.only(bottom: 24),
          child: Padding(
            padding: ResponsiveUtils.pagePadding(
              context,
              mobileHorizontalPercent: 6,
              tabletHorizontal: 42,
              desktopHorizontal: 56,
            ).copyWith(top: 0),
            child: ResponsiveUtils.constrainWidth(
              context: context,
              maxWidth: 680,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileSummaryCard(t: t),
                  ResponsiveSizedBox.height(1.4),
                  ProgressOverviewCard(
                    language: homeLanguage,
                    onDetails: () => Navigator.of(context).push(
                      playfulRoute(page: ProgressPage(language: homeLanguage)),
                    ),
                  ),
                  ResponsiveSizedBox.height(1.4),
                  _EditProfileTile(t: t, homeLanguage: homeLanguage),
                  ResponsiveSizedBox.height(1.4),
                  if (state is LearningInitial || state is LearningLoading)
                    LearningProgressShimmer(label: t.loading)
                  else
                    _LearningProgressCard(t: t, catalog: catalog),
                  ResponsiveSizedBox.height(1.4),
                  _UpgradePlanTile(t: t, homeLanguage: homeLanguage),
                  ResponsiveSizedBox.height(1.4),
                  SoundEffectsSetting(t: t),
                  ResponsiveSizedBox.height(1.4),
                  _ProfileDetailsCard(t: t),
                  ResponsiveSizedBox.height(1.4),
                  DashboardActionTile(
                    icon: Icons.logout_rounded,
                    title: t.logout,
                    subtitle: t.signOutSubtitle,
                    accent: Appcolors.kredcolor,
                    surface: Appcolors.kmetricLowStockSurface,
                    onTap: () =>
                        context.read<AuthBloc>().add(const LogoutEvent()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditProfileTile extends StatelessWidget {
  const _EditProfileTile({required this.t, required this.homeLanguage});

  final AppLocalizations t;
  final String homeLanguage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return _ProfileActionCard(
          assetPath: KidsLearningAssets.pencilIcon,
          title: t.editProfile,
          subtitle: t.editProfileSubtitle,
          accent: Appcolors.kprimarycolor,
          surface: Appcolors.ksoftPrimarySurface,
          onTap: user == null
              ? null
              : () {
                  Navigator.of(context).push(
                    playfulRoute(
                      page: EditProfilePage(
                        user: user,
                        homeLanguage: homeLanguage,
                      ),
                    ),
                  );
                },
        );
      },
    );
  }
}

class _UpgradePlanTile extends StatelessWidget {
  const _UpgradePlanTile({required this.t, required this.homeLanguage});

  final AppLocalizations t;
  final String homeLanguage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        return _UpgradePlanCard(
          title: t.upgradePlan,
          subtitle: t.upgradePlanSubtitle,
          onTap: state is LearningLoaded
              ? () {
                  Navigator.of(context).push(
                    playfulRoute(
                      page: PaymentCheckoutPage(
                        plans: state.catalog.plans,
                        homeLanguage: homeLanguage,
                      ),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.surface,
    this.onTap,
  });

  final String assetPath;
  final String title;
  final String subtitle;
  final Color accent;
  final Color surface;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onTap != null,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            decoration: BoxDecoration(
              color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Appcolors.kauthDivider),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kprimarycolor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    assetPath,
                    width: 31,
                    height: 31,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        title,
                        fontSize: 14.8,
                        weight: FontWeight.w900,
                        color: Appcolors.ktextdark,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 3),
                      ResponsiveText(
                        subtitle,
                        fontSize: 11.5,
                        weight: FontWeight.w600,
                        color: Appcolors.kdashboardMutedText,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: accent,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradePlanCard extends StatelessWidget {
  const _UpgradePlanCard({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onTap != null,
      child: Material(
        color: Appcolors.ktransparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFF8EA), Color(0xFFFFEDD3)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Appcolors.kheroStartButtonBottom),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kheroStartButtonBottom.withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 42,
                  top: 4,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Appcolors.kheroStartButtonBottom.withValues(
                      alpha: 0.30,
                    ),
                    size: 18,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Appcolors.kwhitecolor.withValues(alpha: 0.50),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        KidsLearningAssets.crownIcon,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            title,
                            fontSize: 14.8,
                            weight: FontWeight.w900,
                            color: Appcolors.ktextdark,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 3),
                          ResponsiveText(
                            subtitle,
                            fontSize: 11.5,
                            weight: FontWeight.w600,
                            color: Appcolors.kdashboardMutedText,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Appcolors.kheroStartButtonBottom,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Appcolors.kwhitecolor,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningProgressCard extends StatelessWidget {
  const _LearningProgressCard({required this.t, required this.catalog});

  final AppLocalizations t;
  final LearningCatalog? catalog;

  @override
  Widget build(BuildContext context) {
    return _LearningProgressContent(catalog: catalog, t: t);
  }
}

class _LearningProgressContent extends StatelessWidget {
  const _LearningProgressContent({required this.catalog, required this.t});

  final LearningCatalog? catalog;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final setup = catalog?.setup;
    final plan = _planName(catalog);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFF).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.kprimarycolor.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: Appcolors.ksoftPrimarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Appcolors.kprimarycolor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ResponsiveText(
                  t.learningSetup,
                  fontSize: 14.8,
                  weight: FontWeight.w900,
                  color: Appcolors.ktextdark,
                  overflow: TextOverflow.visible,
                ),
              ),
              TextButton.icon(
                onPressed: catalog == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          playfulRoute(
                            page: LearningSetupPage(catalog: catalog!),
                          ),
                        );
                      },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(t.edit),
                style: TextButton.styleFrom(
                  foregroundColor: Appcolors.kprimarycolor,
                  visualDensity: VisualDensity.compact,
                  textStyle: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSizedBox.height(1.2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfilePill(
                icon: Icons.child_care_rounded,
                label: '${t.student}: ${setup?.childName ?? t.loading}',
              ),
              _ProfilePill(
                icon: Icons.language_rounded,
                label:
                    '${t.languageLabel}: ${setup?.activeLanguage ?? t.loading}',
              ),
              _ProfilePill(
                icon: Icons.star_rounded,
                label: '${t.level}: ${setup?.level ?? t.loading}',
              ),
              _ProfilePill(
                icon: Icons.card_giftcard_rounded,
                label: '${t.plan}: $plan',
              ),
            ],
          ),
          if (setup != null && setup.interests.isNotEmpty) ...[
            ResponsiveSizedBox.height(1.2),
            ResponsiveText(
              '${t.interests}: ${setup.interests.join(', ')}',
              fontSize: 12,
              weight: FontWeight.w800,
              color: Appcolors.kdashboardMutedText,
              overflow: TextOverflow.visible,
            ),
          ],
        ],
      ),
    );
  }

  String _planName(LearningCatalog? catalog) {
    if (catalog == null) return t.loading;
    final planId = catalog.setup.planId;
    if (planId == null) return t.free;
    for (final plan in catalog.plans) {
      if (plan.id == planId) return plan.name;
    }
    return t.free;
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Appcolors.kprimarycolor.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Appcolors.kprimarycolor, size: 15),
          const SizedBox(width: 5),
          ResponsiveText(
            label,
            fontSize: 11,
            weight: FontWeight.w900,
            color: Appcolors.kprimarycolor,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(17, 15, 17, 4),
          decoration: BoxDecoration(
            color: Appcolors.kwhitecolor.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Appcolors.kauthDivider),
            boxShadow: [
              BoxShadow(
                color: Appcolors.kprimarycolor.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -5,
                top: -10,
                child: SvgPicture.asset(
                  KidsLearningAssets.rainbowIcon,
                  width: 54,
                  height: 54,
                  fit: BoxFit.contain,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F1FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Appcolors.kdashboardBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ResponsiveText(
                          t.accountInformation,
                          fontSize: 14.8,
                          weight: FontWeight.w900,
                          color: Appcolors.ktextdark,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(width: 54),
                    ],
                  ),
                  ResponsiveSizedBox.height(1.2),
                  _ProfileInfoRow(
                    icon: Icons.phone_outlined,
                    label: t.mobileNumber,
                    value: user?.mobileNumber,
                    accent: Appcolors.kprimarycolor,
                    surface: Appcolors.ksoftPrimarySurface,
                  ),
                  _ProfileInfoRow(
                    icon: Icons.email_outlined,
                    label: t.email,
                    value: user?.email,
                    accent: Appcolors.kheroStartButtonBottom,
                    surface: Appcolors.kmetricInventorySurface,
                  ),
                  _ProfileInfoRow(
                    icon: Icons.school_outlined,
                    label: t.school,
                    value: user?.school,
                    accent: Appcolors.kdashboardTeal,
                    surface: Appcolors.kauthSoftGreen,
                  ),
                  _ProfileInfoRow(
                    icon: Icons.location_city_outlined,
                    label: t.city,
                    value: user?.city,
                    accent: Appcolors.kdashboardBlue,
                    surface: const Color(0xFFE5F1FF),
                  ),
                  _ProfileInfoRow(
                    icon: Icons.map_outlined,
                    label: t.state,
                    value: user?.state,
                    accent: Appcolors.kmetricInventory,
                    surface: Appcolors.kmetricInventorySurface,
                    showDivider: false,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.surface,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color accent;
  final Color surface;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim().isNotEmpty == true ? value!.trim() : '-';

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    label,
                    fontSize: 11.5,
                    weight: FontWeight.w700,
                    color: Appcolors.kdashboardMutedText,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 3),
                  ResponsiveText(
                    displayValue,
                    fontSize: 12.8,
                    weight: FontWeight.w800,
                    color: Appcolors.ktextdark,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Appcolors.kdashboardMutedIcon,
              size: 22,
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Appcolors.kauthDivider),
          ),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 16, 15),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Appcolors.kauthDivider),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.11),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Appcolors.kwhitecolor,
              shape: BoxShape.circle,
              border: Border.all(color: Appcolors.kwhitecolor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Appcolors.kblackcolor.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.face_rounded,
              color: Appcolors.kdashboardBlue,
              size: 35,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      user?.fullName ?? t.langLexLearner,
                      fontSize: 16.5,
                      weight: FontWeight.w900,
                      color: Appcolors.ktextdark,
                    ),
                    const SizedBox(height: 5),
                    ResponsiveText(
                      user?.mobileNumber ?? t.profileActive,
                      fontSize: 13,
                      weight: FontWeight.w900,
                      color: Appcolors.kdashboardTeal,
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Appcolors.ksoftPrimarySurface.withValues(alpha: 0.76),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Appcolors.kprimarycolor,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Appcolors.kwhitecolor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
