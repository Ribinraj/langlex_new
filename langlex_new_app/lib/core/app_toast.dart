import 'dart:async';

import 'package:flutter/material.dart';
import 'package:langlex_new_app/core/colors.dart';

enum AppToastType { info, success, error }

/// Shared, non-blocking feedback above routes, sheets and dialogs.
class AppToast {
  AppToast._();

  static final _active = Expando<_ToastEntry>();

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted || message.trim().isEmpty) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _active[overlay]?.remove();
    final toast = _ToastEntry(overlay);
    toast.entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        type: type,
        duration: duration,
        onDismiss: toast.remove,
        onUnmount: () => scheduleMicrotask(toast.remove),
      ),
    );
    _active[overlay] = toast;
    overlay.insert(toast.entry);
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppToastType.error);

  static void dismiss(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay != null) _active[overlay]?.remove();
  }
}

class _ToastEntry {
  _ToastEntry(this.overlay);

  final OverlayState overlay;
  late final OverlayEntry entry;
  bool _removed = false;

  void remove() {
    if (_removed) return;
    _removed = true;
    entry.remove();
    entry.dispose();
    if (identical(AppToast._active[overlay], this)) {
      AppToast._active[overlay] = null;
    }
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    required this.onUnmount,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback onUnmount;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Animation<Offset> _slide;
  final _messageScroll = ScrollController();
  Timer? _timer;
  bool _started = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this);
    _slide = Tween(
      begin: const Offset(0, -.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    _animation.duration = media.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);
    _animation.reverseDuration = media.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 140);
    if (!_started) {
      _started = true;
      _animation.forward();
    }
    _timer?.cancel();
    // Screen-reader users can dismiss the message when finished reading.
    if (!media.accessibleNavigation && !_closing) {
      _timer = Timer(widget.duration, _dismiss);
    }
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    try {
      await _animation.reverse().orCancel;
      if (mounted) widget.onDismiss();
    } on TickerCanceled {
      // Replacement or navigation can dispose an outgoing toast.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    _messageScroll.dispose();
    widget.onUnmount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (widget.type) {
      AppToastType.success => (
        Appcolors.kdashboardOnlineText,
        Icons.check_rounded,
      ),
      AppToastType.error => (
        Appcolors.kmetricLowStock,
        Icons.error_outline_rounded,
      ),
      AppToastType.info => (
        Appcolors.klibraryTitle,
        Icons.info_outline_rounded,
      ),
    };
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _animation,
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    child: Material(
                      key: const ValueKey('app-toast'),
                      color: color,
                      elevation: 8,
                      shadowColor: color.withValues(alpha: .28),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: Appcolors.kwhitecolor.withValues(alpha: .16),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Appcolors.kwhitecolor
                                    .withValues(alpha: .16),
                                child: Icon(
                                  icon,
                                  color: Appcolors.kwhitecolor,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      (MediaQuery.sizeOf(context).height * .3)
                                          .clamp(48, 120),
                                ),
                                child: RawScrollbar(
                                  thumbColor: Appcolors.kwhitecolor.withValues(
                                    alpha: .65,
                                  ),
                                  radius: const Radius.circular(99),
                                  thickness: 3,
                                  controller: _messageScroll,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _messageScroll,
                                    child: Text(
                                      widget.message,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Appcolors.kwhitecolor,
                                            fontSize: 14,
                                            height: 1.4,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: _dismiss,
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: Appcolors.kwhitecolor,
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
        ),
      ),
    );
  }
}
