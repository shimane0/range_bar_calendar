import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../styles/range_bar_calendar_style.dart';

/// Day-of-week row (Mon, Tue, ...).
class RangeBarDowRow extends StatelessWidget {
  const RangeBarDowRow({
    required this.startingDayOfWeek,
    required this.style,
    required this.locale,
    this.dowBuilder,
    super.key,
  });

  final int startingDayOfWeek;
  final RangeBarCalendarStyle style;
  final String? locale;
  final Widget Function(BuildContext context, int weekday)? dowBuilder;

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting();
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle =
        style.dowTextStyle ??
        theme.textTheme.labelSmall ??
        const TextStyle(fontSize: 12);
    final TextStyle weekendStyle =
        style.weekendDowTextStyle ??
        textStyle.copyWith(color: theme.colorScheme.error);

    return SizedBox(
      height: style.dowRowHeight,
      child: Row(
        children: List<Widget>.generate(7, (int i) {
          final int weekday = ((startingDayOfWeek - 1 + i) % 7) + 1;
          final bool isSaturday = weekday == DateTime.saturday;
          final bool isSunday = weekday == DateTime.sunday;
          final bool isWeekend = isSaturday || isSunday;
          // 土曜・日曜は個別カラー（saturdayColor / sundayColor）を最優先で適用し、
          // 未指定時は weekendDowTextStyle にフォールバックする。
          final Color? perDayColor =
              isSaturday
                  ? style.saturdayColor
                  : (isSunday ? style.sundayColor : null);
          final TextStyle resolvedStyle =
              isWeekend
                  ? (perDayColor != null
                      ? textStyle.copyWith(color: perDayColor)
                      : weekendStyle)
                  : textStyle;
          final Widget content;
          if (dowBuilder != null) {
            content = dowBuilder!(context, weekday);
          } else {
            content = Text(
              DateFormat.E(locale).format(DateTime(2024, 1, weekday)),
              style: resolvedStyle,
            );
          }
          return Expanded(child: Center(child: content));
        }),
      ),
    );
  }
}
