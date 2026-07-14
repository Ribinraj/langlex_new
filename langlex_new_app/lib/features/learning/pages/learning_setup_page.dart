import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/core/constants.dart';
import 'package:langlex_new_app/core/responsiveutils.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/widgets/learning_widgets.dart';

class LearningSetupPage extends StatefulWidget {
  const LearningSetupPage({
    super.key,
    required this.catalog,
    this.requiredSetup = false,
  });

  final LearningCatalog catalog;
  final bool requiredSetup;

  @override
  State<LearningSetupPage> createState() => _LearningSetupPageState();
}

class _LearningSetupPageState extends State<LearningSetupPage> {
  late final TextEditingController _childNameController;
  late String _ageGroup;
  late String _primaryLanguage;
  late String _learningLanguage;
  late String _level;
  late int _dailyGoalMinutes;
  late int? _planId;
  late Set<String> _interests;
  bool _allowClose = false;

  LearningCatalog get catalog => widget.catalog;

  @override
  void initState() {
    super.initState();
    final setup = catalog.setup;
    _childNameController = TextEditingController(text: setup.childName);
    _ageGroup = _safeValue(setup.ageGroup, LearningSetupOptions.ageGroups);
    _primaryLanguage = _safeValue(setup.primaryLanguage, catalog.languages);
    _learningLanguage = _safeValue(setup.learningLanguage, catalog.languages);
    _level = _safeValue(setup.level, LearningSetupOptions.academicLevels);
    _dailyGoalMinutes = setup.dailyGoalMinutes;
    _planId = setup.planId;
    _interests = setup.interests.toSet();
  }

  @override
  void dispose() {
    _childNameController.dispose();
    super.dispose();
  }

  String _safeValue(String value, List<String> options) {
    if (options.contains(value)) return value;
    return options.isEmpty ? value : options.first;
  }

  void _save() {
    final setup = catalog.setup.copyWith(
      childName: _childNameController.text.trim().isEmpty
          ? AppLocalizations(_primaryLanguage).langLexLearner
          : _childNameController.text.trim(),
      ageGroup: _ageGroup,
      primaryLanguage: _primaryLanguage,
      learningLanguage: _learningLanguage,
      level: _level,
      interests: _interests.toList()..sort(),
      dailyGoalMinutes: _dailyGoalMinutes,
      planId: _planId,
      isConfigured: true,
    );

    context.read<LearningBloc>().add(SaveLearningSetupEvent(setup));
  }

