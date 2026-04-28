import 'package:flutter/material.dart';

/// An event drawn as a horizontal range bar across one or more days.
///
/// [start] and [end] are inclusive day boundaries. They will be normalized
/// to local midnight (year/month/day only) by the layout engine.
@immutable
class RangeCalendarEvent<T> {
  const RangeCalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.color,
    this.priority = 0,
    this.payload,
    this.isTentative = false,
    this.timeLabel,
  }) : assert(
         // Allow same-day events; only forbid end < start.
         // We check the y/m/d portion only via runtime helpers because
         // we cannot call non-const helpers from an assert initializer.
         // The layout engine performs the real validation.
         priority >= 0,
         'priority must be >= 0',
       );

  /// Stable identifier. Used for lane continuity across weeks.
  final String id;

  /// Title shown on the bar.
  final String title;

  /// Start date (inclusive).
  final DateTime start;

  /// End date (inclusive).
  final DateTime end;

  /// Override color. Falls back to the theme bar color.
  final Color? color;

  /// Higher priority events get lanes assigned first (drawn on top rows).
  /// Defaults to 0.
  final int priority;

  /// Arbitrary payload passed back through callbacks.
  final T? payload;

  /// 未定（仮）の予定かどうか。
  ///
  /// `true` のとき、`RangeBarStyle.tentativeDecoration` の設定に従って
  /// バーが装飾される（既定は斜めストライプ + 半透明）。
  /// `RangeBarStyle.tentativeBarBuilder` で完全カスタム描画も可能。
  final bool isTentative;

  /// バー上に時刻として表示する短いテキスト（例: "14:00"、"○月予定"）。
  ///
  /// `RangeBarStyle.contentMode` が `BarContentMode.time` /
  /// `BarContentMode.titleAndTime` のときに使われる。null の場合は
  /// 該当モードでも時刻は描画されない。
  final String? timeLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeCalendarEvent<T> &&
          other.id == id &&
          other.title == title &&
          other.start == start &&
          other.end == end &&
          other.color == color &&
          other.priority == priority &&
          other.payload == payload &&
          other.isTentative == isTentative &&
          other.timeLabel == timeLabel;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    start,
    end,
    color,
    priority,
    payload,
    isTentative,
    timeLabel,
  );
}
