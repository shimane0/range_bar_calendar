import 'package:flutter/material.dart';

/// Visual style for the calendar grid (cells, day numbers, dow row).
@immutable
class RangeBarCalendarStyle {
  const RangeBarCalendarStyle({
    this.dayNumberHeight = 22.0,
    this.dayNumberPadding = const EdgeInsets.only(top: 4.0, left: 6.0),
    this.dayNumberStyle,
    this.todayDayNumberStyle,
    this.outsideDayNumberStyle,
    this.disabledDayNumberStyle,
    this.weekendDayNumberStyle,
    this.saturdayColor,
    this.sundayColor,
    this.selectedBackgroundColor,
    this.todayBackgroundColor,
    this.cellBorderColor,
    this.cellBorderWidth = 0.5,
    this.dowRowHeight = 28.0,
    this.dowTextStyle,
    this.weekendDowTextStyle,
    this.rowMinHeight = 56.0,
    this.rowBottomPadding = 4.0,
    this.moreIndicatorPadding = const EdgeInsets.symmetric(horizontal: 4.0),
    this.moreIndicatorTextStyle,
  });

  final double dayNumberHeight;
  final EdgeInsets dayNumberPadding;
  final TextStyle? dayNumberStyle;
  final TextStyle? todayDayNumberStyle;
  final TextStyle? outsideDayNumberStyle;
  final TextStyle? disabledDayNumberStyle;

  /// Fallback weekend style. Used when [saturdayColor] / [sundayColor]
  /// are not provided.
  final TextStyle? weekendDayNumberStyle;

  /// Color used for Saturday day numbers. When null, falls back to
  /// [weekendDayNumberStyle] color, then to `theme.colorScheme.error`.
  /// Recommended: a calm blue (e.g. `Colors.blue.shade700`) per common
  /// Japanese calendar conventions.
  final Color? saturdayColor;

  /// Color used for Sunday day numbers. When null, falls back to
  /// [weekendDayNumberStyle] color, then to `theme.colorScheme.error`.
  final Color? sundayColor;

  final Color? selectedBackgroundColor;
  final Color? todayBackgroundColor;
  final Color? cellBorderColor;
  final double cellBorderWidth;
  final double dowRowHeight;
  final TextStyle? dowTextStyle;
  final TextStyle? weekendDowTextStyle;
  final double rowMinHeight;
  final double rowBottomPadding;
  final EdgeInsets moreIndicatorPadding;
  final TextStyle? moreIndicatorTextStyle;

  RangeBarCalendarStyle copyWith({
    double? dayNumberHeight,
    EdgeInsets? dayNumberPadding,
    TextStyle? dayNumberStyle,
    TextStyle? todayDayNumberStyle,
    TextStyle? outsideDayNumberStyle,
    TextStyle? disabledDayNumberStyle,
    TextStyle? weekendDayNumberStyle,
    Color? saturdayColor,
    Color? sundayColor,
    Color? selectedBackgroundColor,
    Color? todayBackgroundColor,
    Color? cellBorderColor,
    double? cellBorderWidth,
    double? dowRowHeight,
    TextStyle? dowTextStyle,
    TextStyle? weekendDowTextStyle,
    double? rowMinHeight,
    double? rowBottomPadding,
    EdgeInsets? moreIndicatorPadding,
    TextStyle? moreIndicatorTextStyle,
  }) {
    return RangeBarCalendarStyle(
      dayNumberHeight: dayNumberHeight ?? this.dayNumberHeight,
      dayNumberPadding: dayNumberPadding ?? this.dayNumberPadding,
      dayNumberStyle: dayNumberStyle ?? this.dayNumberStyle,
      todayDayNumberStyle: todayDayNumberStyle ?? this.todayDayNumberStyle,
      outsideDayNumberStyle:
          outsideDayNumberStyle ?? this.outsideDayNumberStyle,
      disabledDayNumberStyle:
          disabledDayNumberStyle ?? this.disabledDayNumberStyle,
      weekendDayNumberStyle:
          weekendDayNumberStyle ?? this.weekendDayNumberStyle,
      saturdayColor: saturdayColor ?? this.saturdayColor,
      sundayColor: sundayColor ?? this.sundayColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      todayBackgroundColor: todayBackgroundColor ?? this.todayBackgroundColor,
      cellBorderColor: cellBorderColor ?? this.cellBorderColor,
      cellBorderWidth: cellBorderWidth ?? this.cellBorderWidth,
      dowRowHeight: dowRowHeight ?? this.dowRowHeight,
      dowTextStyle: dowTextStyle ?? this.dowTextStyle,
      weekendDowTextStyle: weekendDowTextStyle ?? this.weekendDowTextStyle,
      rowMinHeight: rowMinHeight ?? this.rowMinHeight,
      rowBottomPadding: rowBottomPadding ?? this.rowBottomPadding,
      moreIndicatorPadding: moreIndicatorPadding ?? this.moreIndicatorPadding,
      moreIndicatorTextStyle:
          moreIndicatorTextStyle ?? this.moreIndicatorTextStyle,
    );
  }
}
