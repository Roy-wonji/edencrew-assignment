import 'package:flutter/widgets.dart';

enum StockIconType {
  star,
  starFilled,
  search,
  searchOff,
  refresh,
  sort,
  check,
  close,
  back,
}

class StockIcon extends StatelessWidget {
  const StockIcon(this.type, {super.key, this.size = 22, required this.color});

  final StockIconType type;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _StockIconPainter(type, color)),
  );
}

class _StockIconPainter extends CustomPainter {
  const _StockIconPainter(this.type, this.color);

  final StockIconType type;
  final Color color;

  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (type) {
      case StockIconType.star:
        canvas.drawPath(_starPath(size.width), stroke);
      case StockIconType.starFilled:
        canvas.drawPath(_starPath(size.width), fill);
      case StockIconType.search:
        _drawSearch(canvas, size.width, stroke);
      case StockIconType.searchOff:
        _drawSearch(canvas, size.width, stroke);
        canvas.drawPath(_searchOffPath(size.width), stroke);
      case StockIconType.refresh:
        canvas.drawPath(_refreshPath(size.width), stroke);
      case StockIconType.sort:
        canvas.drawPath(_sortPath(size.width), stroke);
      case StockIconType.check:
        canvas.drawPath(_checkPath(size.width), stroke..strokeWidth = 2);
      case StockIconType.close:
        canvas.drawPath(_closePath(size.width), stroke);
      case StockIconType.back:
        canvas.drawPath(_backPath(size.width), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _StockIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;

  // Figma source: figma-search-layout.svg Vector_13 and
  // figma-watchlist.svg Vector_10, normalized from the 22px icon box.
  static Path _starPath(double size) {
    final s = size / 22;
    return Path()
      ..moveTo(11 * s, 16.271 * s)
      ..lineTo(5.3423 * s, 19.245 * s)
      ..lineTo(6.4231 * s, 12.945 * s)
      ..lineTo(1.8398 * s, 8.484 * s)
      ..lineTo(8.1648 * s, 7.567 * s)
      ..lineTo(10.9936 * s, 1.835 * s)
      ..lineTo(13.822 * s, 7.567 * s)
      ..lineTo(20.147 * s, 8.484 * s)
      ..lineTo(15.564 * s, 12.945 * s)
      ..lineTo(16.645 * s, 19.245 * s)
      ..close();
  }

  // Figma source: figma-search-layout.svg Vector_8/9, normalized from the
  // 16px field icon box. The tab icon uses the same vector scaled to 22px.
  static void _drawSearch(Canvas canvas, double size, Paint paint) {
    final s = size / 16;
    canvas.drawCircle(Offset(6.6667 * s, 6.6667 * s), 4.6667 * s, paint);
    canvas.drawLine(Offset(10 * s, 10 * s), Offset(14 * s, 14 * s), paint);
  }

  // Figma source: figma-search-no-results.svg Vector_13, normalized from the
  // 40px empty-result search-off icon box.
  static Path _searchOffPath(double size) {
    final s = size / 40;
    return Path()
      ..moveTo(21.575 * s, 11.874 * s)
      ..lineTo(11.525 * s, 21.925 * s)
      ..moveTo(11.525 * s, 11.874 * s)
      ..lineTo(21.575 * s, 21.925 * s);
  }

  // Figma source: figma-watchlist.svg Vector_8/9, normalized from the
  // 20px header refresh icon box.
  static Path _refreshPath(double size) {
    final s = size / 20;
    return Path()
      ..moveTo(16.667 * s, 9.167 * s)
      ..cubicTo(
        16.463 * s,
        7.7002 * s,
        15.783 * s,
        6.3414 * s,
        14.731 * s,
        5.2996 * s,
      )
      ..cubicTo(
        13.679 * s,
        4.2578 * s,
        12.313 * s,
        3.5908 * s,
        10.845 * s,
        3.4013 * s,
      )
      ..cubicTo(
        9.376 * s,
        3.2118 * s,
        7.886 * s,
        3.5104 * s,
        6.604 * s,
        4.251 * s,
      )
      ..cubicTo(5.322 * s, 4.9917 * s, 4.319 * s, 6.1333 * s, 3.75 * s, 7.5 * s)
      ..moveTo(3.333 * s, 4.1667 * s)
      ..lineTo(3.333 * s, 7.5 * s)
      ..lineTo(6.667 * s, 7.5 * s)
      ..moveTo(3.333 * s, 10.8333 * s)
      ..cubicTo(
        3.537 * s,
        12.2998 * s,
        4.217 * s,
        13.6586 * s,
        5.269 * s,
        14.7004 * s,
      )
      ..cubicTo(
        6.322 * s,
        15.7422 * s,
        7.687 * s,
        16.4092 * s,
        9.155 * s,
        16.5987 * s,
      )
      ..cubicTo(
        10.624 * s,
        16.7882 * s,
        12.114 * s,
        16.4896 * s,
        13.396 * s,
        15.749 * s,
      )
      ..cubicTo(
        14.678 * s,
        15.0083 * s,
        15.681 * s,
        13.8667 * s,
        16.25 * s,
        12.5 * s,
      )
      ..moveTo(16.667 * s, 15.8333 * s)
      ..lineTo(16.667 * s, 12.5 * s)
      ..lineTo(13.333 * s, 12.5 * s);
  }

  // Figma source: figma-watchlist.svg align, normalized from the 16px box.
  static Path _sortPath(double size) {
    final s = size / 16;
    return Path()
      ..moveTo(4 * s, 10.5714 * s)
      ..lineTo(8 * s, 14 * s)
      ..lineTo(12 * s, 10.5714 * s)
      ..moveTo(8 * s, 14 * s)
      ..lineTo(8 * s, 2 * s);
  }

  // Figma source: figma-watchlist-sort.svg Vector_13, normalized from the
  // 22px selected-row trailing check icon box.
  static Path _checkPath(double size) {
    final s = size / 22;
    return Path()
      ..moveTo(3 * s, 11 * s)
      ..lineTo(8 * s, 16 * s)
      ..lineTo(18 * s, 6 * s);
  }

  // Figma source: figma-search-layout.svg Vector_10/11, normalized from the
  // 16px field close icon box.
  static Path _closePath(double size) {
    final s = size / 16;
    return Path()
      ..moveTo(12 * s, 4 * s)
      ..lineTo(4 * s, 12 * s)
      ..moveTo(4 * s, 4 * s)
      ..lineTo(12 * s, 12 * s);
  }

  // Figma source: figma-detail.svg Vector_8/9/10, normalized from the
  // 24px detail header back icon box.
  static Path _backPath(double size) {
    final s = size / 24;
    return Path()
      ..moveTo(6.1667 * s, 12 * s)
      ..lineTo(17.8334 * s, 12 * s)
      ..moveTo(6.1667 * s, 12 * s)
      ..lineTo(11.1667 * s, 17 * s)
      ..moveTo(6.1667 * s, 12 * s)
      ..lineTo(11.1667 * s, 7 * s);
  }
}
