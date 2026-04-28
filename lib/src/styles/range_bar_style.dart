import 'package:flutter/material.dart';

import '../models/range_bar_segment.dart';
import '../models/tentative_bar_decoration.dart';

/// バーに描画するコンテンツの種類。
///
/// `none` 以外を指定したバーは、セグメントの先頭（イベント開始週）にのみ
/// テキストを描画する。連続セグメントには描画しない（読みやすさのため）。
enum BarContentMode {
  /// イベントタイトル（既定）。
  title,

  /// `RangeCalendarEvent.timeLabel` を表示。
  time,

  /// 「タイトル ・ 時刻」の併記。timeLabel が null ならタイトルのみ。
  titleAndTime,

  /// テキストを描画しない（色だけのバー）。
  none,
}

/// Visual style for a single range bar.
@immutable
class RangeBarStyle {
  const RangeBarStyle({
    this.height = 18.0,
    this.verticalGap = 2.0,
    this.horizontalInset = 1.0,
    this.cornerRadius = 4.0,
    this.continuationCornerRadius = 0.0,
    this.titlePadding = const EdgeInsets.symmetric(horizontal: 6.0),
    this.titleStyle,
    this.defaultColor,
    this.opacity = 1.0,
    this.showTitle = true,
    this.contentMode = BarContentMode.title,
    this.barLabelBuilder,
    this.tentativeDecoration = const TentativeBarDecoration(),
    this.tentativeBarBuilder,
    this.maxBarsPerDay = 3,
    this.selectedBorder,
    this.selectedShadow,
    this.selectedOpacity,
    this.minTapTargetHeight = 32.0,
  });

  /// Height of a single bar in logical pixels.
  final double height;

  /// Vertical gap between stacked bars.
  final double verticalGap;

  /// Horizontal inset applied to each bar's left/right edges so adjacent
  /// bars don't visually touch the cell border.
  final double horizontalInset;

  /// Corner radius applied to the visible start/end of an event.
  final double cornerRadius;

  /// Corner radius applied to a segment that continues across a week
  /// boundary (typically 0 for a flush flat edge).
  final double continuationCornerRadius;

  /// Padding around the title text.
  final EdgeInsets titlePadding;

  /// Title text style. Falls back to `theme.textTheme.labelSmall` with
  /// onPrimary-like contrast.
  final TextStyle? titleStyle;

  /// Default bar color when [RangeCalendarEvent.color] is null.
  final Color? defaultColor;

  /// Bar opacity (0..1).
  final double opacity;

  /// Whether to render any text on the bar. Deprecated in favor of
  /// [contentMode]. When `false`, the effective content mode is forced
  /// to [BarContentMode.none] regardless of [contentMode]. Kept for
  /// backward compatibility.
  @Deprecated('Use contentMode = BarContentMode.none instead.')
  final bool showTitle;

  /// What to render on a bar (title / time / both / none).
  final BarContentMode contentMode;

  /// Optional override for the bar's text label. When provided, its return
  /// value is used regardless of [contentMode]. Receives the segment so
  /// callers can inspect both the event and where the segment falls.
  /// Returning `null` falls back to the [contentMode] default.
  final String? Function(RangeBarSegment<dynamic> segment, BarContentMode mode)?
  barLabelBuilder;

  /// Decoration applied to bars whose event has `isTentative = true`.
  /// Set to `null` to disable tentative decoration entirely (tentative
  /// bars are then drawn the same as normal bars).
  final TentativeBarDecoration? tentativeDecoration;

  /// Optional full-control builder for tentative bars. When provided, it
  /// is called instead of the built-in tentative renderer. Use this if
  /// you need a completely custom appearance (e.g. inline icons, custom
  /// shapes).
  final Widget Function(
    BuildContext context,
    RangeBarSegment<dynamic> segment,
    Color baseColor,
  )?
  tentativeBarBuilder;

  /// Maximum bars per day. Excess events become a `+N` indicator.
  final int maxBarsPerDay;

  /// Border applied to the bar when it is selected.
  final BorderSide? selectedBorder;

  /// Shadow applied to the bar when it is selected.
  final List<BoxShadow>? selectedShadow;

  /// Opacity used in place of [opacity] when the bar is selected. When
  /// `null`, [opacity] is used.
  final double? selectedOpacity;

  /// Minimum tap target height in logical pixels. Used to enlarge the
  /// hit-testable region while keeping the visual bar height small.
  final double minTapTargetHeight;

  RangeBarStyle copyWith({
    double? height,
    double? verticalGap,
    double? horizontalInset,
    double? cornerRadius,
    double? continuationCornerRadius,
    EdgeInsets? titlePadding,
    TextStyle? titleStyle,
    Color? defaultColor,
    double? opacity,
    bool? showTitle,
    BarContentMode? contentMode,
    String? Function(RangeBarSegment<dynamic> segment, BarContentMode mode)?
    barLabelBuilder,
    TentativeBarDecoration? tentativeDecoration,
    Widget Function(
      BuildContext context,
      RangeBarSegment<dynamic> segment,
      Color baseColor,
    )?
    tentativeBarBuilder,
    int? maxBarsPerDay,
    BorderSide? selectedBorder,
    List<BoxShadow>? selectedShadow,
    double? selectedOpacity,
    double? minTapTargetHeight,
  }) {
    return RangeBarStyle(
      height: height ?? this.height,
      verticalGap: verticalGap ?? this.verticalGap,
      horizontalInset: horizontalInset ?? this.horizontalInset,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      continuationCornerRadius:
          continuationCornerRadius ?? this.continuationCornerRadius,
      titlePadding: titlePadding ?? this.titlePadding,
      titleStyle: titleStyle ?? this.titleStyle,
      defaultColor: defaultColor ?? this.defaultColor,
      opacity: opacity ?? this.opacity,
      // ignore: deprecated_member_use_from_same_package
      showTitle: showTitle ?? this.showTitle,
      contentMode: contentMode ?? this.contentMode,
      barLabelBuilder: barLabelBuilder ?? this.barLabelBuilder,
      tentativeDecoration: tentativeDecoration ?? this.tentativeDecoration,
      tentativeBarBuilder: tentativeBarBuilder ?? this.tentativeBarBuilder,
      maxBarsPerDay: maxBarsPerDay ?? this.maxBarsPerDay,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      selectedShadow: selectedShadow ?? this.selectedShadow,
      selectedOpacity: selectedOpacity ?? this.selectedOpacity,
      minTapTargetHeight: minTapTargetHeight ?? this.minTapTargetHeight,
    );
  }
}
