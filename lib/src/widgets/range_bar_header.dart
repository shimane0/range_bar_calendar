import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/range_bar_calendar_format.dart';
import '../styles/range_bar_header_style.dart';

/// Header row with previous / next navigation and a title.
class RangeBarHeader extends StatelessWidget {
  const RangeBarHeader({
    required this.focusedDay,
    required this.format,
    required this.style,
    required this.locale,
    required this.onPrevious,
    required this.onNext,
    required this.onFormatChanged,
    this.titleBuilder,
    this.actions,
    this.availableFormats = const <RangeBarCalendarFormat>[
      RangeBarCalendarFormat.month,
      RangeBarCalendarFormat.twoWeeks,
      RangeBarCalendarFormat.week,
    ],
    super.key,
  });

  final DateTime focusedDay;
  final RangeBarCalendarFormat format;
  final RangeBarHeaderStyle style;
  final String? locale;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<RangeBarCalendarFormat> onFormatChanged;
  final Widget Function(
    BuildContext context,
    DateTime focusedDay,
    RangeBarCalendarFormat format,
  )?
  titleBuilder;

  /// 任意のヘッダー右側コンテンツ（例: 「今日」ボタン）。
  /// `centerCluster` レイアウトでは右側に、`spread` レイアウトでは
  /// format toggle の手前に挿入される。
  final Widget? actions;
  final List<RangeBarCalendarFormat> availableFormats;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleStyle =
        style.titleStyle ?? theme.textTheme.titleMedium;
    final Color iconColor =
        style.iconColor ?? theme.iconTheme.color ?? theme.colorScheme.onSurface;

    final Widget title =
        titleBuilder != null
            ? titleBuilder!(context, focusedDay, format)
            : Text(
              DateFormat.yMMMM(locale).format(focusedDay),
              style: titleStyle,
            );

    final Widget prevButton = IconButton(
      icon: Icon(Icons.chevron_left, color: iconColor),
      onPressed: onPrevious,
      tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
    );
    final Widget nextButton = IconButton(
      icon: Icon(Icons.chevron_right, color: iconColor),
      onPressed: onNext,
      tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
    );
    final Widget? formatToggle =
        style.showFormatToggle
            ? PopupMenuButton<RangeBarCalendarFormat>(
              tooltip: '表示形式',
              icon: Icon(Icons.view_module_outlined, color: iconColor),
              initialValue: format,
              onSelected: onFormatChanged,
              itemBuilder:
                  (BuildContext context) =>
                      availableFormats
                          .map(
                            (RangeBarCalendarFormat f) =>
                                PopupMenuItem<RangeBarCalendarFormat>(
                                  value: f,
                                  child: Text(_formatLabel(f)),
                                ),
                          )
                          .toList(),
            )
            : null;

    final Widget body = switch (style.layout) {
      RangeBarHeaderLayout.spread => _buildSpread(
        title: title,
        prevButton: prevButton,
        nextButton: nextButton,
        formatToggle: formatToggle,
      ),
      RangeBarHeaderLayout.centerCluster => _buildCenterCluster(
        title: title,
        prevButton: prevButton,
        nextButton: nextButton,
        formatToggle: formatToggle,
      ),
    };

    return SizedBox(
      height: style.height,
      child: Padding(padding: style.padding, child: body),
    );
  }

  Widget _buildSpread({
    required Widget title,
    required Widget prevButton,
    required Widget nextButton,
    required Widget? formatToggle,
  }) {
    return Row(
      children: <Widget>[
        if (style.showNavigation) prevButton,
        Expanded(child: Align(alignment: style.titleAlignment, child: title)),
        if (style.showNavigation) nextButton,
        if (actions != null) actions!,
        if (formatToggle != null) formatToggle,
      ],
    );
  }

  Widget _buildCenterCluster({
    required Widget title,
    required Widget prevButton,
    required Widget nextButton,
    required Widget? formatToggle,
  }) {
    final double gap = style.navigationGap;
    final Widget cluster = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (style.showNavigation) prevButton,
        if (style.showNavigation) SizedBox(width: gap),
        Flexible(child: title),
        if (style.showNavigation) SizedBox(width: gap),
        if (style.showNavigation) nextButton,
      ],
    );

    final List<Widget> rightActions = <Widget>[
      if (actions != null) actions!,
      if (formatToggle != null) formatToggle,
    ];

    // 中央クラスタを画面中央に置きつつ、`actions` を右側に置く。
    // Stack を使うことで、`actions` の幅が変わってもクラスタが
    // 中央に固定される（画面が広くても prev/next がタイトルから
    // 離れない）。
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(child: Center(child: cluster)),
        if (rightActions.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Row(mainAxisSize: MainAxisSize.min, children: rightActions),
          ),
      ],
    );
  }

  String _formatLabel(RangeBarCalendarFormat f) {
    switch (f) {
      case RangeBarCalendarFormat.month:
        return '月';
      case RangeBarCalendarFormat.twoWeeks:
        return '2週';
      case RangeBarCalendarFormat.week:
        return '週';
    }
  }
}
