/// Date helpers used internally by the calendar.
///
/// All comparisons are based on year/month/day only. Times of day are
/// ignored. To avoid DST-related surprises, values returned by helpers
/// such as [normalizeDate] use the local time zone with the time set to
/// midnight (00:00:00) but compared structurally (y/m/d only).
library;

/// Returns true if [a] and [b] fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Returns the date stripped of any time-of-day component.
DateTime normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

/// Compare two dates structurally (y/m/d only). Returns negative if [a] < [b],
/// zero if same day, positive if [a] > [b].
int compareDate(DateTime a, DateTime b) {
  final int byYear = a.year.compareTo(b.year);
  if (byYear != 0) {
    return byYear;
  }
  final int byMonth = a.month.compareTo(b.month);
  if (byMonth != 0) {
    return byMonth;
  }
  return a.day.compareTo(b.day);
}

/// Returns true if [a] is strictly before [b] (day-only comparison).
bool isBeforeDay(DateTime a, DateTime b) => compareDate(a, b) < 0;

/// Returns true if [a] is strictly after [b] (day-only comparison).
bool isAfterDay(DateTime a, DateTime b) => compareDate(a, b) > 0;

/// Adds [days] calendar days to [d] (DST-safe).
DateTime addDays(DateTime d, int days) {
  return DateTime(d.year, d.month, d.day + days);
}

/// Returns the number of inclusive days between [start] and [end].
/// Negative if [end] is before [start].
int daysBetweenInclusive(DateTime start, DateTime end) {
  final DateTime s = normalizeDate(start);
  final DateTime e = normalizeDate(end);
  return e.difference(s).inDays + 1;
}

/// Returns the first day of the week containing [d], where the week starts
/// on [startingDayOfWeek] (using [DateTime.monday] = 1 .. [DateTime.sunday] = 7).
DateTime firstDayOfWeek(DateTime d, int startingDayOfWeek) {
  assert(
    startingDayOfWeek >= DateTime.monday &&
        startingDayOfWeek <= DateTime.sunday,
    'startingDayOfWeek must be 1..7',
  );
  final int weekday = d.weekday;
  final int diff = (weekday - startingDayOfWeek + 7) % 7;
  return addDays(normalizeDate(d), -diff);
}

/// Returns the first day of the month containing [d].
DateTime firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

/// Returns the last day of the month containing [d].
DateTime lastDayOfMonth(DateTime d) {
  final DateTime nextMonthFirst = DateTime(d.year, d.month + 1, 1);
  return nextMonthFirst.subtract(const Duration(days: 1));
}

/// Returns the column index (0..6) of [d] when the week starts on
/// [startingDayOfWeek].
int columnOfDay(DateTime d, int startingDayOfWeek) {
  return (d.weekday - startingDayOfWeek + 7) % 7;
}
