import 'dart:math' as math;

import 'package:edencrew_assignment_starter/domain/stock/entity/daily_price.dart';
import 'package:edencrew_assignment_starter/shared/formatting/stock_format.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';

class CandleChart extends StatefulWidget {
  const CandleChart({super.key, required this.prices});

  final List<DailyPrice> prices;

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant CandleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex != null && _selectedIndex! >= widget.prices.length) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prices = widget.prices;
    return Semantics(
      label: '${prices.length}거래일 캔들 차트. 터치하면 해당 날짜의 가격을 확인할 수 있습니다.',
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _select(details.localPosition.dx),
          onHorizontalDragDown: (details) => _select(details.localPosition.dx),
          onHorizontalDragUpdate: (details) =>
              _select(details.localPosition.dx),
          onHorizontalDragEnd: (_) => setState(() => _selectedIndex = null),
          onTapUp: (_) => setState(() => _selectedIndex = null),
          child: CustomPaint(
            painter: _Candles(
              prices,
              context.colors,
              selectedIndex: _selectedIndex,
            ),
          ),
        ),
      ),
    );
  }

  void _select(double dx) {
    final count = widget.prices.length;
    if (count == 0) return;
    final sorted = [...widget.prices]..sort((a, b) => a.date.compareTo(b.date));
    final index = _ChartGeometry.indexForDx(
      dx,
      count,
      context.size?.width ?? 0,
    );
    if (index < 0 || index >= sorted.length) return;
    setState(() => _selectedIndex = index);
  }
}

class _Candles extends CustomPainter {
  _Candles(this.prices, this.colors, {this.selectedIndex});

