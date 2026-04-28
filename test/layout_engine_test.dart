import 'package:flutter_test/flutter_test.dart';
import 'package:range_bar_calendar/range_bar_calendar.dart';

List<DateTime> _grid(DateTime gridStart, int weeks) {
  return List<DateTime>.generate(weeks * 7, (int i) => addDays(gridStart, i));
}

RangeCalendarEvent<String> _evt(
  String id,
  DateTime start,
  DateTime end, {
  int priority = 0,
}) {
  return RangeCalendarEvent<String>(
    id: id,
    title: id,
    start: start,
    end: end,
    priority: priority,
    payload: id,
  );
}

void main() {
  // 2025-11-09 is Sunday. Use a 6-week month grid starting Nov 9.
  final DateTime gridStart = DateTime(2025, 11, 9);
  final List<DateTime> sixWeeks = _grid(gridStart, 6);

  group('RangeBarLayoutEngine basic placement', () {
    test('1日のバー: lane 0, columnSpan 1', () {
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('a', DateTime(2025, 11, 12), DateTime(2025, 11, 12)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments, hasLength(1));
      expect(r.segments[0].lane, 0);
      expect(r.segments[0].columnSpan, 1);
      expect(r.segments[0].startsInsideVisibleRange, isTrue);
      expect(r.segments[0].endsInsideVisibleRange, isTrue);
    });

    test('3日連続のバーは同一週で1セグメント', () {
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('b', DateTime(2025, 11, 11), DateTime(2025, 11, 13)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments, hasLength(1));
      expect(r.segments[0].columnSpan, 3);
    });

    test('週をまたぐバーは2セグメントに分割', () {
      // 2025-11-14 (Fri) ~ 2025-11-17 (Mon)
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('c', DateTime(2025, 11, 14), DateTime(2025, 11, 17)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments, hasLength(2));
      expect(r.segments[0].weekIndex, isNot(r.segments[1].weekIndex));
      // First segment ends at the week boundary -> not at event end.
      expect(r.segments[0].endsAtEventEnd, isFalse);
      expect(r.segments[1].startsAtEventStart, isFalse);
    });

    test('月をまたぐバーが描ける', () {
      // 2025-11-28 (Fri) ~ 2025-12-03 (Wed). gridStart = 2025-11-09
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('d', DateTime(2025, 11, 28), DateTime(2025, 12, 3)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      // Spans week 3 (Nov 23-29) and week 4 (Nov 30-Dec 6).
      expect(r.segments.length >= 2, isTrue);
    });

    test('表示範囲外で完全に閉じるイベントは含まれない', () {
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('e', DateTime(2024, 1, 1), DateTime(2024, 1, 5)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments, isEmpty);
    });

    test('end < start のイベントは無視される', () {
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('bad', DateTime(2025, 11, 15), DateTime(2025, 11, 10)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments, isEmpty);
    });
  });

  group('Lane assignment', () {
    test('重なるイベントは別レーンに割り当てられる', () {
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('a', DateTime(2025, 11, 11), DateTime(2025, 11, 13)),
              _evt('b', DateTime(2025, 11, 12), DateTime(2025, 11, 14)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments, hasLength(2));
      final Set<int> lanes = r.segments.map((s) => s.lane).toSet();
      expect(lanes.length, 2);
    });

    test('連続する週で同じ event は同じ lane を維持しようとする', () {
      // 月をまたぐ長期イベント1本だけ → lane 0 を維持
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('long', DateTime(2025, 11, 12), DateTime(2025, 11, 25)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments.length >= 2, isTrue);
      final Set<int> lanes = r.segments.map((s) => s.lane).toSet();
      expect(lanes, <int>{0});
    });

    test('priority 高い event が先に lane 0 を取る', () {
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('low', DateTime(2025, 11, 12), DateTime(2025, 11, 14)),
              _evt(
                'high',
                DateTime(2025, 11, 12),
                DateTime(2025, 11, 14),
                priority: 10,
              ),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      final RangeBarSegment<String> high = r.segments.firstWhere(
        (s) => s.event.id == 'high',
      );
      final RangeBarSegment<String> low = r.segments.firstWhere(
        (s) => s.event.id == 'low',
      );
      expect(high.lane, 0);
      expect(low.lane, 1);
    });
  });

  group('Overflow / +N indicator', () {
    test('maxBarsPerDay=2, 3イベント重なるとhiddenに1件', () {
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('a', DateTime(2025, 11, 12), DateTime(2025, 11, 12)),
              _evt('b', DateTime(2025, 11, 12), DateTime(2025, 11, 12)),
              _evt('c', DateTime(2025, 11, 12), DateTime(2025, 11, 12)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 2,
          );
      expect(r.segments, hasLength(2));
      expect(r.hiddenCounts[DateTime(2025, 11, 12)], 1);
    });
  });

  group('Visible-range clipping', () {
    test('開始が範囲外のイベントは startsInsideVisibleRange = false', () {
      // event.start = 2025-10-28 (before gridStart = 2025-11-09)
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('x', DateTime(2025, 10, 28), DateTime(2025, 11, 11)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments.isNotEmpty, isTrue);
      expect(r.segments.first.startsInsideVisibleRange, isFalse);
    });

    test('終了が範囲外のイベントは endsInsideVisibleRange = false', () {
      // gridEnd = gridStart + 41 days = 2025-12-20
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('y', DateTime(2025, 12, 18), DateTime(2026, 1, 5)),
            ],
            visibleDays: sixWeeks,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments.isNotEmpty, isTrue);
      expect(r.segments.last.endsInsideVisibleRange, isFalse);
    });
  });

  group('Year-cross', () {
    test('年をまたぐ長期イベント', () {
      // grid Dec 28 2025 ~ Feb 7 2026 (6 weeks)
      final List<DateTime> g = _grid(DateTime(2025, 12, 28), 6);
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('y', DateTime(2025, 12, 30), DateTime(2026, 1, 5)),
            ],
            visibleDays: g,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments.length >= 2, isTrue);
    });
  });

  group('Leap day', () {
    test('2024-02-29 を含むバー', () {
      // grid Feb 25 2024 (Sun) for 2 weeks
      final List<DateTime> g = _grid(DateTime(2024, 2, 25), 2);
      final RangeBarLayoutResult<String> r =
          RangeBarLayoutEngine.calculate<String>(
            events: <RangeCalendarEvent<String>>[
              _evt('leap', DateTime(2024, 2, 28), DateTime(2024, 3, 2)),
            ],
            visibleDays: g,
            startingDayOfWeek: DateTime.sunday,
            maxBarsPerDay: 3,
          );
      expect(r.segments, isNotEmpty);
    });
  });
}
