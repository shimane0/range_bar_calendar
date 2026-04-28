import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/range_bar_segment.dart';
import '../models/tentative_bar_decoration.dart';
import '../styles/range_bar_style.dart';

/// Default rendering of a single range bar segment.
///
/// Gesture handling is intentionally kept minimal: only `onTap` and
/// `onLongPress` are claimed, which lets enclosing horizontal drag
/// recognizers (e.g. PageView) win the gesture arena as soon as the
/// pointer moves horizontally. This way users can swipe months even
/// when the gesture starts on top of a bar.
class RangeBarSegmentWidget<T> extends StatelessWidget {
  const RangeBarSegmentWidget({
    required this.segment,
    required this.style,
    this.onTap,
    this.onTapWithPosition,
    this.onLongPress,
    this.isSelected = false,
    super.key,
  });

  final RangeBarSegment<T> segment;
  final RangeBarStyle style;
  final VoidCallback? onTap;

  /// タップ位置（バー内のローカル座標）も併せて受け取りたい場合に指定する。
  /// `onTapWithPosition` が設定されている場合は `onTap` より優先される。
  /// バーが複数日にまたがる際、どの日がタップされたかを特定するために使う。
  final void Function(Offset localPosition)? onTapWithPosition;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isTentative = segment.event.isTentative;
    final TentativeBarDecoration? deco = style.tentativeDecoration;
    final bool applyTentative = isTentative && deco != null;

    double effectiveOpacity =
        isSelected ? (style.selectedOpacity ?? style.opacity) : style.opacity;
    if (applyTentative) {
      effectiveOpacity *= deco.opacity;
    }

    final Color baseColor =
        segment.event.color ?? style.defaultColor ?? theme.colorScheme.primary;
    final Color color = baseColor.withValues(alpha: effectiveOpacity);

