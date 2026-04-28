import 'package:flutter_test/flutter_test.dart';
import 'package:range_bar_calendar/range_bar_calendar.dart';

void main() {
  group('isSameDay', () {
    test('matches y/m/d only, ignores time', () {
      expect(
        isSameDay(DateTime(2025, 1, 1, 23, 59), DateTime(2025, 1, 1, 0, 0)),
        isTrue,
      );
    });

    test('different days', () {
      expect(isSameDay(DateTime(2025, 1, 1), DateTime(2025, 1, 2)), isFalse);
    });
  });

  group('compareDate', () {
    test('orders by year, month, day', () {
      expect(
        compareDate(DateTime(2024, 12, 31), DateTime(2025, 1, 1)) < 0,
        isTrue,
      );
      expect(
        compareDate(DateTime(2025, 2, 1), DateTime(2025, 1, 31)) > 0,
        isTrue,
      );
      expect(compareDate(DateTime(2025, 5, 5), DateTime(2025, 5, 5)), 0);
    });
  });

  group('addDays', () {
    test('crosses month boundary', () {
      expect(addDays(DateTime(2025, 1, 31), 1), DateTime(2025, 2, 1));
    });

    test('crosses year boundary', () {
      expect(addDays(DateTime(2024, 12, 31), 1), DateTime(2025, 1, 1));
    });

    test('handles leap day', () {
      expect(addDays(DateTime(2024, 2, 28), 1), DateTime(2024, 2, 29));
      expect(addDays(DateTime(2024, 2, 29), 1), DateTime(2024, 3, 1));
    });

    test('negative offset', () {
      expect(addDays(DateTime(2025, 3, 1), -1), DateTime(2025, 2, 28));
    });
  });

  group('daysBetweenInclusive', () {
    test('same day = 1', () {
      expect(
        daysBetweenInclusive(DateTime(2025, 1, 1), DateTime(2025, 1, 1)),
        1,
      );
    });

    test('positive range', () {
      expect(
        daysBetweenInclusive(DateTime(2025, 1, 1), DateTime(2025, 1, 7)),
        7,
      );
    });
  });

  group('firstDayOfWeek', () {
    test('starting Sunday', () {
      // 2025-11-12 is Wednesday.
      expect(
        firstDayOfWeek(DateTime(2025, 11, 12), DateTime.sunday),
        DateTime(2025, 11, 9),
      );
    });

    test('starting Monday', () {
      expect(
        firstDayOfWeek(DateTime(2025, 11, 12), DateTime.monday),
        DateTime(2025, 11, 10),
      );
    });
  });

  group('firstDayOfMonth / lastDayOfMonth', () {
    test('basic', () {
      expect(firstDayOfMonth(DateTime(2025, 11, 15)), DateTime(2025, 11, 1));
      expect(lastDayOfMonth(DateTime(2025, 11, 15)), DateTime(2025, 11, 30));
    });

    test('leap year February', () {
      expect(lastDayOfMonth(DateTime(2024, 2, 1)), DateTime(2024, 2, 29));
      expect(lastDayOfMonth(DateTime(2025, 2, 1)), DateTime(2025, 2, 28));
    });
  });

  group('columnOfDay', () {
    test('starting Sunday', () {
      // Sunday = 7, so col 0 when start = sunday(7)
      expect(columnOfDay(DateTime(2025, 11, 9), DateTime.sunday), 0);
      expect(columnOfDay(DateTime(2025, 11, 15), DateTime.sunday), 6);
    });

    test('starting Monday', () {
      expect(columnOfDay(DateTime(2025, 11, 10), DateTime.monday), 0);
      expect(columnOfDay(DateTime(2025, 11, 16), DateTime.monday), 6);
    });
  });
}
