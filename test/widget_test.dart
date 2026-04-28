import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:range_bar_calendar/range_bar_calendar.dart';

Widget _wrap(Widget child) {
  // カレンダーは intrinsic 高さ（ヘッダ + 曜日行 + idealRowHeight × 週数）を
  // 報告する。テスト用 surface（800x600）に月 6 週ビューが収まらない場合
  // RenderFlex overflow が発生するため、SingleChildScrollView で包むことで
  // overflow を防ぎ、レイアウトは intrinsic 高さで成立させる。
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 400, child: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('RangeBarCalendar が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        RangeBarCalendar<String>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: DateTime(2025, 11, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RangeBarCalendar<String>), findsOneWidget);
  });

  testWidgets('日付タップで onDaySelected が呼ばれる', (WidgetTester tester) async {
    DateTime? tapped;
    await tester.pumpWidget(
      _wrap(
        RangeBarCalendar<String>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: DateTime(2025, 11, 15),
          onDaySelected: (DateTime d, DateTime f) => tapped = d,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Find a non-outside day text and tap.
    final Finder textFinder = find.text('15').first;
    await tester.tap(textFinder);
    await tester.pumpAndSettle();
    expect(tapped, isNotNull);
  });

  testWidgets(
    '期間バー単発タップ: デフォルトでは onEventOpenRequested は呼ばれず onEventSelected のみ呼ばれる',
    (WidgetTester tester) async {
      RangeCalendarEvent<String>? selected;
      RangeCalendarEvent<String>? opened;
      await tester.pumpWidget(
        _wrap(
          RangeBarCalendar<String>(
            firstDay: DateTime(2025, 1, 1),
            lastDay: DateTime(2026, 12, 31),
            focusedDay: DateTime(2025, 11, 15),
            events: <RangeCalendarEvent<String>>[
              RangeCalendarEvent<String>(
                id: 'trip',
                title: '北海道旅行',
                start: DateTime(2025, 11, 12),
                end: DateTime(2025, 11, 16),
              ),
            ],
            onEventSelected: (RangeCalendarEvent<String> e) => selected = e,
            onEventOpenRequested: (RangeCalendarEvent<String> e) => opened = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('北海道旅行'));
      await tester.pumpAndSettle();
      expect(selected, isNotNull);
      expect(selected!.id, 'trip');
      expect(opened, isNull, reason: '単発タップで詳細遷移してはならない');
    },
  );

  testWidgets('期間バー長押しで onEventLongPress が呼ばれる', (WidgetTester tester) async {
    RangeCalendarEvent<String>? longPressed;
    await tester.pumpWidget(
      _wrap(
        RangeBarCalendar<String>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: DateTime(2025, 11, 15),
          events: <RangeCalendarEvent<String>>[
            RangeCalendarEvent<String>(
              id: 'trip',
              title: '北海道旅行',
              start: DateTime(2025, 11, 12),
              end: DateTime(2025, 11, 16),
            ),
          ],
          onEventLongPress: (RangeCalendarEvent<String> e) => longPressed = e,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.text('北海道旅行'));
    await tester.pumpAndSettle();
    expect(longPressed, isNotNull);
    expect(longPressed!.id, 'trip');
  });

  testWidgets(
    'eventTapBehavior=openDetails のとき単発タップで onEventOpenRequested が呼ばれる',
    (WidgetTester tester) async {
      RangeCalendarEvent<String>? opened;
      await tester.pumpWidget(
        _wrap(
          RangeBarCalendar<String>(
            firstDay: DateTime(2025, 1, 1),
            lastDay: DateTime(2026, 12, 31),
            focusedDay: DateTime(2025, 11, 15),
            eventTapBehavior: RangeBarEventTapBehavior.openDetails,
            events: <RangeCalendarEvent<String>>[
              RangeCalendarEvent<String>(
                id: 'trip',
                title: '北海道旅行',
                start: DateTime(2025, 11, 12),
                end: DateTime(2025, 11, 16),
              ),
            ],
            onEventOpenRequested: (RangeCalendarEvent<String> e) => opened = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('北海道旅行'));
      await tester.pumpAndSettle();
      expect(opened, isNotNull);
    },
  );

  testWidgets('eventTapBehavior=none のとき単発タップで何も呼ばれない', (
    WidgetTester tester,
  ) async {
    RangeCalendarEvent<String>? selected;
    RangeCalendarEvent<String>? opened;
    await tester.pumpWidget(
      _wrap(
        RangeBarCalendar<String>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: DateTime(2025, 11, 15),
          eventTapBehavior: RangeBarEventTapBehavior.none,
          events: <RangeCalendarEvent<String>>[
            RangeCalendarEvent<String>(
              id: 'trip',
              title: '北海道旅行',
              start: DateTime(2025, 11, 12),
              end: DateTime(2025, 11, 16),
            ),
          ],
          onEventSelected: (RangeCalendarEvent<String> e) => selected = e,
          onEventOpenRequested: (RangeCalendarEvent<String> e) => opened = e,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('北海道旅行'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(opened, isNull);
  });

  testWidgets('selectedEventId に一致するバーは選択枠が描画される', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        RangeBarCalendar<String>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: DateTime(2025, 11, 15),
          selectedEventId: 'trip',
          events: <RangeCalendarEvent<String>>[
            RangeCalendarEvent<String>(
              id: 'trip',
              title: '北海道旅行',
              start: DateTime(2025, 11, 12),
              end: DateTime(2025, 11, 16),
            ),
            RangeCalendarEvent<String>(
              id: 'other',
              title: '通常予定',
              start: DateTime(2025, 11, 20),
              end: DateTime(2025, 11, 20),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final segments =
        tester
            .widgetList<RangeBarSegmentWidget<String>>(
              find.byType(RangeBarSegmentWidget<String>),
            )
            .toList();
    expect(segments, isNotEmpty);
    final selectedSegments = segments.where(
      (RangeBarSegmentWidget<String> w) => w.isSelected,
    );
    expect(selectedSegments, isNotEmpty);
    expect(selectedSegments.every((w) => w.segment.event.id == 'trip'), isTrue);
    expect(
      segments
          .where((w) => !w.isSelected)
          .every((w) => w.segment.event.id == 'other'),
      isTrue,
    );
  });

  testWidgets('@deprecated onEventTap は onEventSelected の代替として動作する（後方互換）', (
    WidgetTester tester,
  ) async {
    RangeCalendarEvent<String>? tapped;
    await tester.pumpWidget(
      _wrap(
        RangeBarCalendar<String>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: DateTime(2025, 11, 15),
          events: <RangeCalendarEvent<String>>[
            RangeCalendarEvent<String>(
              id: 'trip',
              title: '北海道旅行',
              start: DateTime(2025, 11, 12),
              end: DateTime(2025, 11, 16),
            ),
          ],
          // ignore: deprecated_member_use
          onEventTap: (RangeCalendarEvent<String> e) => tapped = e,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('北海道旅行'));
    await tester.pumpAndSettle();
    expect(tapped, isNotNull);
    expect(tapped!.id, 'trip');
  });

  // -- ここから追加: PO フィードバック対応の回帰テスト ---------------------

  testWidgets('outside（前月/翌月）の日付タップでも onDaySelected が呼ばれ、focusedDay は維持される', (
    WidgetTester tester,
  ) async {
    DateTime? tappedDay;
    DateTime? returnedFocused;
    final DateTime focused = DateTime(2025, 11, 15);
    await tester.pumpWidget(
      _wrap(
        RangeBarCalendar<String>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: focused,
          onDaySelected: (DateTime d, DateTime f) {
            tappedDay = d;
            returnedFocused = f;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 11 月の月表示で先頭セル（11/1 の前にある outside の日）をタップ。
    // 11/1 は土曜なので、最初に出てくる outside は 10/26〜10/31 の範囲。
    // ここでは「26」のテキストをタップする（10 月 26 日）。
    final Finder outside = find.text('26').first;
    await tester.tap(outside, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tappedDay, isNotNull, reason: 'outside セルもタップに反応する必要がある');
    // ライブラリ仕様: outside タップでは focusedDay の月は据え置き（月ジャンプしない）。
    // ページ内部で焦点日を月の代表日に正規化するため、必ずしも入力と一致しないが、
    // 月（year/month）が変わらないことが「月切替を起こさない」契約。
    expect(returnedFocused, isNotNull);
    expect(returnedFocused!.year, focused.year);
    expect(returnedFocused!.month, focused.month);
    // タップ対象の day（outside の 10/26）の月とは異なる
    expect(tappedDay!.month, isNot(returnedFocused!.month));
  });

  testWidgets('singleDayEventBuilder は単日かつ非tentativeのイベントで呼ばれる', (
    WidgetTester tester,
  ) async {
    final Set<String> inlineCalled = <String>{};
    await tester.pumpWidget(
      _wrap(
        RangeBarCalendar<String>(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: DateTime(2025, 11, 15),
          events: <RangeCalendarEvent<String>>[
            // 単日（時刻あり）→ inline で描かれるべき
            RangeCalendarEvent<String>(
              id: 'single',
              title: '会議',
              start: DateTime(2025, 11, 10),
              end: DateTime(2025, 11, 10),
              timeLabel: '10:00',
            ),
            // 複数日 → 通常バー
            RangeCalendarEvent<String>(
              id: 'trip',
              title: '北海道旅行',
              start: DateTime(2025, 11, 12),
              end: DateTime(2025, 11, 16),
            ),
            // 単日でも tentative → 通常バー
            RangeCalendarEvent<String>(
              id: 'month',
              title: '月予定',
              start: DateTime(2025, 11, 20),
              end: DateTime(2025, 11, 20),
              isTentative: true,
            ),
          ],
          builders: RangeBarCalendarBuilders<String>(
            singleDayEventBuilder: (
              BuildContext _,
              RangeBarSegment<String> seg,
            ) {
              inlineCalled.add(seg.event.id);
              return Text('inline:${seg.event.title}');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(inlineCalled, contains('single'));
    expect(inlineCalled.contains('trip'), isFalse, reason: '複数日はバー描画');
    expect(
      inlineCalled.contains('month'),
      isFalse,
      reason: 'tentative 単日はバー描画',
    );
    expect(find.text('inline:会議'), findsOneWidget);
  });
}
