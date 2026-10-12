import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_bloc.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_event.dart';
import 'package:langlex_new_app/features/learning/blocs/learning_bloc/learning_state.dart';
import 'package:langlex_new_app/features/learning/models/learning_models.dart';

String nativeLanguageName(String language) => switch (language) {
  'Hindi' => 'हिन्दी',
  'Kannada' => 'ಕನ್ನಡ',
  'Maithili' => 'मैथिली',
  'Assamese' => 'অসমীয়া',
  _ => language,
};

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key, required this.catalog});
  final LearningCatalog catalog;
  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final List<String> _selected = [];
  @override
  Widget build(BuildContext context) {
    final state = context.watch<LearningBloc>().state;
    final saving = state is LearningLoaded && state.setupSaving;
    final t = AppLocalizations(_selected.firstOrNull ?? 'English');
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Appcolors.khomeBackgroundTop,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Appcolors.khomeBackgroundTop,
                Appcolors.khomeBackgroundBottom,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.translate_rounded,
                              size: 30,
                              color: Appcolors.kprimarycolor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t.chooseThreeLanguages,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Appcolors.klibraryTitle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.threeLanguagesDescription,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Appcolors.ktextgreycolor,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: i < _selected.length
                                        ? Appcolors.kprimarycolor
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              if (i < 2) const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_selected.length} / 3',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Appcolors.klibraryTitle,
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (final language in widget.catalog.languages) ...[
                          Builder(
                            builder: (context) {
                              final selected = _selected.contains(language);
                              final enabled =
                                  !saving && (selected || _selected.length < 3);
                              return Material(
                                color: selected
                                    ? const Color(0xFFF5EFFF)
                                    : Colors.white.withValues(alpha: .85),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: selected
                                        ? Appcolors.kprimarycolor
                                        : Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CheckboxListTile(
                                  key: ValueKey('language-$language'),
                                  value: selected,
                                  activeColor: Appcolors.kprimarycolor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    nativeLanguageName(language),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(language),
                                  onChanged: enabled
                                      ? (_) => setState(() {
                                          selected
                                              ? _selected.remove(language)
                                              : _selected.add(language);
                                        })
                                      : null,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (state is LearningLoaded && state.setupError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              state.setupError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Text(
                          t.languagesPermanentNote,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Appcolors.ktextgreycolor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Appcolors.kprimarycolor,
                            minimumSize: const Size.fromHeight(54),
                          ),
                          onPressed: _selected.length == 3 && !saving
                              ? () {
                                  context.read<LearningBloc>().add(
                                    SaveLearningSetupEvent(
                                      widget.catalog.setup.copyWith(
                                        selectedLanguages: List.unmodifiable(
                                          _selected,
                                        ),
                                        activeLanguage: _selected.first,
                                        isConfigured: true,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            saving ? t.saving : t.startLearning,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
