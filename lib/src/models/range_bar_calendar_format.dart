/// Calendar display formats supported by [RangeBarCalendar].
enum RangeBarCalendarFormat {
  /// Show a full month grid (typically 6 weeks).
  month,

  /// Show two weeks centered on the focused day's week.
  twoWeeks,

  /// Show a single week containing the focused day.
  week,
}

extension RangeBarCalendarFormatX on RangeBarCalendarFormat {
  /// Number of weeks displayed for this format.
  int get weekCount {
    switch (this) {
      case RangeBarCalendarFormat.month:
        return 6;
      case RangeBarCalendarFormat.twoWeeks:
        return 2;
      case RangeBarCalendarFormat.week:
        return 1;
    }
  }
}
