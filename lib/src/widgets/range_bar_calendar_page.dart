import 'package:flutter/material.dart';

import '../engine/range_bar_layout_engine.dart';
import '../models/range_bar_calendar_format.dart';
import '../models/range_bar_event_tap_behavior.dart';
import '../models/range_bar_layout_result.dart';
import '../models/range_bar_segment.dart';
import '../models/range_calendar_event.dart';
import '../styles/range_bar_calendar_style.dart';
import '../styles/range_bar_style.dart';
import '../utils/date_utils.dart';
import 'range_bar_calendar_builders.dart';
import 'range_bar_segment_widget.dart';

/// Renders a single page (one or more week rows) of the calendar grid.
class RangeBarCalendarPage<T> extends StatefulWidget {
  const RangeBarCalendarPage({
    required this.visibleDays,
    required this.focusedDay,
    required this.firstDay,
    required this.lastDay,
    required this.events,
    required this.format,
    required this.startingDayOfWeek,
    required this.calendarStyle,
    required this.barStyle,
    required this.builders,
    required this.selectedDay,
    required this.selectedEventId,
    required this.eventTapBehavior,
    required this.rowHeight,
    required this.onDayTap,
    required this.onEventSelected,
    required this.onEventTapAtDay,
    required this.onEventOpenRequested,
    required this.onEventLongPress,
    required this.onMoreTap,
    super.key,
  });

  final List<DateTime> visibleDays;
  final DateTime focusedDay;
  final DateTime firstDay;
  final DateTime lastDay;
  final List<RangeCalendarEvent<T>> events;
  final RangeBarCalendarFormat format;
  final int startingDayOfWeek;
  final RangeBarCalendarStyle calendarStyle;
  final RangeBarStyle barStyle;
  final RangeBarCalendarBuilders<T> builders;
  final DateTime? selectedDay;
  final String? selectedEventId;
  final RangeBarEventTapBehavior eventTapBehavior;

  /// Uniform height applied to every week row in this page. Computed by
  /// [RangeBarCalendar] so all pages share the same outer height.
  final double rowHeight;
  final void Function(DateTime day, DateTime focusedDay)? onDayTap;
  final void Function(RangeCalendarEvent<T> event)? onEventSelected;

  /// Bar tap with the actual day under the tap position. When provided,
  /// it takes precedence over [onEventSelected] for tap handling. Useful
  /// when a multi-day bar is tapped and the caller wants to know which
  /// specific day was hit (e.g. to select that day without changing the
  /// focused month).
  final void Function(RangeCalendarEvent<T> event, DateTime day)? onEventTapAtDay;
  final void Function(RangeCalendarEvent<T> event)? onEventOpenRequested;
  final void Function(RangeCalendarEvent<T> event)? onEventLongPress;
  final void Function(DateTime day, int hiddenCount, List<RangeCalendarEvent<T>> hiddenEvents)?
  onMoreTap;

  @override
  State<RangeBarCalendarPage<T>> createState() => _RangeBarCalendarPageState<T>();
}

class _RangeBarCalendarPageState<T> extends State<RangeBarCalendarPage<T>> {
  /// Cached layout result. Recomputed only when the layout-affecting inputs
  /// change. Selection-only changes (`selectedDay` / `selectedEventId`) do
  /// not invalidate this cache, eliminating the dominant rebuild cost when
  /// the user taps days repeatedly.
  RangeBarLayoutResult<T>? _cachedResult;

  /// Identity of the [events] list captured when [_cachedResult] was last
  /// computed. Compared with `identical` so callers that mutate the same
  /// list in place still see updates as long as they pass a new list
  /// reference (which is the common Riverpod / immutable pattern).
  List<RangeCalendarEvent<T>>? _cacheEventsIdentity;
  List<DateTime>? _cacheVisibleDaysIdentity;
  int? _cacheStartingDayOfWeek;
  int? _cacheMaxBarsPerDay;

