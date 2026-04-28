/// Google Calendar-style range bar calendar widget for Flutter.
///
/// See `RangeBarCalendar` for the main entry point.
library;

export 'src/engine/range_bar_layout_engine.dart';
export 'src/models/range_bar_calendar_format.dart';
export 'src/models/range_bar_event_tap_behavior.dart';
export 'src/models/range_bar_layout_result.dart';
export 'src/models/range_bar_segment.dart';
export 'src/models/range_calendar_event.dart';
export 'src/models/tentative_bar_decoration.dart';
export 'src/styles/range_bar_calendar_style.dart';
export 'src/styles/range_bar_header_style.dart';
export 'src/styles/range_bar_style.dart';
export 'src/utils/date_utils.dart'
    show
        isSameDay,
        normalizeDate,
        compareDate,
        firstDayOfWeek,
        firstDayOfMonth,
        lastDayOfMonth,
        addDays,
        daysBetweenInclusive,
        columnOfDay;
export 'src/widgets/range_bar_calendar.dart';
export 'src/widgets/range_bar_calendar_builders.dart';
export 'src/widgets/range_bar_segment_widget.dart';
