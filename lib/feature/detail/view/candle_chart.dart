import 'dart:math' as math;

import 'package:edencrew_assignment_starter/domain/stock/entity/daily_price.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';

class CandleChart extends StatefulWidget {
  const CandleChart({super.key, required this.prices});

  final List<DailyPrice> prices;

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void didUpdateWidget(covariant CandleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prices != widget.prices) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.prices.length}거래일 캔들 차트. 상세 가격은 아래 일별 시세 표에서 확인하세요.',
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOut,
            ),
            child: CustomPaint(
              painter: _Candles(widget.prices, context.colors),
            ),
          ),
        ),
      ),
    );
  }
}

class _Candles extends CustomPainter {
  _Candles(this.prices, this.colors);

  static const _referenceWidth = 361.0;
  static const _referenceSideInset = .8;
  static const _referenceBarWidth = 4.81;
  static const _referenceWickWidth = .3;

  final List<DailyPrice> prices;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty || size.isEmpty) return;

    final sorted = [...prices]..sort((a, b) => a.date.compareTo(b.date));
    final low = sorted.map((x) => x.low).reduce(math.min).toDouble();
    final high = sorted.map((x) => x.high).reduce(math.max).toDouble();
    final spread = math.max(high - low, 1.0);
    final verticalPadding = spread * .12;
    final horizontalScale = size.width / _referenceWidth;
    final referenceBarWidth = _referenceBarWidth * horizontalScale;
    final wickWidth = math.max(.3, _referenceWickWidth * horizontalScale);
    final sideInset = _referenceSideInset * horizontalScale;
    final maxStep = sorted.length == 1
        ? referenceBarWidth
        : (size.width - sideInset * 2) / (sorted.length - 1);
    final barWidth = math.min(referenceBarWidth, math.max(.5, maxStep * .8));
    final step = sorted.length == 1
        ? 0.0
        : (size.width - sideInset * 2 - barWidth) / (sorted.length - 1);
    final wickPaint = Paint()
      ..color = colors.chartBaseline
      ..strokeWidth = wickWidth
      ..strokeCap = StrokeCap.square;

    double y(num value) {
      return size.height -
          (value - low + verticalPadding) /
              (spread + 2 * verticalPadding) *
              size.height;
    }

    for (var i = 0; i < sorted.length; i++) {
      final price = sorted[i];
      final candlePaint = Paint()
        ..color = price.close > price.open
            ? colors.chartLineUp
            : price.close < price.open
            ? colors.chartLineDown
            : colors.chartBaseline;
      final left = sideInset + step * i;
      final centerX = left + barWidth / 2;

      canvas.drawLine(
        Offset(centerX, y(price.high)),
        Offset(centerX, y(price.low)),
        wickPaint,
      );

      final top = math.min(y(price.open), y(price.close));
      final bottom = math.max(y(price.open), y(price.close));
      canvas.drawRect(
        Rect.fromLTWH(left, top, barWidth, math.max(1, bottom - top)),
        candlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Candles oldDelegate) {
    return oldDelegate.prices != prices || oldDelegate.colors != colors;
  }
}
