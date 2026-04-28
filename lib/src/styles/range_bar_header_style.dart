import 'package:flutter/material.dart';

/// ヘッダーのレイアウト方式。
enum RangeBarHeaderLayout {
  /// 旧来の挙動。`prev | title(Expanded) | next | (format/actions)` を
  /// 行全幅に展開する。広い画面では prev / next が左右両端に貼り付き、
  /// 月タイトルから視覚的に離れて見える。
  spread,

  /// 月タイトルと prev/next を中央クラスタとしてまとめ、`actions` を
  /// 右側に置く。広い画面でも prev / next が月タイトルの両脇に固定で
  /// 並ぶ。
  centerCluster,
}

/// Visual style for the calendar header (prev/next + title row).
@immutable
class RangeBarHeaderStyle {
  const RangeBarHeaderStyle({
    this.height = 48.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0),
    this.titleStyle,
    this.titleAlignment = Alignment.center,
    this.iconColor,
    this.showFormatToggle = true,
    this.showNavigation = true,
    this.layout = RangeBarHeaderLayout.spread,
    this.navigationGap = 4.0,
  });

  final double height;
  final EdgeInsets padding;
  final TextStyle? titleStyle;
  final AlignmentGeometry titleAlignment;
  final Color? iconColor;
  final bool showFormatToggle;
  final bool showNavigation;

  /// レイアウト方式（spread / centerCluster）。
  final RangeBarHeaderLayout layout;

  /// `centerCluster` レイアウトのとき、月タイトルと prev/next の間に
  /// 入れる水平余白。
  final double navigationGap;

  RangeBarHeaderStyle copyWith({
    double? height,
    EdgeInsets? padding,
    TextStyle? titleStyle,
    AlignmentGeometry? titleAlignment,
    Color? iconColor,
    bool? showFormatToggle,
    bool? showNavigation,
    RangeBarHeaderLayout? layout,
    double? navigationGap,
  }) {
    return RangeBarHeaderStyle(
      height: height ?? this.height,
      padding: padding ?? this.padding,
      titleStyle: titleStyle ?? this.titleStyle,
      titleAlignment: titleAlignment ?? this.titleAlignment,
      iconColor: iconColor ?? this.iconColor,
      showFormatToggle: showFormatToggle ?? this.showFormatToggle,
      showNavigation: showNavigation ?? this.showNavigation,
      layout: layout ?? this.layout,
      navigationGap: navigationGap ?? this.navigationGap,
    );
  }
}
