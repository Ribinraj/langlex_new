import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_event.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';
import 'package:langlex_new_app/features/dashboard/pages/edit_profile_page.dart';
import 'package:langlex_new_app/features/dashboard/widgets/dashboard_page_layout.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/learning_setup_page.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        final homeLanguage = state is LearningLoaded
            ? state.catalog.setup.primaryLanguage
            : 'English';
        final t = AppLocalizations(homeLanguage);

        return DashboardPageLayout(
          children: [
            DashboardHeader(title: t.profile, subtitle: t.profileSubtitle),
            ResponsiveSizedBox.height(3),
            _ProfileSummaryCard(t: t),
            ResponsiveSizedBox.height(2.4),
            _EditProfileTile(t: t, homeLanguage: homeLanguage),
            ResponsiveSizedBox.height(2.4),
            _LearningProgressCard(t: t),
            ResponsiveSizedBox.height(2.4),
            _UpgradePlanTile(t: t, homeLanguage: homeLanguage),
            ResponsiveSizedBox.height(2.4),
            _ProfileDetailsCard(t: t),
            ResponsiveSizedBox.height(1.6),
            DashboardActionTile(
              icon: Icons.logout_rounded,
              title: t.logout,
              subtitle: t.signOutSubtitle,
              accent: Appcolors.kredcolor,
              surface: Appcolors.kmetricLowStockSurface,
              onTap: () => context.read<AuthBloc>().add(const LogoutEvent()),
            ),
          ],
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

        return DashboardActionTile(
          icon: Icons.manage_accounts_rounded,
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
        return DashboardActionTile(
          icon: Icons.workspace_premium_rounded,
          title: t.upgradePlan,
          subtitle: t.upgradePlanSubtitle,
          accent: Appcolors.kmetricInventory,
          surface: Appcolors.kmetricInventorySurface,
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

class _LearningProgressCard extends StatelessWidget {
  const _LearningProgressCard({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        final catalog = state is LearningLoaded ? state.catalog : null;

        return _LearningProgressContent(
          catalog: catalog,
          t: t,
          courseCount: catalog?.courses.length ?? 0,
          quizCount: catalog?.quizQuestions.length ?? 0,
        );
      },
    );
  }
}

class _LearningProgressContent extends StatelessWidget {
  const _LearningProgressContent({
    required this.catalog,
    required this.t,
    required this.courseCount,
    required this.quizCount,
  });

  final LearningCatalog? catalog;
  final AppLocalizations t;
  final int courseCount;
  final int quizCount;

  @override
  Widget build(BuildContext context) {
    final setup = catalog?.setup;
    final plan = _planName(catalog);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Appcolors.kauthDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ResponsiveText(
                  t.learningSetup,
                  fontSize: 16,
                  weight: FontWeight.w800,
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
              ),
            ],
          ),
          ResponsiveSizedBox.height(1.6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProfilePill(
                label: '${t.student}: ${setup?.childName ?? t.loading}',
              ),
              _ProfilePill(
                label: '${t.home}: ${setup?.primaryLanguage ?? t.loading}',
              ),
              _ProfilePill(
                label: '${t.learning}: ${setup?.learningLanguage ?? t.loading}',
              ),
              _ProfilePill(label: '${t.level}: ${setup?.level ?? t.loading}'),
              _ProfilePill(
                label:
                    '${t.goal}: ${setup?.dailyGoalMinutes ?? 0} ${t.minutesShort}',
              ),
              _ProfilePill(label: '${t.plan}: $plan'),
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
          ResponsiveSizedBox.height(1.8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: courseCount == 0 ? 0 : 1,
              minHeight: 9,
              backgroundColor: Appcolors.ksoftPrimarySurface,
              valueColor: const AlwaysStoppedAnimation(Appcolors.kprimarycolor),
            ),
          ),
          const SizedBox(height: 10),
          ResponsiveText(
            t.courseQuizReady(courseCount, quizCount),
            fontSize: 12,
            weight: FontWeight.w800,
            color: Appcolors.kdashboardMutedText,
          ),
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
  const _ProfilePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Appcolors.ksoftPrimarySurface,
        borderRadius: BorderRadius.circular(99),
      ),
      child: ResponsiveText(
        label,
        fontSize: 11.5,
        weight: FontWeight.w900,
        color: Appcolors.kprimarycolor,
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Appcolors.kauthDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                t.accountInformation,
                fontSize: 16,
                weight: FontWeight.w800,
                color: Appcolors.ktextdark,
                overflow: TextOverflow.visible,
              ),
              ResponsiveSizedBox.height(2),
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
                accent: Appcolors.kmetricInventory,
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
                accent: Appcolors.kprimarycolor,
                surface: Appcolors.ksoftPrimarySurface,
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    label,
                    fontSize: 12,
                    weight: FontWeight.w700,
                    color: Appcolors.kdashboardMutedText,
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 4),
                  ResponsiveText(
                    displayValue,
                    fontSize: 14,
                    weight: FontWeight.w800,
                    color: Appcolors.ktextdark,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Appcolors.ksoftPrimarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Appcolors.kprimarycolor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      user?.fullName ?? t.langLexLearner,
                      fontSize: 17,
                      weight: FontWeight.w800,
                      color: Appcolors.ktextdark,
                    ),
                    const SizedBox(height: 5),
                    ResponsiveText(
                      user?.mobileNumber ?? t.profileActive,
                      fontSize: 13,
                      weight: FontWeight.w700,
                      color: Appcolors.kdashboardTeal,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