  final List<DailyPrice> prices;
  final AppColors colors;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty || size.isEmpty) return;

    final sorted = [...prices]..sort((a, b) => a.date.compareTo(b.date));
    final geometry = _ChartGeometry(size, sorted.length);
    final low = sorted.map((x) => x.low).reduce(math.min).toDouble();
    final high = sorted.map((x) => x.high).reduce(math.max).toDouble();
    final maxVolume = sorted.map((x) => x.volume).reduce(math.max).toDouble();
    final spread = math.max(high - low, 1.0);
    final verticalPadding = spread * .12;

    double y(num value) {
      return geometry.priceBottom -
          (value - low + verticalPadding) /
              (spread + 2 * verticalPadding) *
              geometry.priceHeight;
    }

    _drawGridAndAxis(canvas, size, geometry, low, high);
    _drawArea(canvas, sorted, geometry, y);
    _drawVolumeBars(canvas, sorted, geometry, maxVolume);
    _drawCandles(canvas, sorted, geometry, y);

    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < sorted.length) {
      _drawCrosshair(canvas, sorted[selected], selected, geometry, y, size);
    }
  }

  void _drawGridAndAxis(
    Canvas canvas,
    Size size,
    _ChartGeometry geometry,
    double low,
    double high,
  ) {
    final gridPaint = Paint()
      ..color = colors.chartBaseline.withValues(alpha: .34)
      ..strokeWidth = .5;
    for (final ratio in const <double>[0, .5, 1]) {
      final y = geometry.priceTop + geometry.priceHeight * ratio;
      canvas.drawLine(
        Offset(0, y),
        Offset(geometry.axisLeft - 6, y),
        gridPaint,
      );
      _drawText(
        canvas,
        number((high - (high - low) * ratio).round()),
        Offset(geometry.axisLeft, y - 7),
        colors.chartAxisLabel,
        align: TextAlign.left,
      );
    }

    final sorted = [...prices]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.isNotEmpty) {
      _drawText(
        canvas,
        _shortDate(sorted.first.date),
        Offset(0, geometry.dateLabelTop),
        colors.chartAxisLabel,
      );
      _drawText(
        canvas,
        _shortDate(sorted.last.date),
        Offset(geometry.axisLeft - 42, geometry.dateLabelTop),
        colors.chartAxisLabel,
      );
    }
  }

  void _drawArea(
    Canvas canvas,
    List<DailyPrice> sorted,
    _ChartGeometry geometry,
    double Function(num value) y,
  ) {
    if (sorted.length < 2) return;
    final first = sorted.first.close;
    final last = sorted.last.close;
    final path = Path();
    for (var i = 0; i < sorted.length; i += 1) {
      final point = Offset(geometry.centerX(i), y(sorted[i].close));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path
      ..lineTo(geometry.centerX(sorted.length - 1), geometry.priceBottom)
      ..lineTo(geometry.centerX(0), geometry.priceBottom)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = (last >= first ? colors.chartAreaUp : colors.chartAreaDown),
    );
  }

  void _drawVolumeBars(
    Canvas canvas,
    List<DailyPrice> sorted,
    _ChartGeometry geometry,
    double maxVolume,
  ) {
    final paint = Paint()..color = colors.chartVolumeBar;
    for (var i = 0; i < sorted.length; i += 1) {
      final height = maxVolume <= 0
          ? 0.0
          : (sorted[i].volume / maxVolume) * geometry.volumeHeight;
      final left = geometry.left(i);
      canvas.drawRect(
        Rect.fromLTWH(
          left,
          geometry.volumeBottom - height,
          geometry.barWidth,
          math.max(1, height),
        ),
        paint,
      );
    }
  }

  void _drawCandles(
    Canvas canvas,
    List<DailyPrice> sorted,
    _ChartGeometry geometry,
    double Function(num value) y,
  ) {
    final wickPaint = Paint()
      ..color = colors.chartBaseline
      ..strokeWidth = math.max(.3, geometry.wickWidth)
      ..strokeCap = StrokeCap.square;

    for (var i = 0; i < sorted.length; i += 1) {
      final price = sorted[i];
      final candlePaint = Paint()
        ..color = price.close > price.open
            ? colors.chartLineUp
            : price.close < price.open
            ? colors.chartLineDown
            : colors.chartLineFlat;
      final left = geometry.left(i);
      final centerX = geometry.centerX(i);

      canvas.drawLine(
        Offset(centerX, y(price.high)),
        Offset(centerX, y(price.low)),
        wickPaint,
      );

      final top = math.min(y(price.open), y(price.close));
      final bottom = math.max(y(price.open), y(price.close));
      canvas.drawRect(
        Rect.fromLTWH(left, top, geometry.barWidth, math.max(1, bottom - top)),
        candlePaint,
      );
    }
  }

  void _drawCrosshair(
    Canvas canvas,
    DailyPrice price,
    int index,
    _ChartGeometry geometry,
    double Function(num value) y,
    Size size,
  ) {
    final x = geometry.centerX(index);
    final closeY = y(price.close);
    final crossPaint = Paint()
      ..color = colors.chartAxisLabel.withValues(alpha: .72)
      ..strokeWidth = .8;
    canvas.drawLine(
      Offset(x, geometry.priceTop),
      Offset(x, geometry.volumeBottom),
      crossPaint,
    );
    canvas.drawLine(
      Offset(0, closeY),
      Offset(geometry.axisLeft - 6, closeY),
      crossPaint,
    );

    final tooltip = '${_shortDate(price.date)}  ${number(price.close)}';
    final textPainter = _textPainter(
      tooltip,
      Colors.white,
      fontSize: 11,
      fontWeight: AppTypography.medium,
    )..layout();
    final tooltipWidth = textPainter.width + 16;
    final tooltipHeight = textPainter.height + 10;
    final left = (x + 8 + tooltipWidth > size.width)
        ? x - tooltipWidth - 8
        : x + 8;
    final top = math.max(0.0, closeY - tooltipHeight - 8);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, tooltipWidth, tooltipHeight),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xE61D1D1B));
    textPainter.paint(canvas, Offset(left + 8, top + 5));
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    TextAlign align = TextAlign.left,
  }) {
    final painter = _textPainter(text, color)..layout(maxWidth: 52);
    painter.paint(canvas, offset);
  }

  TextPainter _textPainter(
    String text,
    Color color, {
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          height: 1.2,
          fontWeight: fontWeight,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
  }

  String _shortDate(DateTime date) {
    return '${date.month}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _Candles oldDelegate) {
    return oldDelegate.prices != prices ||
        oldDelegate.colors != colors ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

final class _ChartGeometry {
  _ChartGeometry(this.size, this.count)
    : horizontalScale = size.width / referenceWidth,
      axisLeft = size.width - 54;

  static const referenceWidth = 361.0;
  static const _referenceSideInset = .8;
  static const _referenceBarWidth = 4.81;
  static const _referenceWickWidth = .3;

  final Size size;
  final int count;
  final double horizontalScale;
  final double axisLeft;

  double get sideInset => _referenceSideInset * horizontalScale;
  double get priceTop => 4;
  double get priceBottom => 136;
  double get priceHeight => priceBottom - priceTop;
  double get volumeBottom => 174;
  double get volumeHeight => 28;
  double get dateLabelTop => 184;
  double get referenceBarWidth => _referenceBarWidth * horizontalScale;
  double get wickWidth => _referenceWickWidth * horizontalScale;
  double get maxStep =>
      count == 1 ? referenceBarWidth : (axisLeft - sideInset * 2) / (count - 1);
  double get barWidth =>
      math.min(referenceBarWidth, math.max(.5, maxStep * .8));
  double get step =>
      count == 1 ? 0.0 : (axisLeft - sideInset * 2 - barWidth) / (count - 1);

  double left(int index) => sideInset + step * index;

  double centerX(int index) => left(index) + barWidth / 2;

  static int indexForDx(double dx, int count, double width) {
    if (count <= 1 || width <= 0) return 0;
    final axisLeft = width - 54;
    final sideInset = _referenceSideInset * (width / referenceWidth);
    final step = (axisLeft - sideInset * 2) / (count - 1);
    return ((dx - sideInset) / step).round().clamp(0, count - 1);
  }
}
