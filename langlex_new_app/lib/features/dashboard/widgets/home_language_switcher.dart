import 'package:langlex_new_app/core/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';
import 'package:langlex_new_app/features/learning/pages/language_selection_page.dart';

class HomeLanguageSwitcher extends StatelessWidget {
  const HomeLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<LearningBloc, LearningState>(
        listener: (context, state) {
          if (state is LearningLoaded && state.setupError != null) {
            AppToast.error(context, state.setupError!);
          }
        },
        builder: (context, state) {
          final setup = state is LearningLoaded ? state.catalog.setup : null;
          final t = AppLocalizations(setup?.activeLanguage ?? 'English');
          final saving = state is LearningLoaded && state.setupSaving;
          return Tooltip(
            message: t.languageLabel,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Appcolors.klanguageAccent,
                foregroundColor: Appcolors.kwhitecolor,
                disabledBackgroundColor: Appcolors.klanguageSurface,
                disabledForegroundColor: Appcolors.klibraryTitle,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: setup == null || !setup.hasSelectedLanguages || saving
                  ? null
                  : () async {
                      final language = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        constraints: BoxConstraints(
                          maxWidth: 560,
                          maxHeight: MediaQuery.sizeOf(context).height * .88,
                        ),
                        backgroundColor: Appcolors.klanguageSheetBackground,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        builder: (context) =>
                            _LanguageSheet(t: t, setup: setup),
                      );
                      if (!context.mounted ||
                          language == null ||
                          language == setup.activeLanguage) {
                        return;
                      }
                      context.read<LearningBloc>().add(
                        SaveLearningSetupEvent(
                          setup.copyWith(activeLanguage: language),
                        ),
                      );
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      saving
                          ? t.saving
                          : nativeLanguageName(
                              setup?.activeLanguage ?? 'English',
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded, size: 16),
                ],
              ),
            ),
          );
        },
      );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.t, required this.setup});
  final AppLocalizations t;
  final LearningSetup setup;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Appcolors.klanguageSheetBackground, Appcolors.khomeHeaderEnd],
      ),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Appcolors.klanguageAccent.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 12, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 28,
                  color: Appcolors.klanguageAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.languageLabel,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Appcolors.klibraryTitle,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 21,
                    color: Appcolors.klibrarySubtitle,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.languageAppliesToEverything,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Appcolors.klibrarySubtitle,
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (final language in setup.selectedLanguages) ...[
                    _LanguageChoice(
                      language: language,
                      selected: language == setup.activeLanguage,
                    ),
                    if (language != setup.selectedLanguages.last)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({required this.language, required this.selected});
  final String language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final native = nativeLanguageName(language);
    final glyph = switch (language) {
      'Hindi' || 'Maithili' => 'अ',
      'Kannada' => 'ಅ',
      'Assamese' => 'অ',
      _ => 'Aa',
    };
    return Semantics(
      selected: selected,
      child: Material(
        color: selected
            ? Appcolors.klanguageSurface
            : Appcolors.kwhitecolor.withValues(alpha: .85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            width: 1.5,
            color: selected ? Appcolors.klanguageAccent : Appcolors.kwhitecolor,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(context, language),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Appcolors.klanguageAccent
                          : Appcolors.khomeBackgroundBottom,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      glyph,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Appcolors.kwhitecolor
                            : Appcolors.ksearchSelectedChip,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        native,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Appcolors.klibraryTitle,
                        ),
                      ),
                      if (native != language) ...[
                        const SizedBox(height: 3),
                        Text(
                          language,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Appcolors.klibrarySubtitle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 24,
                  color: selected
                      ? Appcolors.klanguageAccent
                      : Appcolors.klibrarySubtitle.withValues(alpha: .5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
