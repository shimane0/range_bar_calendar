/// How a single tap on an event bar should behave.
enum RangeBarEventTapBehavior {
  /// Single tap selects the event (updates selected event / preview).
  ///
  /// This is the recommended default for calendar surfaces where users
  /// often pan, scroll, and compare events. Detail navigation should be
  /// triggered through an explicit affordance (e.g. a preview card or
  /// a long-press / details button).
  selectOnly,

  /// Single tap opens the event details directly.
  ///
  /// Use only when the calendar is purely a launcher and accidental
  /// navigation is unlikely.
  openDetails,

  /// Single tap is ignored. Selection / open is exposed via callbacks
  /// only for explicit invocations from outside.
  none,
}
