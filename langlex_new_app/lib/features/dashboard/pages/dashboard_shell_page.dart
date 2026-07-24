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
import 'package:langlex_new_app/features/dashboard/pages/practice_page.dart';
import 'package:langlex_new_app/features/dashboard/pages/profile_page.dart';
import 'package:langlex_new_app/features/dashboard/widgets/custom_bottom_nav_bar.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/pages/learning_setup_page.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class DashboardShellPage extends StatefulWidget {
  const DashboardShellPage({super.key});

  @override
  State<DashboardShellPage> createState() => _DashboardShellPageState();
}

class _DashboardShellPageState extends State<DashboardShellPage> {
  int _selectedIndex = 0;
  bool _setupGateOpened = false;

  @override
  void initState() {
    super.initState();
    context.read<LearningBloc>().add(const LoadLearningCatalogEvent());
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    final isMobile = ResponsiveUtils.isMobile(context);
    final learningState = context.watch<LearningBloc>().state;
    final homeLanguage = learningState is LearningLoaded
        ? learningState.catalog.setup.primaryLanguage
        : 'English';
    final t = AppLocalizations(homeLanguage);
    final tabs = [
      _DashboardTab(
        item: BottomNavBarItem(
          icon: Icons.home_rounded,
          label: t.home,
          assetPath: 'assets/icons/learn (1).svg',
        ),
        page: const HomePage(),
      ),
      _DashboardTab(
        item: BottomNavBarItem(
          icon: Icons.menu_book_rounded,
          label: t.learn,
          assetPath: 'assets/icons/open-book.svg',
        ),
        page: const LearnPage(),
      ),
      _DashboardTab(
        item: BottomNavBarItem(
          icon: Icons.extension_rounded,
          label: t.practice,
          assetPath: 'assets/icons/best-practice.svg',
        ),
        page: const PracticePage(),
      ),
      _DashboardTab(
        item: BottomNavBarItem(
          icon: Icons.person_rounded,
          label: t.profile,
          assetPath: 'assets/icons/account.svg',
        ),
        page: const ProfilePage(),
      ),
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
        BlocListener<LearningBloc, LearningState>(
          listener: (context, state) {
            if (state is! LearningLoaded) return;
            if (state.catalog.setup.isConfigured || _setupGateOpened) return;

            _setupGateOpened = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                playfulRoute(
                  page: LearningSetupPage(
                    catalog: state.catalog,
                    requiredSetup: true,
                  ),
                ),
              );
            });
          },
        ),
      ],
      child: Scaffold(
        extendBody: true,
        backgroundColor: Appcolors.kscreenWarmBackground,
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
              items: [for (final tab in tabs) tab.item],
              selectedIndex: _selectedIndex,
              onTap: (index) {
                LearningAssetSound.playNavTab(index);
                if (index == _selectedIndex) return;
                setState(() => _selectedIndex = index);
              },
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [for (final tab in tabs) tab.page],
          ),
        ),
      ),
    );
  }
}

class _DashboardTab {
  const _DashboardTab({required this.item, required this.page});

  final BottomNavBarItem item;
  final Widget page;
}
