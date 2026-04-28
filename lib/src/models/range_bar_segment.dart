import 'package:flutter/foundation.dart';

import 'range_calendar_event.dart';

/// A clipped portion of a [RangeCalendarEvent] that fits within a single
/// week row of the visible grid.
@immutable
class RangeBarSegment<T> {
  const RangeBarSegment({
    required this.event,
    required this.weekIndex,
    required this.startCol,
    required this.endCol,
    required this.lane,
    required this.startsInsideVisibleRange,
    required this.endsInsideVisibleRange,
    required this.startsAtEventStart,
    required this.endsAtEventEnd,
  });

  /// The original event this segment was clipped from.
  final RangeCalendarEvent<T> event;

  /// Index of the week row in the visible grid (0-based).
  final int weekIndex;

  /// Starting column (0..6). Always relative to the visible grid's
  /// `startingDayOfWeek`.
  final int startCol;

  /// Ending column inclusive (0..6).
  final int endCol;

  /// Vertical lane within the week row (0-based, 0 = topmost).
  final int lane;

  /// Whether this segment's left edge is the actual start of the event
  /// AND the start day is visible. Used to draw a rounded left edge.
  final bool startsInsideVisibleRange;

  /// Whether this segment's right edge is the actual end of the event
  /// AND the end day is visible. Used to draw a rounded right edge.
  final bool endsInsideVisibleRange;

  /// Whether the segment's start is the event's true start (regardless of
  /// visibility). Used to decide whether to render the title.
  final bool startsAtEventStart;

  /// Whether the segment's end is the event's true end.
  final bool endsAtEventEnd;

  /// Number of columns this segment spans.
  int get columnSpan => endCol - startCol + 1;
}