    // Caller may fully override the bar widget for tentative events.
    if (applyTentative && style.tentativeBarBuilder != null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTapWithPosition != null ? null : onTap,
        onTapUp:
            onTapWithPosition != null
                ? (TapUpDetails d) => onTapWithPosition!(d.localPosition)
                : null,
        onLongPress: onLongPress,
        child: style.tentativeBarBuilder!(context, segment, baseColor),
      );
    }

    final BorderRadius radius = BorderRadius.only(
      topLeft: Radius.circular(
        segment.startsInsideVisibleRange
            ? style.cornerRadius
            : style.continuationCornerRadius,
      ),
      bottomLeft: Radius.circular(
        segment.startsInsideVisibleRange
            ? style.cornerRadius
            : style.continuationCornerRadius,
      ),
      topRight: Radius.circular(
        segment.endsInsideVisibleRange
            ? style.cornerRadius
            : style.continuationCornerRadius,
      ),
      bottomRight: Radius.circular(
        segment.endsInsideVisibleRange
            ? style.cornerRadius
            : style.continuationCornerRadius,
      ),
    );

    final TextStyle? titleStyle =
        style.titleStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: _onColor(color),
          fontWeight: FontWeight.w500,
        );

    final BorderSide? selectedBorderSide =
        isSelected
            ? (style.selectedBorder ??
                BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  width: 1.5,
                ))
            : null;

    final String? label = _resolveLabel();
    final Widget? labelChild =
        label == null
            ? null
            : Padding(
              padding: style.titlePadding,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            );

    // Build pattern overlay (stripe / hatch) for tentative bars.
    Widget? patternOverlay;
    if (applyTentative && deco.pattern != TentativeBarPattern.none) {
      final Color patternColor = (deco.patternColor ?? _onColor(color))
          .withValues(alpha: deco.patternOpacity);
      patternOverlay = ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: _TentativePatternPainter(
            pattern: deco.pattern,
            color: patternColor,
            stripeSpacing: deco.stripeSpacing,
            stripeWidth: deco.stripeWidth,
            angleRad: deco.stripeAngleDegrees * math.pi / 180.0,
          ),
        ),
      );
    }

    // Optional dashed border overlay for tentative bars (when borderDashPattern is set).
    Widget? dashedBorderOverlay;
    if (applyTentative &&
        deco.borderWidth > 0 &&
        deco.borderDashPattern != null &&
        deco.borderDashPattern!.isNotEmpty) {
      dashedBorderOverlay = CustomPaint(
        painter: _DashedBorderPainter(
          color: deco.borderColor ?? baseColor,
          width: deco.borderWidth,
          dashPattern: deco.borderDashPattern!,
          radius: radius,
        ),
      );
    }

    final Widget bar = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border:
            selectedBorderSide != null
                ? Border.fromBorderSide(selectedBorderSide)
                : (applyTentative &&
                    deco.borderWidth > 0 &&
                    (deco.borderDashPattern == null ||
                        deco.borderDashPattern!.isEmpty))
                ? Border.all(
                  color: deco.borderColor ?? baseColor,
                  width: deco.borderWidth,
                )
                : null,
        boxShadow: isSelected ? style.selectedShadow : null,
      ),
      child:
          patternOverlay == null && dashedBorderOverlay == null
              ? labelChild
              : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (patternOverlay != null) patternOverlay,
                  if (dashedBorderOverlay != null) dashedBorderOverlay,
                  if (labelChild != null) labelChild,
                ],
              ),
    );

    // Use translucent so day-cell taps under thin gaps still register,
    // while tap on the bar itself is captured. Only onTap/onLongPress
    // are registered so drag gestures bubble up to PageView.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTapWithPosition != null ? null : onTap,
      onTapUp:
          onTapWithPosition != null
              ? (TapUpDetails d) => onTapWithPosition!(d.localPosition)
              : null,
      onLongPress: onLongPress,
      child: bar,
    );
  }

  /// Resolve which text (if any) should be shown on this segment.
  /// Returns `null` to skip text rendering. Text is only drawn on the
  /// segment that contains the event's actual start (i.e. the first
  /// segment of the event chain).
  String? _resolveLabel() {
    if (!segment.startsAtEventStart) return null;

    // Honor the deprecated showTitle flag: when explicitly false, hide
    // text regardless of contentMode.
    // ignore: deprecated_member_use_from_same_package
    final BarContentMode mode =
        // ignore: deprecated_member_use_from_same_package
        style.showTitle == false ? BarContentMode.none : style.contentMode;

    if (style.barLabelBuilder != null) {
      final String? overridden = style.barLabelBuilder!(segment, mode);
      if (overridden != null) return overridden;
    }

    final String title = segment.event.title;
    final String? time = segment.event.timeLabel;
    switch (mode) {
      case BarContentMode.none:
        return null;
      case BarContentMode.title:
        return title;
      case BarContentMode.time:
        return time;
      case BarContentMode.titleAndTime:
        if (time == null || time.isEmpty) return title;
        return '$title ・ $time';
    }
  }

  Color _onColor(Color background) {
    final double luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// Paints a tentative pattern (diagonal stripes / hatch) over a bar.
class _TentativePatternPainter extends CustomPainter {
  _TentativePatternPainter({
    required this.pattern,
    required this.color,
    required this.stripeSpacing,
    required this.stripeWidth,
    required this.angleRad,
  });

  final TentativeBarPattern pattern;
  final Color color;
  final double stripeSpacing;
  final double stripeWidth;
  final double angleRad;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stripeWidth;

    void drawStripes(double angle) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(angle);
      // Diagonal length needs to cover the rotated bounding box.
      final double diag = math.sqrt(
        size.width * size.width + size.height * size.height,
      );
      final double half = diag / 2 + stripeSpacing;
      for (double x = -half; x <= half; x += stripeSpacing) {
        canvas.drawLine(Offset(x, -half), Offset(x, half), paint);
      }
      canvas.restore();
    }

    switch (pattern) {
      case TentativeBarPattern.none:
        return;
      case TentativeBarPattern.stripe:
        drawStripes(angleRad);
        break;
      case TentativeBarPattern.hatch:
        drawStripes(angleRad);
        drawStripes(angleRad + math.pi / 2);
        break;
      case TentativeBarPattern.dashedBorder:
        // Pattern body is empty — the dashed border is rendered by
        // _DashedBorderPainter when borderDashPattern is provided.
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _TentativePatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.color != color ||
        oldDelegate.stripeSpacing != stripeSpacing ||
        oldDelegate.stripeWidth != stripeWidth ||
        oldDelegate.angleRad != angleRad;
  }
}

/// Paints a dashed border around the bar's rounded rect.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.width,
    required this.dashPattern,
    required this.radius,
  });

  final Color color;
  final double width;
  final List<double> dashPattern;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || dashPattern.isEmpty) return;
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width;
    final RRect rrect = radius.toRRect(Offset.zero & size);
    final Path path = Path()..addRRect(rrect);
    _drawDashed(canvas, path, paint, dashPattern);
  }

  static void _drawDashed(
    Canvas canvas,
    Path source,
    Paint paint,
    List<double> dashPattern,
  ) {
    int i = 0;
    for (final ui in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < ui.length) {
        final double seg = dashPattern[i % dashPattern.length];
        final double next = (distance + seg).clamp(0.0, ui.length);
        if (draw) {
          canvas.drawPath(ui.extractPath(distance, next), paint);
        }
        distance = next;
        draw = !draw;
        i++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.width != width ||
        oldDelegate.dashPattern != dashPattern ||
        oldDelegate.radius != radius;
  }
}
