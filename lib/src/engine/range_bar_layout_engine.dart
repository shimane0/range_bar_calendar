import '../models/range_bar_layout_result.dart';
import '../models/range_bar_segment.dart';
import '../models/range_calendar_event.dart';
import '../utils/date_utils.dart';

/// Pure-Dart layout engine that turns a list of [RangeCalendarEvent]s and
/// a list of visible days into a set of [RangeBarSegment]s with assigned
/// lanes.
///
/// Algorithm overview:
///
/// 1. Filter events that intersect the visible range and have valid date
///    order (`end >= start`).
/// 2. Stable-sort by priority (desc), start (asc), duration (desc), id (asc).
/// 3. For each event, walk weeks left-to-right. Compute a clipped segment
///    per intersecting week. Assign the smallest free lane in
///    `[0, maxBarsPerDay)`, preferring the lane used by the same event in
///    the previous week (continuity).
/// 4. If no lane fits, the segment is hidden and contributes to the
///    `+N` indicator on each of its days.
class RangeBarLayoutEngine {
  const RangeBarLayoutEngine._();

  /// Compute a layout result for the given inputs.
  ///
  /// [visibleDays] must be a list whose length is a positive multiple of 7
  /// and whose first day's weekday equals [startingDayOfWeek].
  static RangeBarLayoutResult<T> calculate<T>({
    required List<RangeCalendarEvent<T>> events,
    required List<DateTime> visibleDays,
    required int startingDayOfWeek,
    required int maxBarsPerDay,
  }) {
    assert(visibleDays.isNotEmpty, 'visibleDays must not be empty');
    assert(
      visibleDays.length % 7 == 0,
      'visibleDays.length must be a multiple of 7',
    );
    assert(maxBarsPerDay >= 1, 'maxBarsPerDay must be >= 1');
    assert(
      startingDayOfWeek >= DateTime.monday &&
          startingDayOfWeek <= DateTime.sunday,
      'startingDayOfWeek must be 1..7',
    );

    final DateTime visibleStart = normalizeDate(visibleDays.first);
    final DateTime visibleEnd = normalizeDate(visibleDays.last);
    final int weekCount = visibleDays.length ~/ 7;

    // Filter to events intersecting the visible range with valid dates.
    final List<_NormalizedEvent<T>> filtered = <_NormalizedEvent<T>>[];
    for (final RangeCalendarEvent<T> e in events) {
      final DateTime s = normalizeDate(e.start);
      final DateTime ed = normalizeDate(e.end);
      if (compareDate(ed, s) < 0) {
        continue;
      }
      if (compareDate(ed, visibleStart) < 0) {
        continue;
      }
      if (compareDate(s, visibleEnd) > 0) {
        continue;
      }
      filtered.add(_NormalizedEvent<T>(e, s, ed));
    }

    filtered.sort((_NormalizedEvent<T> a, _NormalizedEvent<T> b) {
      final int byPriority = b.event.priority.compareTo(a.event.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      final int byStart = compareDate(a.start, b.start);
      if (byStart != 0) {
        return byStart;
      }
      final int aDur = daysBetweenInclusive(a.start, a.end);
      final int bDur = daysBetweenInclusive(b.start, b.end);
      final int byDur = bDur.compareTo(aDur);
      if (byDur != 0) {
        return byDur;
      }
      return a.event.id.compareTo(b.event.id);
    });

    // Per-week lane occupancy grid: [week][lane][col].
    final List<List<List<bool>>> occupied = List<List<List<bool>>>.generate(
      weekCount,
      (_) => List<List<bool>>.generate(
        maxBarsPerDay,
        (_) => List<bool>.filled(7, false),
      ),
    );

    final List<RangeBarSegment<T>> segments = <RangeBarSegment<T>>[];
    final Map<DateTime, int> hiddenCounts = <DateTime, int>{};
    final Map<DateTime, List<RangeCalendarEvent<T>>> hiddenEventsByDay =
        <DateTime, List<RangeCalendarEvent<T>>>{};
    final List<int> weekLaneCounts = List<int>.filled(weekCount, 0);

    for (final _NormalizedEvent<T> ne in filtered) {
      int? prevLane;
      for (int w = 0; w < weekCount; w++) {
        final DateTime weekStart = visibleDays[w * 7];
        final DateTime weekEnd = visibleDays[w * 7 + 6];
        if (compareDate(ne.end, weekStart) < 0) {
          continue;
        }
        if (compareDate(ne.start, weekEnd) > 0) {
          continue;
        }

        final DateTime segStart =
            compareDate(ne.start, weekStart) >= 0 ? ne.start : weekStart;
        final DateTime segEnd =
            compareDate(ne.end, weekEnd) <= 0 ? ne.end : weekEnd;
        final int startCol = columnOfDay(segStart, startingDayOfWeek);
        final int endCol = columnOfDay(segEnd, startingDayOfWeek);

        bool fits(int lane) {
          if (lane < 0 || lane >= maxBarsPerDay) {
            return false;
          }
          for (int c = startCol; c <= endCol; c++) {
            if (occupied[w][lane][c]) {
              return false;
            }
          }
          return true;
        }

        int? assigned;
        if (prevLane != null && fits(prevLane)) {
          assigned = prevLane;
        } else {
          for (int lane = 0; lane < maxBarsPerDay; lane++) {
            if (fits(lane)) {
              assigned = lane;
              break;
            }
          }
        }

        if (assigned == null) {
          for (int c = startCol; c <= endCol; c++) {
            final DateTime day = visibleDays[w * 7 + c];
            hiddenCounts[day] = (hiddenCounts[day] ?? 0) + 1;
            (hiddenEventsByDay[day] ??= <RangeCalendarEvent<T>>[]).add(
              ne.event,
            );
          }
          prevLane = null;
          continue;
        }

        for (int c = startCol; c <= endCol; c++) {
          occupied[w][assigned][c] = true;
        }
        if (assigned + 1 > weekLaneCounts[w]) {
          weekLaneCounts[w] = assigned + 1;
        }

        final bool startsAtEventStart = compareDate(segStart, ne.start) == 0;
        final bool endsAtEventEnd = compareDate(segEnd, ne.end) == 0;
        segments.add(
          RangeBarSegment<T>(
            event: ne.event,
            weekIndex: w,
            startCol: startCol,
            endCol: endCol,
            lane: assigned,
            startsInsideVisibleRange:
                startsAtEventStart &&
                compareDate(ne.event.start, visibleStart) >= 0,
            endsInsideVisibleRange:
                endsAtEventEnd && compareDate(ne.event.end, visibleEnd) <= 0,
            startsAtEventStart: startsAtEventStart,
            endsAtEventEnd: endsAtEventEnd,
          ),
        );
        prevLane = assigned;
      }
    }

    return RangeBarLayoutResult<T>(
      segments: segments,
      weekLaneCounts: weekLaneCounts,
      hiddenCounts: hiddenCounts,
      hiddenEventsByDay: hiddenEventsByDay,
    );
  }
}

class _NormalizedEvent<T> {
  _NormalizedEvent(this.event, this.start, this.end);
  final RangeCalendarEvent<T> event;
  final DateTime start;
  final DateTime end;
}
