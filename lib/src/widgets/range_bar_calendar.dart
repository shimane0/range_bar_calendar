import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/range_bar_calendar_format.dart';
import '../models/range_bar_event_tap_behavior.dart';
import '../models/range_calendar_event.dart';
import '../styles/range_bar_calendar_style.dart';
import '../styles/range_bar_header_style.dart';
import '../styles/range_bar_style.dart';
import '../utils/date_utils.dart';
import 'range_bar_calendar_builders.dart';
import 'range_bar_calendar_page.dart';
import 'range_bar_dow_row.dart';
import 'range_bar_header.dart';

/// Reserved vertical slot for the `+N` overflow indicator. Always reserved
/// so every page has a stable, uniform height regardless of which week
/// happens to overflow.
const double _moreIndicatorReserve = 16.0;

/// Google Calendar-style range bar calendar.
///
/// `T` is the type of [RangeCalendarEvent.payload].
class RangeBarCalendar<T> extends StatefulWidget {
  const RangeBarCalendar({
    required this.firstDay,
    required this.lastDay,
    required this.focusedDay,
    this.calendarFormat = RangeBarCalendarFormat.month,
    this.events,
    this.selectedDay,
    this.selectedEventId,
    this.startingDayOfWeek = DateTime.sunday,
    this.locale,
    this.calendarStyle = const RangeBarCalendarStyle(),
    this.barStyle = const RangeBarStyle(),
    this.headerStyle = const RangeBarHeaderStyle(),
    this.builders,
    this.availableFormats = const <RangeBarCalendarFormat>[
      RangeBarCalendarFormat.month,
      RangeBarCalendarFormat.twoWeeks,
      RangeBarCalendarFormat.week,
    ],
    this.eventTapBehavior = RangeBarEventTapBehavior.selectOnly,
    this.onDaySelected,
    this.onPageChanged,
    this.onFormatChanged,
    this.onEventSelected,
    this.onEventTapAtDay,
    this.onEventOpenRequested,
    this.onEventLongPress,
    this.onMoreTap,
    this.headerActions,
    @Deprecated(
      'Use onEventSelected (single tap = select) or onEventOpenRequested '
      '(explicit open) instead. Single tap should not navigate by default.',
    )
    this.onEventTap,
    super.key,
  });

  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime focusedDay;
  final RangeBarCalendarFormat calendarFormat;
  final List<RangeCalendarEvent<T>>? events;
  final DateTime? selectedDay;

  /// Currently selected event id. The matching bar is rendered with the
  /// selected visual style ([RangeBarStyle.selectedBorder] et al.).
  final String? selectedEventId;
  final int startingDayOfWeek;
  final String? locale;
  final RangeBarCalendarStyle calendarStyle;
  final RangeBarStyle barStyle;
  final RangeBarHeaderStyle headerStyle;
  final RangeBarCalendarBuilders<T>? builders;
  final List<RangeBarCalendarFormat> availableFormats;

  /// Behavior of a single tap on an event bar. Defaults to
  /// [RangeBarEventTapBehavior.selectOnly] so accidental taps do not
  /// navigate users away from the calendar.
  final RangeBarEventTapBehavior eventTapBehavior;
  final void Function(DateTime selectedDay, DateTime focusedDay)? onDaySelected;
  final ValueChanged<DateTime>? onPageChanged;
  final ValueChanged<RangeBarCalendarFormat>? onFormatChanged;

  /// Invoked when [eventTapBehavior] is [RangeBarEventTapBehavior.selectOnly]
  /// and the user taps a bar.
  final ValueChanged<RangeCalendarEvent<T>>? onEventSelected;

  /// バーをタップした際、「そのタップ位置の実日」を併せて受け取りたい
  /// 場合に使うコールバック。設定されていると [onEventSelected] よりも
  /// こちらがタップ処理で優先される（[onEventLongPress] は影響しない）。
  /// 複数日にまたがるバーで「タップした日を選択してfocus月は動かさず
  /// その日の予定一覧を見せる」というユースケースをサポートする。
  final void Function(RangeCalendarEvent<T> event, DateTime day)? onEventTapAtDay;

  /// Invoked when [eventTapBehavior] is [RangeBarEventTapBehavior.openDetails]
  /// or callers want to open details from outside the bar tap (e.g. a
  /// preview card).
  final ValueChanged<RangeCalendarEvent<T>>? onEventOpenRequested;
  final ValueChanged<RangeCalendarEvent<T>>? onEventLongPress;