  bool _layoutInputsUnchanged() {
    return _cachedResult != null &&
        identical(_cacheEventsIdentity, widget.events) &&
        identical(_cacheVisibleDaysIdentity, widget.visibleDays) &&
        _cacheStartingDayOfWeek == widget.startingDayOfWeek &&
        _cacheMaxBarsPerDay == widget.barStyle.maxBarsPerDay;
  }

  RangeBarLayoutResult<T> _layoutResult() {
    if (_layoutInputsUnchanged()) {
      return _cachedResult!;
    }
    final RangeBarLayoutResult<T> r = RangeBarLayoutEngine.calculate<T>(
      events: widget.events,
      visibleDays: widget.visibleDays,
      startingDayOfWeek: widget.startingDayOfWeek,
      maxBarsPerDay: widget.barStyle.maxBarsPerDay,
    );
    _cachedResult = r;
    _cacheEventsIdentity = widget.events;
    _cacheVisibleDaysIdentity = widget.visibleDays;
    _cacheStartingDayOfWeek = widget.startingDayOfWeek;
    _cacheMaxBarsPerDay = widget.barStyle.maxBarsPerDay;
    return r;
  }

  void _handleBarTap(RangeCalendarEvent<T> event) {
    switch (widget.eventTapBehavior) {
      case RangeBarEventTapBehavior.selectOnly:
        widget.onEventSelected?.call(event);
      case RangeBarEventTapBehavior.openDetails:
        widget.onEventOpenRequested?.call(event);
      case RangeBarEventTapBehavior.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final RangeBarLayoutResult<T> result = _layoutResult();

    final int weekCount = widget.visibleDays.length ~/ 7;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double colWidth = constraints.maxWidth / 7;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            weekCount,
            (int w) => _buildWeekRow(context, w, colWidth, result),
          ),
        );
      },
    );
  }

  Widget _buildWeekRow(
    BuildContext context,
    int weekIndex,
    double colWidth,
    RangeBarLayoutResult<T> result,
  ) {
    final List<DateTime> daysInWeek = widget.visibleDays.sublist(weekIndex * 7, weekIndex * 7 + 7);

    bool weekHasOverflow = false;
    for (final DateTime d in daysInWeek) {
      if ((result.hiddenCounts[d] ?? 0) > 0) {
        weekHasOverflow = true;
        break;
      }
    }

    final int laneCount = result.weekLaneCounts[weekIndex];
    final double barAreaHeight = laneCount * (widget.barStyle.height + widget.barStyle.verticalGap);
    final double moreAreaHeight = weekHasOverflow ? 16.0 : 0.0;
    // Use the uniform [rowHeight] passed from the parent so every week row
    // in every page has the exact same height. This keeps the page (and
    // therefore the whole calendar) at a stable intrinsic height and
    // avoids leftover blank space below the grid.

    // Pre-bucketed by the layout engine so retrieval is O(1) per week.
    final List<RangeBarSegment<T>> segmentsInWeek = result.segmentsByWeek[weekIndex];

    return SizedBox(
      height: widget.rowHeight,
      child: Stack(
        children: <Widget>[
          // Background: 7 day cells in a row.
          Row(
            children: List<Widget>.generate(7, (int col) {
              final DateTime day = daysInWeek[col];
              return Expanded(child: _buildDayCell(context, day));
            }),
          ),
          // Bars.
          for (final RangeBarSegment<T> seg in segmentsInWeek)
            Positioned(
              left: seg.startCol * colWidth + widget.barStyle.horizontalInset,
              top:
                  widget.calendarStyle.dayNumberHeight +
                  seg.lane * (widget.barStyle.height + widget.barStyle.verticalGap),
              width: seg.columnSpan * colWidth - 2 * widget.barStyle.horizontalInset,
              height: widget.barStyle.height,
              child: _buildBar(context, seg, daysInWeek, colWidth),
            ),
          // More indicators.
          if (weekHasOverflow)
            for (int col = 0; col < 7; col++)
              if ((result.hiddenCounts[daysInWeek[col]] ?? 0) > 0)
                Positioned(
                  left: col * colWidth,
                  top: widget.calendarStyle.dayNumberHeight + barAreaHeight,
                  width: colWidth,
                  height: moreAreaHeight,
                  child: _buildMore(
                    context,
                    daysInWeek[col],
                    result.hiddenCounts[daysInWeek[col]]!,
                    result.hiddenEventsByDay[daysInWeek[col]] ?? const <Never>[],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();
    final bool isToday = isSameDay(day, now);
    final bool isSelected = widget.selectedDay != null && isSameDay(widget.selectedDay!, day);
    final bool isOutside =
        widget.format == RangeBarCalendarFormat.month
            ? day.month != widget.focusedDay.month
            : false;
    final bool isDisabled = isBeforeDay(day, widget.firstDay) || isAfterDay(day, widget.lastDay);
    final bool isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    final RangeBarDayContext dayCtx = RangeBarDayContext(
      day: day,
      focusedDay: widget.focusedDay,
      isToday: isToday,
      isSelected: isSelected,
      isOutside: isOutside,
      isDisabled: isDisabled,
      isWeekend: isWeekend,
    );

    final Widget background =
        widget.builders.cellBackgroundBuilder != null
            ? widget.builders.cellBackgroundBuilder!(context, dayCtx)
            : _defaultCellBackground(theme, dayCtx);

    final Widget number =
        widget.builders.dayNumberBuilder != null
            ? widget.builders.dayNumberBuilder!(context, dayCtx)
            : _defaultDayNumber(theme, dayCtx);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // outside（前月/翌月）セルでも `null` にせず onTap を受ける。
      // ただし第二引数の focusedDay は据え置き（タップした日 day は
      // 別月の可能性があるため、月ジャンプを防ぐ）。アプリ側で月遷移
      // させたい場合は onDayTap 内で focusedDay を上書きすればよい。
      onTap:
          isDisabled ? null : () => widget.onDayTap?.call(day, isOutside ? widget.focusedDay : day),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          background,
          Positioned(
            top: widget.calendarStyle.dayNumberPadding.top,
            left: widget.calendarStyle.dayNumberPadding.left,
            right: widget.calendarStyle.dayNumberPadding.right,
            child: SizedBox(
              height:
                  widget.calendarStyle.dayNumberHeight - widget.calendarStyle.dayNumberPadding.top,
              child: number,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultCellBackground(ThemeData theme, RangeBarDayContext d) {
    final Color border =
        widget.calendarStyle.cellBorderColor ??
        theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final Color? bg =
        d.isSelected
            ? (widget.calendarStyle.selectedBackgroundColor ??
                theme.colorScheme.primaryContainer.withValues(alpha: 0.4))
            : d.isToday
            ? (widget.calendarStyle.todayBackgroundColor ??
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.3))
            : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: border, width: widget.calendarStyle.cellBorderWidth),
          right: BorderSide(color: border, width: widget.calendarStyle.cellBorderWidth),
        ),
      ),
    );
  }

  Widget _defaultDayNumber(ThemeData theme, RangeBarDayContext d) {
    TextStyle? base = widget.calendarStyle.dayNumberStyle ?? theme.textTheme.bodySmall;
    if (d.isOutside) {
      base =
          widget.calendarStyle.outsideDayNumberStyle ??
          base?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.35));
    } else if (d.isDisabled) {
      base =
          widget.calendarStyle.disabledDayNumberStyle ??
          base?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.25));
    } else if (d.isToday) {
      base =
          widget.calendarStyle.todayDayNumberStyle ??
          base?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold);
    } else if (d.isWeekend) {
      final bool isSunday = d.day.weekday == DateTime.sunday;
      final Color? perDayColor =
          isSunday ? widget.calendarStyle.sundayColor : widget.calendarStyle.saturdayColor;
      if (perDayColor != null) {
        base = (widget.calendarStyle.weekendDayNumberStyle ?? base)?.copyWith(color: perDayColor);
      } else {
        base =
            widget.calendarStyle.weekendDayNumberStyle ??
            base?.copyWith(color: theme.colorScheme.error);
      }
    }
    return Align(alignment: Alignment.centerLeft, child: Text('${d.day.day}', style: base));
  }

  Widget _buildBar(
    BuildContext context,
    RangeBarSegment<T> seg,
    List<DateTime> daysInWeek,
    double colWidth,
  ) {
    final bool isSelected =
        widget.selectedEventId != null && seg.event.id == widget.selectedEventId;

    // タップ位置から実タップ日を解決するヘルパー。onEventTapAtDay 設定時のみ使う。
    // バーの実描画幅は (columnSpan * colWidth - 2*horizontalInset)。
    // localPosition.dx は GestureDetector の子（バー）内座標で 0..segWidth。
    // 1 日分の表示幅は colWidth とほぼ等しい（端の inset 影響は微小）ので、
    // dayIndex = floor((localPosition.dx + horizontalInset) / colWidth) で
    // 安定的に解決できる。
    void Function(Offset)? tapWithPosition;
    if (widget.onEventTapAtDay != null) {
      tapWithPosition = (Offset localPosition) {
        final double adjustedDx = localPosition.dx + widget.barStyle.horizontalInset;
        final int dayIndex = (adjustedDx / colWidth).floor().clamp(0, seg.columnSpan - 1);
        final int absoluteIndex = (seg.startCol + dayIndex).clamp(0, daysInWeek.length - 1);
        final DateTime tappedDay = daysInWeek[absoluteIndex];
        widget.onEventTapAtDay!(seg.event, tappedDay);
      };
    }

    if (widget.builders.rangeBarBuilder != null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: tapWithPosition != null ? null : () => _handleBarTap(seg.event),
        onTapUp:
            tapWithPosition != null ? (TapUpDetails d) => tapWithPosition!(d.localPosition) : null,
        onLongPress: () => widget.onEventLongPress?.call(seg.event),
        child: widget.builders.rangeBarBuilder!(context, seg),
      );
    }
    // 単日（start == end）かつ非 tentative の予定は、Google カレンダー
    // 風のインライン表示（● HH:mm タイトル）に差し替え可能。レーン配置・
    // タップ配線・+N 計算は通常のバーと同一（lane を占有する）。
    if (widget.builders.singleDayEventBuilder != null &&
        !seg.event.isTentative &&
        isSameDay(seg.event.start, seg.event.end)) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: tapWithPosition != null ? null : () => _handleBarTap(seg.event),
        onTapUp:
            tapWithPosition != null ? (TapUpDetails d) => tapWithPosition!(d.localPosition) : null,
        onLongPress: () => widget.onEventLongPress?.call(seg.event),
        child: widget.builders.singleDayEventBuilder!(context, seg),
      );
    }
    return RangeBarSegmentWidget<T>(
      segment: seg,
      style: widget.barStyle,
      isSelected: isSelected,
      onTap: () => _handleBarTap(seg.event),
      onTapWithPosition: tapWithPosition,
      onLongPress: () => widget.onEventLongPress?.call(seg.event),
    );
  }

  Widget _buildMore(
    BuildContext context,
    DateTime day,
    int hiddenCount,
    List<RangeCalendarEvent<T>> hiddenEvents,
  ) {
    if (widget.builders.moreIndicatorBuilder != null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => widget.onMoreTap?.call(day, hiddenCount, hiddenEvents),
        child: widget.builders.moreIndicatorBuilder!(context, day, hiddenCount, hiddenEvents),
      );
    }
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle =
        widget.calendarStyle.moreIndicatorTextStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ) ??
        const TextStyle(fontSize: 11);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => widget.onMoreTap?.call(day, hiddenCount, hiddenEvents),
      child: Padding(
        padding: widget.calendarStyle.moreIndicatorPadding,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('+$hiddenCount', style: textStyle),
        ),
      ),
    );
  }
}
