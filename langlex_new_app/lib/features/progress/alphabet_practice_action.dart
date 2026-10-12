import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/app_toast.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';
import 'progress_widgets.dart';

class AlphabetPracticeAction extends StatefulWidget {
  const AlphabetPracticeAction({
    super.key,
    required this.contentKey,
    required this.language,
    required this.exampleIds,
  });
  final String contentKey, language;
  final List<int> exampleIds;
  @override
  State<AlphabetPracticeAction> createState() => _AlphabetPracticeActionState();
}

class _AlphabetPracticeActionState extends State<AlphabetPracticeAction> {
  bool _saving = false;
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final t = AppLocalizations(widget.language);
    try {
      final repo = context.read<LearningRepository>();
      for (final id in widget.exampleIds) {
        await repo.recordContentItem(
          contentType: 'alphabet',
          contentKey: widget.contentKey,
          itemKey: 'alphabet-$id',
          position: 0,
          totalItems: widget.exampleIds.length,
        );
      }
      if (!mounted) return;
      if (repo.progress.pending > 0) {
        AppToast.success(context, t.progressSavedOnDevice);
      }
      await repo.progress.refresh(widget.language);
    } catch (_) {
      if (mounted) AppToast.error(context, t.couldNotLoadLearningContent);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations(widget.language);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopicProgressBadge(
              type: 'alphabet',
              contentKey: widget.contentKey,
              language: widget.language,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving || widget.exampleIds.isEmpty ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_saving ? t.loading : t.markPracticed),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          ],
        ),
      ),
    );
  }
}
