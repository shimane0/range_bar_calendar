# range_bar_calendar

Google カレンダー風の「期間予定バー」表示に特化した Flutter カレンダーウィジェット。

複数日にまたがる予定を、月をまたぐ場合・週で折り返す場合・終了日が表示範囲外の場合も
含めて自然に横長バーで描画します。

## 特徴

- 月表示 / 隔週(2週) / 週 のフォーマット切り替え
- 期間バーの自動レーン配置（同じ予定は週をまたいでも可能な限り同じレーンを使用）
- 1日に表示できる最大バー数を超えた場合の `+N` 表示（オーバーフロー集約）
- 任意のセル / バー / ヘッダ / 曜日表示を `builders` で完全カスタマイズ可能
- Riverpod / DB に依存しない純粋な UI ライブラリ
- `table_calendar` の主要 API（`focusedDay` / `firstDay` / `lastDay` /
  `calendarFormat` / `onDaySelected` / `onPageChanged` / `onFormatChanged`）
  と命名互換

## 使い方

```dart
import 'package:range_bar_calendar/range_bar_calendar.dart';

RangeBarCalendar<String>(
  firstDay: DateTime(2020, 1, 1),
  lastDay: DateTime(2030, 12, 31),
  focusedDay: _focusedDay,
  calendarFormat: _format,
  selectedDay: _selectedDay,
  events: [
    RangeCalendarEvent(
      id: 'trip-1',
      title: '北海道旅行',
      start: DateTime(2025, 11, 12),
      end: DateTime(2025, 11, 16),
      color: Colors.indigo,
      payload: 'trip-1',
    ),
  ],
  onDaySelected: (day, focusedDay) =>
      setState(() {
        _selectedDay = day;
        _focusedDay = focusedDay;
      }),
  onPageChanged: (focusedDay) =>
      setState(() => _focusedDay = focusedDay),
  onFormatChanged: (f) => setState(() => _format = f),
  // 単発タップは「選択のみ」。詳細遷移は長押しまたは別UIで行う想定。
  selectedEventId: _selectedEventId,
  eventTapBehavior: RangeBarEventTapBehavior.selectOnly, // デフォルト
  onEventSelected: (event) =>
      setState(() => _selectedEventId = event.id),
  onEventLongPress: (event) =>
      Navigator.of(context).push(/* 詳細画面へ */),
);
```

> **タップ挙動について**
> カレンダーUXの原則として、期間バーの単発タップで詳細画面へ即遷移するのは
> 誤遷移の温床になります。本ライブラリでは `eventTapBehavior` で
> 挙動を選択できます。
> - `selectOnly`（推奨/デフォルト）: 単発タップ→`onEventSelected`、長押し→`onEventLongPress`
> - `openDetails`: 単発タップ→`onEventOpenRequested`
> - `none`: 単発タップを無視（カードや別UIから操作）
>
> `onEventTap` は後方互換のため残されていますが非推奨です。

## レイアウトアルゴリズム概要

1. 表示範囲（`visibleDays`）に交差するイベントを抽出。
2. 優先度 desc → 開始日 asc → 期間長 desc で安定ソート。
3. 各イベントを「週 × カラム」のセグメントに分割。
4. 週ごとにレーン（lane）を割り当て。同じイベントは隣接週と
   同じレーンを優先的に再利用（横方向の連続感）。
5. `maxBarsPerDay` を超えたセグメントは hidden 扱いとし、対象日に
   `+N` インジケータを付与。

詳しくは `lib/src/engine/range_bar_layout_engine.dart` 参照。

## table_calendar との比較

| 機能 | range_bar_calendar | table_calendar |
|---|---|---|
| 期間バー表示 | ◎ ネイティブ | △ Marker は1日単位 |
| 週またぎの自動分割 | ◎ | × |
| `+N` オーバーフロー集約 | ◎ | × |
| Marker (点・数値) | △ ビルダーで実装 | ◎ |
| eventLoader API | △ 補助的 | ◎ |
| Range / multi-day 選択 | △ 単日選択のみ | ◎ |

期間予定バー主体の UI（旅行・キャンペーン・プロジェクト等）を
持つアプリではこちらを、ポイント予定主体（タスク・todo 等）の
場合は `table_calendar` を選ぶと良いでしょう。

## 既知の制限

- バーの高さ・余白はテーマ単位の固定値（行ごとの自動可変化は未対応）。
- 現状ドラッグでの予定移動・リサイズは未対応（タップ/ロングタップのみ）。
- Adaptive layout（タブレット時の二画面表示）は未対応。
