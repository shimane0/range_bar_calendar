import 'package:flutter/foundation.dart';

import 'range_bar_segment.dart';
import 'range_calendar_event.dart';

/// Result of laying out events for a single visible page.
@immutable
class RangeBarLayoutResult<T> {
  const RangeBarLayoutResult({
    required this.segments,
    required this.segmentsByWeek,
    required this.weekLaneCounts,
    required this.hiddenCounts,
    required this.hiddenEventsByDay,
  });

  /// All segments to draw.
  final List<RangeBarSegment<T>> segments;

  /// Pre-bucketed view of [segments] indexed by `weekIndex`.
  ///
  /// `segmentsByWeek[w]` is the list of segments belonging to week `w` in
  /// the visible page. Renderers can iterate this directly instead of
  /// filtering [segments] with `where(weekIndex == w)` for each row.
  final List<List<RangeBarSegment<T>>> segmentsByWeek;

  /// For each week index, the number of lanes actually used (used for
  /// computing row height).
  final List<int> weekLaneCounts;

  /// Map of normalized day -> count of hidden events overflowing that day.
  final Map<DateTime, int> hiddenCounts;

  /// Map of normalized day -> the actual hidden events on that day.
  final Map<DateTime, List<RangeCalendarEvent<T>>> hiddenEventsByDay;
}
