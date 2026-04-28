import 'package:flutter/material.dart';

/// 未定予定（[RangeCalendarEvent.isTentative] = true）のバーに重ねる
/// 装飾パターン。
///
/// 視覚的に確定予定と区別するための表現。色覚多様性に配慮するため、
/// 不透明度・縁取り・パターンといった「色以外の手がかり」を組み合わせて
/// 表現できるよう、各要素を個別に指定できる構造にしている。
enum TentativeBarPattern {
  /// パターンなし。[TentativeBarDecoration.opacity] のみ適用。
  none,

  /// 斜めストライプ（推奨デフォルト）。色覚多様性に最も配慮しやすい。
  stripe,

  /// 破線の縁取りのみ（バー塗りはそのまま、半透明だけかける）。
  dashedBorder,

  /// 細かい斜めハッチ。stripe より密度の高いパターン。
  hatch,
}

/// 未定バーの装飾仕様。
///
/// `RangeBarStyle.tentativeDecoration` に設定すると、`isTentative = true`
/// のイベントバーに対して以下の順序で装飾が適用される:
///
/// 1. ベース塗りに [opacity] を乗算
/// 2. [pattern] に応じたオーバーレイを CustomPaint で描画
/// 3. [borderColor] / [borderWidth] / [borderDashPattern] による縁取り
///
/// 各フィールドはユーザーが個別にカスタムできる。完全に独自の描画にしたい
/// 場合は [RangeBarStyle.tentativeBarBuilder] を使う。
@immutable
class TentativeBarDecoration {
  const TentativeBarDecoration({
    this.opacity = 0.55,
    this.pattern = TentativeBarPattern.stripe,
    this.patternColor,
    this.patternOpacity = 0.5,
    this.stripeSpacing = 6.0,
    this.stripeWidth = 2.0,
    this.stripeAngleDegrees = -35.0,
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderDashPattern,
  }) : assert(opacity >= 0.0 && opacity <= 1.0),
       assert(patternOpacity >= 0.0 && patternOpacity <= 1.0),
       assert(stripeSpacing > 0),
       assert(stripeWidth > 0);

  /// バーのベース塗り全体に乗算する不透明度（0..1）。
  final double opacity;

  /// 上に重ねるパターン種別。
  final TentativeBarPattern pattern;

  /// パターン線の色。null の場合は白系を自動選択（バー色に対する
  /// コントラストで黒/白を切替）。
  final Color? patternColor;

  /// パターン線の不透明度（0..1）。
  final double patternOpacity;

  /// ストライプ/ハッチの間隔（px）。
  final double stripeSpacing;

  /// ストライプ/ハッチの線幅（px）。
  final double stripeWidth;

  /// ストライプ/ハッチの角度（度）。負値は左下→右上方向。
  final double stripeAngleDegrees;

  /// 縁取り色。null の場合はパターン色と同系色を自動選択。
  final Color? borderColor;

  /// 縁取り幅。0 の場合は描画しない。
  final double borderWidth;

  /// 縁取りの dash パターン。null の場合は実線。
  /// 例: `[3, 2]` で 3px 描画 → 2px 空白の繰り返し。
  final List<double>? borderDashPattern;

  TentativeBarDecoration copyWith({
    double? opacity,
    TentativeBarPattern? pattern,
    Color? patternColor,
    double? patternOpacity,
    double? stripeSpacing,
    double? stripeWidth,
    double? stripeAngleDegrees,
    Color? borderColor,
    double? borderWidth,
    List<double>? borderDashPattern,
  }) {
    return TentativeBarDecoration(
      opacity: opacity ?? this.opacity,
      pattern: pattern ?? this.pattern,
      patternColor: patternColor ?? this.patternColor,
      patternOpacity: patternOpacity ?? this.patternOpacity,
      stripeSpacing: stripeSpacing ?? this.stripeSpacing,
      stripeWidth: stripeWidth ?? this.stripeWidth,
      stripeAngleDegrees: stripeAngleDegrees ?? this.stripeAngleDegrees,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderDashPattern: borderDashPattern ?? this.borderDashPattern,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TentativeBarDecoration &&
          other.opacity == opacity &&
          other.pattern == pattern &&
          other.patternColor == patternColor &&
          other.patternOpacity == patternOpacity &&
          other.stripeSpacing == stripeSpacing &&
          other.stripeWidth == stripeWidth &&
          other.stripeAngleDegrees == stripeAngleDegrees &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          _listEquals(other.borderDashPattern, borderDashPattern);

  @override
  int get hashCode => Object.hash(
    opacity,
    pattern,
    patternColor,
    patternOpacity,
    stripeSpacing,
    stripeWidth,
    stripeAngleDegrees,
    borderColor,
    borderWidth,
    borderDashPattern == null ? null : Object.hashAll(borderDashPattern!),
  );

  static bool _listEquals(List<double>? a, List<double>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