  /// DEPRECATED: kept only for backward compatibility. When provided
  /// and no other callback is set, falls back to it for selectOnly /
  /// openDetails behaviors.
  @Deprecated(
    'Use onEventSelected (single tap = select) or onEventOpenRequested '
    '(explicit open) instead. Single tap should not navigate by default.',
  )
  final ValueChanged<RangeCalendarEvent<T>>? onEventTap;
  final void Function(DateTime day, int hiddenCount, List<RangeCalendarEvent<T>> hiddenEvents)?
  onMoreTap;

  /// ヘッダー右側に挿入される任意ウィジェット（例: 「今日」ボタン）。
  final Widget? headerActions;

  @override
  State<RangeBarCalendar<T>> createState() => _RangeBarCalendarState<T>();
}

class _RangeBarCalendarState<T> extends State<RangeBarCalendar<T>> {
  late PageController _pageController;
  late int _currentPage;

  List<RangeCalendarEvent<T>> get _events => widget.events ?? <RangeCalendarEvent<T>>[];

  RangeBarCalendarBuilders<T> get _builders => widget.builders ?? RangeBarCalendarBuilders<T>();

  @override
  void initState() {
    super.initState();
    _currentPage = _pageIndexOf(widget.focusedDay, widget.calendarFormat);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(covariant RangeBarCalendar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool formatChanged = oldWidget.calendarFormat != widget.calendarFormat;
    final int desiredPage = _pageIndexOf(widget.focusedDay, widget.calendarFormat);

    if (formatChanged ||
        oldWidget.firstDay != widget.firstDay ||
        oldWidget.lastDay != widget.lastDay) {
      _pageController.dispose();
      _pageController = PageController(initialPage: desiredPage);
      _currentPage = desiredPage;
    } else if (desiredPage != _currentPage) {
      _currentPage = desiredPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }
        _pageController.jumpToPage(desiredPage);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageIndexOf(DateTime day, RangeBarCalendarFormat format) {
    switch (format) {
      case RangeBarCalendarFormat.month:
        final DateTime base = firstDayOfMonth(widget.firstDay);
        return (day.year - base.year) * 12 + (day.month - base.month);
      case RangeBarCalendarFormat.twoWeeks:
        final DateTime base = firstDayOfWeek(widget.firstDay, widget.startingDayOfWeek);
        final DateTime aligned = firstDayOfWeek(day, widget.startingDayOfWeek);
        return aligned.difference(base).inDays ~/ 14;
      case RangeBarCalendarFormat.week:
        final DateTime base = firstDayOfWeek(widget.firstDay, widget.startingDayOfWeek);
        final DateTime aligned = firstDayOfWeek(day, widget.startingDayOfWeek);
        return aligned.difference(base).inDays ~/ 7;
    }
  }

  DateTime _focusedDayForPage(int page, RangeBarCalendarFormat format) {
    switch (format) {
      case RangeBarCalendarFormat.month:
        final DateTime base = firstDayOfMonth(widget.firstDay);
        return DateTime(base.year, base.month + page, 1);
      case RangeBarCalendarFormat.twoWeeks:
        final DateTime base = firstDayOfWeek(widget.firstDay, widget.startingDayOfWeek);
        return addDays(base, page * 14);
      case RangeBarCalendarFormat.week:
        final DateTime base = firstDayOfWeek(widget.firstDay, widget.startingDayOfWeek);
        return addDays(base, page * 7);
    }
  }

  int get _pageCount {
    switch (widget.calendarFormat) {
      case RangeBarCalendarFormat.month:
        final DateTime f = firstDayOfMonth(widget.firstDay);
        final DateTime l = firstDayOfMonth(widget.lastDay);
        return (l.year - f.year) * 12 + (l.month - f.month) + 1;
      case RangeBarCalendarFormat.twoWeeks:
        final DateTime f = firstDayOfWeek(widget.firstDay, widget.startingDayOfWeek);
        final DateTime l = firstDayOfWeek(widget.lastDay, widget.startingDayOfWeek);
        return (l.difference(f).inDays ~/ 14) + 1;
      case RangeBarCalendarFormat.week:
        final DateTime f = firstDayOfWeek(widget.firstDay, widget.startingDayOfWeek);
        final DateTime l = firstDayOfWeek(widget.lastDay, widget.startingDayOfWeek);
        return (l.difference(f).inDays ~/ 7) + 1;
    }
  }

  List<DateTime> _visibleDaysForFocused(DateTime focused, RangeBarCalendarFormat format) {
    switch (format) {
      case RangeBarCalendarFormat.month:
        final DateTime monthStart = firstDayOfMonth(focused);
        final DateTime gridStart = firstDayOfWeek(monthStart, widget.startingDayOfWeek);
        return List<DateTime>.generate(42, (int i) => addDays(gridStart, i));
      case RangeBarCalendarFormat.twoWeeks:
        final DateTime gridStart = firstDayOfWeek(focused, widget.startingDayOfWeek);
        return List<DateTime>.generate(14, (int i) => addDays(gridStart, i));
      case RangeBarCalendarFormat.week:
        final DateTime gridStart = firstDayOfWeek(focused, widget.startingDayOfWeek);
        return List<DateTime>.generate(7, (int i) => addDays(gridStart, i));
    }
  }

  void _goPrevious() {
    if (_currentPage <= 0) {
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _goNext() {
    if (_currentPage >= _pageCount - 1) {
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  /// Number of week rows shown per page for the current format.
  int get _weekCountPerPage {
    switch (widget.calendarFormat) {
      case RangeBarCalendarFormat.month:
        return 6;
      case RangeBarCalendarFormat.twoWeeks:
        return 2;
      case RangeBarCalendarFormat.week:
        return 1;
    }
  }

  /// Uniform row height applied to every week row across every page so the
  /// calendar reports a stable intrinsic height to its parent. Reserves
  /// space for [RangeBarStyle.maxBarsPerDay] bars plus the `+N` slot so
  /// page-to-page swipes do not change the calendar's outer height.
  double _uniformRowHeight() {
    final RangeBarCalendarStyle cs = widget.calendarStyle;
    final RangeBarStyle bs = widget.barStyle;
    final double maxBarArea = bs.maxBarsPerDay * (bs.height + bs.verticalGap);
    return math.max(
      cs.rowMinHeight,
      cs.dayNumberHeight + maxBarArea + _moreIndicatorReserve + cs.rowBottomPadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime headerFocused = _focusedDayForPage(_currentPage, widget.calendarFormat);
    final double idealRowHeight = _uniformRowHeight();
    final int weekCount = _weekCountPerPage;
    final double idealPageHeight = idealRowHeight * weekCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RangeBarHeader(
          focusedDay: headerFocused,
          format: widget.calendarFormat,
          style: widget.headerStyle,
          locale: widget.locale,
          availableFormats: widget.availableFormats,
          titleBuilder: _builders.headerTitleBuilder,
          actions: widget.headerActions,
          onPrevious: _goPrevious,
          onNext: _goNext,
          onFormatChanged: (RangeBarCalendarFormat f) => widget.onFormatChanged?.call(f),
        ),
        RangeBarDowRow(
          startingDayOfWeek: widget.startingDayOfWeek,
          style: widget.calendarStyle,
          locale: widget.locale,
          dowBuilder: _builders.dowBuilder,
        ),
        // PageView は idealRowHeight × 週数で固定高さを確保する。これにより
        // 親が `Expanded` でラップして領域を狭めても、+N インジケータ用の
        // 16px が常に確保され、月表示で予定が 3 件以上あるセルでも「+N」
        // が見切れない。Calendar 全体は `mainAxisSize: min` の intrinsic
        // 高さを持つため、呼び出し側は Column 直下に置けば良い。
        SizedBox(
          height: idealPageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
              final DateTime newFocused = _focusedDayForPage(page, widget.calendarFormat);
              widget.onPageChanged?.call(newFocused);
            },
            itemBuilder: (BuildContext context, int page) {
              final DateTime pageFocused = _focusedDayForPage(page, widget.calendarFormat);
              final List<DateTime> days = _visibleDaysForFocused(
                pageFocused,
                widget.calendarFormat,
              );
              return RangeBarCalendarPage<T>(
                visibleDays: days,
                focusedDay: pageFocused,
                firstDay: widget.firstDay,
                lastDay: widget.lastDay,
                events: _events,
                format: widget.calendarFormat,
                startingDayOfWeek: widget.startingDayOfWeek,
                calendarStyle: widget.calendarStyle,
                barStyle: widget.barStyle,
                builders: _builders,
                selectedDay: widget.selectedDay,
                selectedEventId: widget.selectedEventId,
                eventTapBehavior: widget.eventTapBehavior,
                rowHeight: idealRowHeight,
                onDayTap: widget.onDaySelected,
                onEventSelected:
                    widget.onEventSelected ??
                    // ignore: deprecated_member_use_from_same_package
                    widget.onEventTap,
                onEventTapAtDay: widget.onEventTapAtDay,
                onEventOpenRequested:
                    widget.onEventOpenRequested ??
                    // ignore: deprecated_member_use_from_same_package
                    widget.onEventTap,
                onEventLongPress: widget.onEventLongPress,
                onMoreTap: widget.onMoreTap,
              );
            },
          ),
        ),
      ],
    );
  }
}
