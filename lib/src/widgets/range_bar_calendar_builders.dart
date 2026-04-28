import 'package:flutter/widgets.dart';

import '../models/range_bar_calendar_format.dart';
import '../models/range_bar_segment.dart';
import '../models/range_calendar_event.dart';

/// Information about a calendar day passed to cell builders.
@immutable
class RangeBarDayContext {
  const RangeBarDayContext({
    required this.day,
    required this.focusedDay,
    required this.isToday,
    required this.isSelected,
    required this.isOutside,
    required this.isDisabled,
    required this.isWeekend,
  });

  final DateTime day;
  final DateTime focusedDay;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;
  final bool isDisabled;
  final bool isWeekend;
}

/// Builder collection allowing full customization of the calendar.
@immutable
class RangeBarCalendarBuilders<T> {
  const RangeBarCalendarBuilders({
    this.headerTitleBuilder,
    this.dowBuilder,
    this.dayNumberBuilder,
    this.cellBackgroundBuilder,
    this.rangeBarBuilder,
    this.singleDayEventBuilder,
    this.moreIndicatorBuilder,
  });

  /// Header title (e.g. "2025年11月"). Receives the focused day and the
  /// current format.
  final Widget Function(
    BuildContext context,
    DateTime focusedDay,
    RangeBarCalendarFormat format,
  )?
  headerTitleBuilder;

  /// Day-of-week label in the DOW row.
  final Widget Function(BuildContext context, int weekday)? dowBuilder;

  /// Day number label inside a cell.
  final Widget Function(BuildContext context, RangeBarDayContext day)?
  dayNumberBuilder;

  /// Background of a single day cell (selection / today highlights, etc.).
  final Widget Function(BuildContext context, RangeBarDayContext day)?
  cellBackgroundBuilder;

  /// Renders a single range bar segment.
  final Widget Function(BuildContext context, RangeBarSegment<T> segment)?
  rangeBarBuilder;

  /// Renders a single-day event using a Google Calendar-style inline row
  /// (e.g. "● HH:mm Title") instead of a colored bar.
  ///
  /// Called only when:
  /// - [RangeCalendarEvent.start] and [RangeCalendarEvent.end] fall on the
  ///   same day (single-day event), and
  /// - [RangeCalendarEvent.isTentative] is `false`.
  ///
  /// The widget is laid out in the same Positioned slot as a normal bar
  /// (height = [RangeBarStyle.height]), and lane assignment / `+N`
  /// overflow handling are unchanged. Multi-day bars and tentative
  /// (month-precision) bars continue to use the regular bar rendering.
  final Widget Function(BuildContext context, RangeBarSegment<T> segment)?
  singleDayEventBuilder;

  /// Renders the `+N more` indicator on a day.
  final Widget Function(
    BuildContext context,
    DateTime day,
    int hiddenCount,
    List<RangeCalendarEvent<T>> hiddenEvents,
  )?
  moreIndicatorBuilder;
}
