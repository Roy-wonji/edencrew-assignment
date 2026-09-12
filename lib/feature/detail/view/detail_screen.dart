import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/shared/design_system/stock_icon.dart';
import 'package:edencrew_assignment_starter/shared/design_system/stock_widgets.dart';
import 'package:edencrew_assignment_starter/shared/formatting/stock_format.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';

import '../../shared/state/load_phase.dart';
import '../state/detail_state.dart';
import 'candle_chart.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.state,
    required this.stock,
    required this.quote,
    required this.isFavorite,
    required this.quoteLoading,
    required this.onBack,
    required this.onFavorite,
    required this.onPeriod,
    required this.onLoadMoreDailyPrices,
    required this.onRetryQuote,
    this.quoteError,
  });

  final DetailState state;
  final Stock stock;
  final Quote? quote;
  final bool isFavorite;
  final bool quoteLoading;
  final String? quoteError;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final ValueChanged<ChartPeriod> onPeriod;
  final VoidCallback onLoadMoreDailyPrices;
  final VoidCallback onRetryQuote;

  @override
  Widget build(BuildContext context) {
    final detail = state;
    final quote = this.quote;
    final prices = [...detail.prices]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            _DetailAppBar(
              stock: stock,
              isFavorite: isFavorite,
              onBack: onBack,
              onFavorite: onFavorite,
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 160 &&
                      detail.hasMoreDailyPrices) {
                    onLoadMoreDailyPrices();
                  }
                  return false;
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CurrentPrice(
                        quote: quote,
                        quoteLoading: quoteLoading,
                      ),
                    ),
                    if (quoteError != null)
                      ErrorNotice(message: quoteError!, retry: onRetryQuote),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PeriodTabs(
                        selected: detail.period,
                        onPeriod: onPeriod,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (detail.phase == LoadPhase.loading ||
                        detail.phase == LoadPhase.refreshing)
                      LinearProgressIndicator(
                        minHeight: 2,
                        color: context.colors.accentDefault,
                        backgroundColor: context.colors.surfaceRaised,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ChartPanel(
                        stockId: stock.id,
                        prices: prices,
                        phase: detail.phase,
                        errorMessage: detail.errorMessage,
                        onRetry: () => onPeriod(detail.period),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _QuoteSummary(quote: quote),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _DailyPrices(
                        prices: prices
                            .take(detail.visibleDailyPriceCount)
                            .toList(growable: false),
                        hasMore: detail.hasMoreDailyPrices,
                        loadingMore:
                            detail.phase == LoadPhase.loading &&
                            !detail.hasMoreDailyPrices,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({
    required this.stock,
    required this.isFavorite,
    required this.onBack,
    required this.onFavorite,
  });

  final Stock stock;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: Row(
        children: [
          _IconTapTarget(
            tooltip: '뒤로 가기',
            onTap: onBack,
            child: StockIcon(
              StockIconType.back,
              size: 24,
              color: context.colors.textSecondary,
            ),
          ),
          Expanded(child: _HeaderIdentity(stock: stock)),
          _IconTapTarget(
            tooltip: isFavorite ? '관심 해제' : '관심 등록',
            onTap: onFavorite,
            child: StockIcon(
              isFavorite ? StockIconType.starFilled : StockIconType.star,
              size: 24,
              color: isFavorite
                  ? context.colors.favoriteActive
                  : context.colors.favoriteInactive,
            ),
          ),
          const SizedBox(width: 3),
        ],
      ),
    );
  }
}

class _IconTapTarget extends StatelessWidget {
  const _IconTapTarget({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(width: 48, height: 55, child: Center(child: child)),
      ),
    );
  }
}

class _HeaderIdentity extends StatelessWidget {
  const _HeaderIdentity({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stock.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 15,
            height: 20 / 15,
            letterSpacing: -.1,
            fontWeight: AppTypography.medium,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: stock.symbol,
                style: const TextStyle(fontFamily: 'Inter'),
              ),
              TextSpan(text: ' · ${stock.market}'),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 11,
            height: 14 / 11,
          ),
        ),
      ],
    );
  }
}

class _CurrentPrice extends StatelessWidget {
  const _CurrentPrice({required this.quote, required this.quoteLoading});

  final Quote? quote;
  final bool quoteLoading;

