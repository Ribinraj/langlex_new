import 'package:langlex_new_app/core/widgets/app_empty_state.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:langlex_new_app/features/learning/learning_repo.dart';

/// Appends bounded API pages when the tail approaches the enclosing viewport.
/// Change the key when filters change. The parent supplies the scroll view.
class PagedLearningList<T> extends StatefulWidget {
  const PagedLearningList({
    super.key,
    required this.load,
    required this.builder,
    this.separatePages = false,
    this.loadingIndicator,
    this.emptyState,
  });
  final Future<CatalogPage<T>> Function(int page) load;
  final Widget Function(BuildContext context, CatalogPage<T> page) builder;

  /// Keep practice sessions stable while more sessions are appended below them.
  final bool separatePages;

  /// Optional placeholder shown while the first or a subsequent page loads.
  final Widget? loadingIndicator;

  /// Replaces both the content builder and result count when no items exist.
  final Widget? emptyState;
  @override
  State<PagedLearningList<T>> createState() => _PagedLearningListState<T>();
}

class _PagedLearningListState<T> extends State<PagedLearningList<T>> {
  final _pages = <CatalogPage<T>>[];
  final _tail = GlobalKey();
  ScrollPosition? _position;
  bool _loading = false;
  bool _failed = false;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_checkTail);
      _position = position;
      _position?.addListener(_checkTail);
    }
    _scheduleCheck();
  }

  @override
  void dispose() {
    _position?.removeListener(_checkTail);
    super.dispose();
  }

  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkTail();
    });
  }

  void _checkTail() {
    if (_loading || _failed || _ended || !mounted) return;
    final position = _position;
    final tail = _tail.currentContext?.findRenderObject();
    if (position == null ||
        !position.hasContentDimensions ||
        tail == null ||
        !tail.attached) {
      return;
    }
    final viewport = RenderAbstractViewport.maybeOf(tail);
    if (viewport == null) return;
    final distance =
        viewport.getOffsetToReveal(tail, 0).offset - position.pixels;
    if (distance <= position.viewportDimension + 200) _load();
  }

  Future<void> _load() async {
    if (_loading || _ended) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await widget.load(
        _pages.isEmpty ? 1 : _pages.last.page + 1,
      );
      if (!mounted) return;
      setState(() {
        _pages.add(result);
        _loading = false;
        _ended = !result.hasMore || result.items.isEmpty;
      });
      _scheduleCheck();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _pages.lastOrNull;
    final hasItems = _pages.any((page) => page.items.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.separatePages) ...[
          for (final page in _pages)
            if (page.items.isNotEmpty) widget.builder(context, page),
        ] else if (last != null && hasItems)
          widget.builder(
            context,
            CatalogPage<T>(
              items: _pages.expand((page) => page.items).toList(),
              page: last.page,
              limit: last.limit,
              total: last.total,
            ),
          ),
        if (!_loading && !_failed && !hasItems && last != null)
          widget.emptyState ??
              const AppEmptyState(
                title: 'Nothing here just yet',
                message: 'Try another category or come back later.',
              ),
        Padding(
          key: _tail,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _failed
              ? Column(
                  children: [
                    Text(
                      _pages.isEmpty
                          ? 'Could not load content.'
                          : 'Could not load more. Your place is saved.',
                    ),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                )
              : _loading
              ? widget.loadingIndicator ??
                    const CatalogShimmer(
                      kind: CatalogSkeleton.courses,
                      label: 'Loading content',
                      itemCount: 2,
                    )
              : !hasItems
              ? const SizedBox.shrink()
              : Text(
                  _ended
                      ? 'End of results'
                      : '${_pages.fold<int>(0, (count, page) => count + page.items.length)} of ${last!.total}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        ),
      ],
    );
  }
}