  @override
  Widget build(BuildContext context) {
    final interestOptions =
        catalog.courses
            .map((course) => course.category)
            .where((category) => category.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final t = AppLocalizations(_primaryLanguage);

    return BlocListener<LearningBloc, LearningState>(
      listener: (context, state) {
        if (state is! LearningLoaded) return;
        if (state.setupSaved) {
          setState(() => _allowClose = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.setupSaved)));
          Navigator.of(context).pop();
        }
        if (state.setupError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.couldNotSaveLearningSetup)));
        }
      },
      child: PopScope(
        canPop: !widget.requiredSetup || _allowClose,
        child: Scaffold(
          backgroundColor: Appcolors.kscreenWarmBackground,
          appBar: AppBar(
            title: Text(t.learningSetup),
            automaticallyImplyLeading: !widget.requiredSetup,
          ),
          bottomNavigationBar: _SaveSetupBar(t: t, onSave: _save),
          body: SingleChildScrollView(
            padding: ResponsiveUtils.pagePadding(
              context,
              mobileHorizontalPercent: 6,
              tabletHorizontal: 42,
              desktopHorizontal: 56,
              top: 10,
              bottom: 112,
            ),
            child: ResponsiveUtils.constrainWidth(
              context: context,
              maxWidth: 680,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.requiredSetup) ...[
                    _RequiredSetupIntro(t: t),
                    ResponsiveSizedBox.height(1.6),
                  ],
                  _SetupCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LearningSectionHeader(title: t.studentProfile),
                        ResponsiveSizedBox.height(1.2),
                        TextField(
                          controller: _childNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(t.childName),
                        ),
                        ResponsiveSizedBox.height(1.4),
                        _DropdownField(
                          label: t.ageGroup,
                          value: _ageGroup,
                          items: LearningSetupOptions.ageGroups,
                          onChanged: (value) =>
                              setState(() => _ageGroup = value),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveSizedBox.height(1.6),
                  _SetupCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LearningSectionHeader(title: t.languagesAndLevel),
                        ResponsiveSizedBox.height(1.2),
                        _DropdownField(
                          label: t.homeLanguage,
                          value: _primaryLanguage,
                          items: catalog.languages,
                          onChanged: (value) =>
                              setState(() => _primaryLanguage = value),
                        ),
                        ResponsiveSizedBox.height(1.4),
                        _DropdownField(
                          label: t.learningLanguage,
                          value: _learningLanguage,
                          items: catalog.languages,
                          onChanged: (value) =>
                              setState(() => _learningLanguage = value),
                        ),
                        ResponsiveSizedBox.height(1.4),
                        _DropdownField(
                          label: t.level,
                          value: _level,
                          items: LearningSetupOptions.academicLevels,
                          onChanged: (value) => setState(() => _level = value),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveSizedBox.height(1.6),
                  _SetupCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LearningSectionHeader(title: t.interests),
                        ResponsiveSizedBox.height(1.2),
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: [
                            for (final interest in interestOptions)
                              LearningFilterChip(
                                label: interest,
                                selected: _interests.contains(interest),
                                onTap: () {
                                  setState(() {
                                    if (_interests.contains(interest)) {
                                      _interests.remove(interest);
                                    } else {
                                      _interests.add(interest);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ResponsiveSizedBox.height(1.6),
                  _SetupCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LearningSectionHeader(
                          title: t.dailyGoal(_dailyGoalMinutes),
                        ),
                        Slider(
                          value: _dailyGoalMinutes.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: t.dailyGoal(_dailyGoalMinutes),
                          onChanged: (value) =>
                              setState(() => _dailyGoalMinutes = value.round()),
                        ),
                        ResponsiveSizedBox.height(1.2),
                        _DropdownField<int?>(
                          label: t.plan,
                          value: _planId,
                          items: [for (final plan in catalog.plans) plan.id],
                          labelFor: (id) {
                            final plan = catalog.plans.firstWhere(
                              (item) => item.id == id,
                              orElse: () => catalog.plans.first,
                            );
                            return plan.name;
                          },
                          onChanged: (value) => setState(() => _planId = value),
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
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Appcolors.kwhitecolor,
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
    );
  }
}

class _SaveSetupBar extends StatelessWidget {
  const _SaveSetupBar({required this.t, required this.onSave});

  final AppLocalizations t;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.isMobile(context) ? 20.0 : 42.0;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Appcolors.kscreenWarmBackground.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(
              color: Appcolors.kprimarycolor.withValues(alpha: 0.08),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Appcolors.ktextdark.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            12,
          ),
          child: Center(
            heightFactor: 1,
            child: BlocBuilder<LearningBloc, LearningState>(
              builder: (context, state) {
                final saving = state is LearningLoaded && state.setupSaving;
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : onSave,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(saving ? t.saving : t.saveSetup),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RequiredSetupIntro extends StatelessWidget {
  const _RequiredSetupIntro({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Appcolors.kauthSoftGreen,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Appcolors.kdashboardTeal.withValues(alpha: 0.18),
        ),
      ),
      child: ResponsiveText(
        t.requiredSetupIntro,
        fontSize: 14,
        weight: FontWeight.w900,
        color: Appcolors.ktextdark,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelFor,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelFor;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Appcolors.kwhitecolor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(labelFor?.call(item) ?? item.toString()),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Appcolors.kauthDivider),
      ),
      child: child,
    );
  }
}