  @override
  Widget build(BuildContext context) {
    final quote = this.quote;
    if (quote == null) {
      if (quoteLoading) {
        return const SizedBox(height: 36, child: QuoteSkeleton());
      }
      return SizedBox(
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '현재가를 불러오지 못했습니다',
            style: TextStyle(color: context.colors.textTertiary),
          ),
        ),
      );
    }

    final change = quote.change;
    final sign = change > 0
        ? '▲'
        : change < 0
        ? '▼'
        : '—';

    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            number(quote.current),
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 30,
              height: 36 / 30,
              letterSpacing: -.4,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$sign '),
                  TextSpan(
                    text: number(change.abs()),
                    style: const TextStyle(fontFamily: 'Inter'),
                  ),
                  const TextSpan(text: ' ('),
                  TextSpan(
                    text: percent(quote.changeRate),
                    style: const TextStyle(fontFamily: 'Inter'),
                  ),
                  const TextSpan(text: ')'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: changeColor(context, change),
                fontSize: 15,
                height: 20 / 15,
                letterSpacing: -.1,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selected, required this.onPeriod});

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onPeriod;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 4.0;
          final chipWidth = (constraints.maxWidth - gap * 3) / 4;

          return Row(
            children: [
              for (final period in ChartPeriod.values) ...[
                _PeriodChip(
                  period: period,
                  selected: selected == period,
                  width: chipWidth,
                  onTap: () => onPeriod(period),
                ),
                if (period != ChartPeriod.values.last)
                  const SizedBox(width: gap),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.period,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final ChartPeriod period;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? context.colors.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: 28,
            child: Center(
              child: Text(
                period.label,
                style: TextStyle(
                  color: selected
                      ? context.colors.accentDefault
                      : context.colors.textSecondary,
                  fontSize: 13,
                  height: 18 / 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPanel extends StatefulWidget {
  const _ChartPanel({
    required this.stockId,
    required this.prices,
    required this.phase,
    required this.errorMessage,
    required this.onRetry,
  });

  final String stockId;
  final List<DailyPrice> prices;
  final LoadPhase phase;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  State<_ChartPanel> createState() => _ChartPanelState();
}

class _ChartPanelState extends State<_ChartPanel> {
  List<DailyPrice> _cachedPrices = const <DailyPrice>[];
  String? _cachedStockId;

  @override
  void initState() {
    super.initState();
    _cachedStockId = widget.stockId;
    _cachedPrices = widget.prices;
  }

  @override
  void didUpdateWidget(covariant _ChartPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_cachedStockId != widget.stockId) {
      _cachedStockId = widget.stockId;
      _cachedPrices = const <DailyPrice>[];
    }
    if (widget.prices.isNotEmpty) {
      _cachedPrices = widget.prices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prices = widget.prices;
    final displayPrices = prices.isNotEmpty ? prices : _cachedPrices;
    final isLoading =
        widget.phase == LoadPhase.loading ||
        widget.phase == LoadPhase.refreshing;
    final Widget content;
    final ValueKey<String> key;
    if (widget.errorMessage != null && prices.isEmpty) {
      key = const ValueKey('error');
      content = ErrorNotice(
        message: widget.errorMessage!,
        retry: widget.onRetry,
      );
    } else if (displayPrices.isNotEmpty) {
      key = const ValueKey('chart');
      content = AnimatedOpacity(
        opacity: isLoading ? .62 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: CandleChart(prices: displayPrices),
      );
    } else {
      key = ValueKey(isLoading ? 'loading' : 'empty');
      content = _EmptyChart(phase: widget.phase);
    }

    return SizedBox(
      height: 200,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        reverseDuration: const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.center,
          children: [...previousChildren, ?currentChild],
        ),
        child: KeyedSubtree(key: key, child: content),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.phase});

  final LoadPhase phase;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        phase == LoadPhase.loading ? '일별 시세를 불러오는 중입니다' : '표시할 일별 시세가 없습니다',
        style: TextStyle(fontSize: 12, color: context.colors.textDisabled),
      ),
    );
  }
}

class _QuoteSummary extends StatelessWidget {
  const _QuoteSummary({required this.quote});

  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(label: '시가', value: _numberOrDash(quote?.open)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(label: '고가', value: _numberOrDash(quote?.high)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(label: '저가', value: _numberOrDash(quote?.low)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: '거래량',
                value: quote == null ? '—' : compactVolume(quote!.volume),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(
                label: '시가총액',
                value: quote == null ? '—' : compactCap(quote!.marketCap),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _numberOrDash(int? value) =>
      value == null ? '—' : number(value);
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceSunken,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 11,
              height: 14 / 11,
            ),
          ),
          const SizedBox(height: 7),
          Text.rich(
            TextSpan(
              children: [
                if (label == '거래량' || label == '시가총액') ...[
                  TextSpan(
                    text: value.replaceAll(RegExp(r'[^0-9,.]'), ''),
                    style: const TextStyle(fontFamily: 'Inter'),
                  ),
                  TextSpan(text: value.replaceAll(RegExp(r'[0-9,.]'), '')),
                ] else
                  TextSpan(text: value),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 15,
              height: 20 / 15,
              letterSpacing: -.1,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyPrices extends StatelessWidget {
  const _DailyPrices({
    required this.prices,
    required this.hasMore,
    required this.loadingMore,
  });

  final List<DailyPrice> prices;
  final bool hasMore;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              '일별 시세',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 13,
                height: 18 / 13,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ),
        const _PriceRow(values: ['날짜', '종가', '등락', '거래량'], header: true),
        for (final price in prices)
          _PriceRow(
            values: [
              tradingDate(price.date),
              number(price.close),
              signedNumber(price.change),
              number(price.volume),
            ],
            change: price.change,
          ),
        if (hasMore || loadingMore) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Center(
              child: loadingMore
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.accentDefault,
                      ),
                    )
                  : Text(
                      '아래로 스크롤하면 더 표시됩니다',
                      style: TextStyle(
                        color: context.colors.textTertiary,
                        fontSize: 11,
                        height: 14 / 11,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.values, this.header = false, this.change = 0});

  final List<String> values;
  final bool header;
  final int change;

  @override
  Widget build(BuildContext context) {
    final baseColor = header
        ? context.colors.textSecondary
        : context.colors.textPrimary;

    return SizedBox(
      height: 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: _CellText(values[0], color: context.colors.textSecondary),
          ),
          SizedBox(
            width: 68,
            child: _CellText(
              values[1],
              color: baseColor,
              align: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 106,
            child: _CellText(
              values[2],
              color: header
                  ? context.colors.textSecondary
                  : changeColor(context, change),
              align: TextAlign.right,
            ),
          ),
          Expanded(
            child: _CellText(
              values[3],
              color: header
                  ? context.colors.textSecondary
                  : context.colors.textSecondary,
              align: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText(
    this.value, {
    required this.color,
    this.align = TextAlign.left,
  });

  final String value;
  final Color color;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 11, height: 14 / 11),
    );
  }
}
