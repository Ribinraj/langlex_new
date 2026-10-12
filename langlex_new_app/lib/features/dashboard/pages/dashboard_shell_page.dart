import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/core/routes/approutes.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_bloc.dart';
import 'package:langlex_new_app/features/authentication/blocs/auth_bloc/auth_state.dart';
import 'package:langlex_new_app/features/dashboard/pages/home_page.dart';
import 'package:langlex_new_app/features/dashboard/pages/learn_page.dart';
import 'package:langlex_new_app/features/dashboard/widgets/custom_bottom_nav_bar.dart';
import 'package:langlex_new_app/features/dashboard/widgets/dashboard_drawer.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';
import 'package:langlex_new_app/features/notifications/pages/notifications_page.dart';
import 'package:langlex_new_app/features/dashboard/pages/profile_page.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/pages/learning_setup_page.dart';
import 'package:langlex_new_app/features/learning/pages/language_selection_page.dart';

class DashboardShellPage extends StatefulWidget {
  const DashboardShellPage({super.key});

  @override
  State<DashboardShellPage> createState() => _DashboardShellPageState();
}

class _DashboardShellPageState extends State<DashboardShellPage> {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    context.read<LearningBloc>().add(
      const LoadLearningCatalogEvent(forceRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    final learningState = context.watch<LearningBloc>().state;
    final homeLanguage = learningState is LearningLoaded
        ? learningState.catalog.setup.primaryLanguage
        : 'English';
    final t = AppLocalizations(homeLanguage);
    final isMobile = ResponsiveUtils.isMobile(context);
    final pages = [
      const HomePage(),
      const LearnPage(searchMode: true),
      const ProfilePage(showBack: false),
    ];

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              context.go(AppRoutes.login);
            }
          },
        ),
      ],
      child:
          learningState is LearningLoaded &&
              !learningState.catalog.setup.hasSelectedLanguages
          ? LanguageSelectionPage(catalog: learningState.catalog)
          : PopScope(
              canPop: _selectedIndex == 0,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && _selectedIndex != 0) _selectTab(0);
              },
              child: Scaffold(
                extendBody: true,
                backgroundColor: Appcolors.kscreenWarmBackground,
                drawer: DashboardDrawer(
                  t: t,
                  setup: learningState is LearningLoaded
                      ? learningState.catalog.setup
                      : null,
                  selectedIndex: _selectedIndex,
                  onSelectTab: (index) {
                    Navigator.of(context).pop();
                    _selectTab(index);
                  },
                  onSetup: learningState is LearningLoaded
                      ? () => _openMenuPage(
                          context,
                          LearningSetupPage(catalog: learningState.catalog),
                        )
                      : null,
                  onNotifications: () => _openMenuPage(
                    context,
                    NotificationsPage(homeLanguage: homeLanguage),
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  top: false,
                  minimum: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 42,
                    0,
                    isMobile ? 20 : 42,
                    12,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 1,
                    child: CustomBottomNavBar(
                      items: [
                        BottomNavBarItem(
                          icon: Icons.home_rounded,
                          label: t.home,
                          assetPath: 'assets/icons/learn (1).svg',
                        ),
                        BottomNavBarItem(
                          icon: Icons.search_rounded,
                          label: t.search,
                        ),
                        BottomNavBarItem(
                          icon: Icons.person_rounded,
                          label: t.profile,
                          assetPath: 'assets/icons/account.svg',
                        ),
                      ],
                      selectedIndex: _selectedIndex,
                      onTap: (index) {
                        LearningAssetSound.playNavTab(index);
                        _selectTab(index);
                      },
                    ),
                  ),
                ),
                body: IndexedStack(
                  key: ValueKey(homeLanguage),
                  index: _selectedIndex,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      TickerMode(
                        enabled: i == _selectedIndex,
                        child: AbsorbPointer(
                          absorbing:
                              learningState is LearningLoaded &&
                              learningState.setupSaving,
                          child: _visitedTabs.contains(i)
                              ? pages[i]
                              : const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _selectTab(int index) {
    final state = context.read<LearningBloc>().state;
    if (state is LearningLoaded && state.setupSaving) return;
    if (index == _selectedIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  void _openMenuPage(BuildContext context, Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(playfulRoute(page: page));
  }
}
