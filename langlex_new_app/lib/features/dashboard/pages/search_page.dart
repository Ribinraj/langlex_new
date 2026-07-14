import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/animations/app_animations.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/features/dashboard/widgets/dashboard_page_layout.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/course_detail_page.dart';
import 'package:langlex_new_app/features/learning/pages/story_reader_page.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';
import 'package:langlex_new_app/features/payments/pages/payment_checkout_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningBloc, LearningState>(
      builder: (context, state) {
        const fallback = AppLocalizations('English');
        if (state is LearningLoading || state is LearningInitial) {
          return DashboardPageLayout(
            children: [
              DashboardHeader(
                title: fallback.library,
                subtitle: fallback.librarySubtitle,
              ),
              const SizedBox(height: 24),
              _LibraryStatusPanel(message: fallback.loadingLibrary),
            ],
          );
        }

        if (state is LearningError) {
          return DashboardPageLayout(
            children: [
              DashboardHeader(
                title: fallback.library,
                subtitle: fallback.librarySubtitle,
              ),
              ResponsiveSizedBox.height(2.4),
              _LibraryStatusPanel(
                message: fallback.couldNotLoadLearningContent,
                actionLabel: fallback.retry,
                onAction: () => context.read<LearningBloc>().add(
                  const LoadLearningCatalogEvent(forceRefresh: true),
                ),
              ),
            ],
          );
        }

        final catalog = (state as LearningLoaded).catalog;
        return _buildLoadedLibrary(context, catalog);
      },
    );
  }

  Widget _buildLoadedLibrary(BuildContext context, LearningCatalog catalog) {
    final t = AppLocalizations(catalog.setup.primaryLanguage);
    final lowerQuery = _query.trim().toLowerCase();
    final courses = catalog.courses.where((course) {
      final matchesQuery =
          lowerQuery.isEmpty ||
          course.title.toLowerCase().contains(lowerQuery) ||
          course.category.toLowerCase().contains(lowerQuery) ||
          course.language.toLowerCase().contains(lowerQuery);
      final matchesFilter =
          _selectedFilter == 'All' ||
          course.language == _selectedFilter ||
          course.category == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();

    return DashboardPageLayout(
      children: [
        DashboardHeader(title: t.library, subtitle: t.librarySubtitle),
        ResponsiveSizedBox.height(2.4),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            filled: true,
            fillColor: Appcolors.kwhitecolor,
            hintText: t.searchHint,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Appcolors.kdashboardNavIcon,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Appcolors.kauthDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Appcolors.kauthDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Appcolors.kprimarycolor,
                width: 1.5,
              ),
            ),
          ),
        ),
        ResponsiveSizedBox.height(1.4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in [
                'All',
                ...catalog.languages,
                ...catalog.courses.map((course) => course.category).toSet(),
              ]) ...[
                LearningFilterChip(
                  label: filter == 'All' ? t.all : filter,
                  selected: _selectedFilter == filter,
                  onTap: () => setState(() => _selectedFilter = filter),
                ),
                const SizedBox(width: 9),
              ],
            ],
          ),
        ),
        ResponsiveSizedBox.height(2.4),
        LearningSectionHeader(title: t.coursesTitle(courses.length)),
        ResponsiveSizedBox.height(1.2),
        if (courses.isEmpty)
          _EmptyLibraryState(t: t)
        else
          for (final course in courses) ...[
            LearningCourseCard(
              course: course,
              homeLanguage: catalog.setup.primaryLanguage,
              onTap: () => _openCourse(
                context,
                course,
                catalog.plans,
                catalog.setup.primaryLanguage,
              ),
            ),
            ResponsiveSizedBox.height(1.4),
          ],
        ResponsiveSizedBox.height(1.4),
        LearningSectionHeader(title: t.stories),
        ResponsiveSizedBox.height(1.2),
        if (catalog.stories.isEmpty)
          _LibraryStatusPanel(message: t.noStoriesAvailable)
        else
          for (final story in catalog.stories) ...[
            _StoryTile(
              story: story,
              t: t,
              onTap: () => _openStory(
                context,
                story,
                catalog.plans,
                catalog.setup.primaryLanguage,
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Future<void> _openCourse(
    BuildContext context,
    LearningCourse course,
    List<SubscriptionPlan> plans,
    String homeLanguage,
  ) async {
    if (course.access == LearningAccess.premium) {
      final unlocked = await Navigator.of(context).push<bool>(
        playfulRoute(
          page: PaymentCheckoutPage(plans: plans, homeLanguage: homeLanguage),
        ),
      );
      if (unlocked != true || !context.mounted) return;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).push(
      playfulRoute(
        page: CourseDetailPage(course: course, homeLanguage: homeLanguage),
      ),
    );
  }

  Future<void> _openStory(
    BuildContext context,
    StoryItem story,
    List<SubscriptionPlan> plans,
    String homeLanguage,
  ) async {
    if (story.access == LearningAccess.premium) {
      final unlocked = await Navigator.of(context).push<bool>(
        playfulRoute(
          page: PaymentCheckoutPage(plans: plans, homeLanguage: homeLanguage),
        ),
      );
      if (unlocked != true || !context.mounted) return;
    }

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).push(
      playfulRoute(
        page: StoryReaderPage(story: story, homeLanguage: homeLanguage),
      ),
    );
  }
}

class _LibraryStatusPanel extends StatelessWidget {
  const _LibraryStatusPanel({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Appcolors.kauthDivider),
      ),
      child: Column(
        children: [
          ResponsiveText(
            message,
            fontSize: 14,
            weight: FontWeight.w800,
            color: Appcolors.kdashboardMutedText,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.story, required this.t, required this.onTap});

  final StoryItem story;
  final AppLocalizations t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashboardActionTile(
      icon: Icons.menu_book_rounded,
      title: story.title,
      subtitle:
          '${story.language} • ${story.grade} • ${story.minutes} ${t.minutesShort}',
      accent: Appcolors.kmetricInventory,
      surface: Appcolors.kmetricInventorySurface,
      onTap: onTap,
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Appcolors.kauthDivider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Appcolors.kdashboardMutedIcon,
            size: 34,
          ),
          SizedBox(height: 10),
          ResponsiveText(
            t.noMatchingLessons,
            fontSize: 15,
            weight: FontWeight.w900,
            color: Appcolors.ktextdark,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}
