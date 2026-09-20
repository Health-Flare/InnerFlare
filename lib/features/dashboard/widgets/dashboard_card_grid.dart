import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/models/dashboard_card.dart';

/// The dashboard's masonry grid (docs/features/dashboard_grid_layout
/// .feature) — shared between the real dashboard (read-only) and Customize
/// dashboard's live resize preview, so both render cards identically and a
/// resize made in the preview is confirmed by the exact layout engine the
/// dashboard itself uses.
class DashboardCardGrid extends StatelessWidget {
  const DashboardCardGrid({
    super.key,
    required this.instances,
    required this.cardBuilder,
    this.resizable = false,
  });

  final List<DashboardCardInstance> instances;
  final Widget Function(DashboardCardInstance instance) cardBuilder;

  /// When true, each tile gets a draggable corner grip that resizes it
  /// (docs/features/dashboard_grid_layout.feature, "A card's cell size can
  /// be adjusted from Customize dashboard"). The real dashboard passes
  /// false — resizing only happens from the Customize preview, never on
  /// the primary, deliberately uncluttered dashboard.
  final bool resizable;

  @override
  Widget build(BuildContext context) {
    if (instances.isEmpty) return const SizedBox.shrink();
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final instance in instances)
          _buildTile(context, instance, cardBuilder(instance)),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context,
    DashboardCardInstance instance,
    Widget card,
  ) {
    final columnSpan = instance.columnSpan;
    final rowSpan = instance.rowSpan;

    // `Stack`'s non-positioned child (`card`) determines the Stack's own
    // size, and a Stack under `StackFit.loose` gives that child a LOOSE
    // width — so without forcing it to stretch, a content-sized card (e.g.
    // DashboardChip, which was only ever single-column before resizing
    // existed) shrinks the whole Stack to its own narrow content width
    // instead of the tile's full (possibly two-column) width, stranding
    // the resize handle out past the card's visible right edge.
    final child = resizable
        ? Stack(
            children: [
              SizedBox(width: double.infinity, child: card),
              Positioned(
                right: 4,
                bottom: 4,
                child: _ResizeHandle(instance: instance),
              ),
            ],
          )
        : card;

    // A card still at its default row span keeps the exact tile type used
    // before resizing existed — auto-height from content — so no untouched
    // card's default look changes. Only a card resized taller switches to
    // a fixed pixel height, `Center`-ed so the card doesn't need any
    // internal layout changes to sit nicely in the extra room.
    if (rowSpan > 1) {
      return StaggeredGridTile.extent(
        crossAxisCellCount: columnSpan,
        mainAxisExtent: instance.kind.approximateRowHeight * rowSpan,
        child: Center(child: child),
      );
    }
    return StaggeredGridTile.fit(crossAxisCellCount: columnSpan, child: child);
  }
}

/// A pixel distance the user must drag past, on a given axis, before that
/// axis's span steps by one unit — keeps the gesture from stepping on every
/// tiny wobble of a real touch.
const _dragStepPx = 56.0;

/// A bottom-right corner grip that resizes the card it's attached to. Uses
/// long-press-then-drag rather than a plain pan so it doesn't fight the
/// surrounding scroll gesture — the same idiom
/// `ReorderableDragStartListener` relies on for reordering.
class _ResizeHandle extends ConsumerStatefulWidget {
  const _ResizeHandle({required this.instance});

  final DashboardCardInstance instance;

  @override
  ConsumerState<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends ConsumerState<_ResizeHandle> {
  // `LongPressMoveUpdateDetails.offsetFromOrigin` is cumulative from the
  // start of the gesture, not a per-update delta — these track how much of
  // that cumulative offset has already been "spent" on a step, so a drag
  // can cross more than one threshold in a single continuous gesture.
  double _consumedDx = 0;
  double _consumedDy = 0;

  // The span this gesture is stepping from — tracked locally (rather than
  // read back off `widget.instance`) so a fast drag that crosses more than
  // one threshold before the provider's rebuild reaches this widget still
  // steps correctly instead of repeatedly comparing against a stale span.
  late int _columnSpan = widget.instance.columnSpan;
  late int _rowSpan = widget.instance.rowSpan;

  void _onLongPressStart(LongPressStartDetails details) {
    _consumedDx = 0;
    _consumedDy = 0;
    _columnSpan = widget.instance.columnSpan;
    _rowSpan = widget.instance.rowSpan;
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final notifier = ref.read(dashboardCardPreferencesProvider.notifier);
    final id = widget.instance.id;

    // A single move event (e.g. a fast or programmatic drag) can overshoot
    // more than one threshold at once, so each axis loops until either the
    // remaining offset is under threshold or that axis has hit its bound.
    while ((details.offsetFromOrigin.dx - _consumedDx).abs() >= _dragStepPx) {
      final step = (details.offsetFromOrigin.dx - _consumedDx) > 0 ? 1 : -1;
      final newColumnSpan = (_columnSpan + step).clamp(
        dashboardGridMinColumnSpan,
        dashboardGridMaxColumnSpan,
      );
      _consumedDx += _dragStepPx * step;
      if (newColumnSpan == _columnSpan) break;
      _columnSpan = newColumnSpan;
      notifier.resizeCard(id, columnSpan: newColumnSpan);
    }

    while ((details.offsetFromOrigin.dy - _consumedDy).abs() >= _dragStepPx) {
      final step = (details.offsetFromOrigin.dy - _consumedDy) > 0 ? 1 : -1;
      final newRowSpan = (_rowSpan + step).clamp(
        dashboardGridMinRowSpan,
        dashboardGridMaxRowSpan,
      );
      _consumedDy += _dragStepPx * step;
      if (newRowSpan == _rowSpan) break;
      _rowSpan = newRowSpan;
      notifier.resizeCard(id, rowSpan: newRowSpan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('resize-handle-${widget.instance.id}'),
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.open_in_full_rounded,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
