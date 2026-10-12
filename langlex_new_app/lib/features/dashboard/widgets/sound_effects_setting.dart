import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/app_localizations.dart';
import 'package:langlex_new_app/core/app_toast.dart';
import 'package:langlex_new_app/core/colors.dart';
import 'package:langlex_new_app/features/learning/widgets/media_widgets.dart';

class SoundEffectsSetting extends StatefulWidget {
  const SoundEffectsSetting({super.key, required this.t});
  final AppLocalizations t;

  @override
  State<SoundEffectsSetting> createState() => _SoundEffectsSettingState();
}

class _SoundEffectsSettingState extends State<SoundEffectsSetting> {
  bool _saving = false;

  Future<void> _change(bool value) async {
    setState(() => _saving = true);
    try {
      await LearningAssetSound.setEnabled(value);
    } catch (_) {
      if (mounted) AppToast.error(context, widget.t.soundPreferenceSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: LearningAssetSound.enabled,
    builder: (context, enabled, _) => Material(
      color: Appcolors.kwhitecolor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Appcolors.kauthDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: _saving ? null : _change,
        activeThumbColor: Appcolors.klibraryTitle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        title: Row(
          children: [
            Icon(
              enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Appcolors.klibraryTitle,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.t.soundEffects,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Appcolors.ktextdark,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            widget.t.soundEffectsHint,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Appcolors.kdashboardMutedText,
            ),
          ),
        ),
      ),
    ),
  );
}
