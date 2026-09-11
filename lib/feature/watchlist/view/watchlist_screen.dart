import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:flutter/material.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:edencrew_assignment_starter/shared/formatting/stock_format.dart';
import 'package:edencrew_assignment_starter/shared/design_system/stock_icon.dart';
import 'package:edencrew_assignment_starter/shared/design_system/stock_widgets.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({
    super.key,
    required this.stocks,
    required this.quotes,
    required this.loadingSymbols,
    required this.sort,
    required this.onRefresh,
    required this.onSort,
    required this.onOpen,
    this.errorMessage,
  });
  final List<Stock> stocks;
  final Map<String, Quote> quotes;
  final Set<String> loadingSymbols;
  final WatchlistSort sort;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final ValueChanged<WatchlistSort> onSort;
  final ValueChanged<Stock> onOpen;

  void _showSort(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surfaceOverlay,
      barrierColor: Colors.black.withValues(alpha: .5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimens.radiusLg + context.dimens.space1),
        ),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final bottomPadding =
            mediaQuery.padding.bottom > mediaQuery.viewPadding.bottom
            ? mediaQuery.padding.bottom
            : mediaQuery.viewPadding.bottom;
        return SizedBox(
          key: const ValueKey('watchlist-sort-sheet'),
          height: 1 + 64 + (WatchlistSort.values.length * 56) + bottomPadding,
          child: Padding(
            padding: EdgeInsets.only(top: 1, bottom: bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  key: const ValueKey('watchlist-sort-title-row'),
                  height: 64,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.dimens.space6,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '정렬',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 19,
                          height: 22 / 19,
                          fontWeight: AppTypography.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                for (final sort in WatchlistSort.values)
                  InkWell(
                    onTap: () {
                      onSort(sort);
                      Navigator.of(sheetContext).pop();
                    },
                    child: SizedBox(
                      key: ValueKey('watchlist-sort-option-${sort.name}'),
                      height: 56,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dimens.space6,
                          vertical: context.dimens.space2 + 2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sort.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 20 / 15,
                                  fontWeight: AppTypography.medium,
                                  letterSpacing: -0.1,
                                  color: this.sort == sort
                                      ? context.colors.textPrimary
                                      : context.colors.textSecondary,
                                ),
                              ),
                            ),
                            if (this.sort == sort)
                              StockIcon(
                                StockIconType.check,
                                key: ValueKey(
                                  'watchlist-sort-selected-${sort.name}',
                                ),
                                size: 22,
                                color: context.colors.textPrimary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimens.space4,
            vertical: context.dimens.space3,
          ),
          child: SizedBox(
            height: 28,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '관심',
                    style: TextStyle(
                      fontSize: 19,
                      height: 22 / 19,
                      letterSpacing: -0.2,
                      fontWeight: AppTypography.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showSort(context),
                  borderRadius: BorderRadius.circular(context.dimens.radiusSm),
                  child: Row(
                    children: [
                      Text(
                        sort.label,
                        style: TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          fontWeight: AppTypography.bold,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      SizedBox(width: context.dimens.space2),
                      StockIcon(
                        StockIconType.sort,
                        size: context.dimens.iconSm,
                        color: context.colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.dimens.space4),
                SizedBox(
                  width: context.dimens.iconMd,
                  height: context.dimens.iconMd,
                  child: IconButton(
                    tooltip: '시세 새로고침',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tight(
                      Size.square(context.dimens.iconMd),
                    ),
                    icon: StockIcon(
                      StockIconType.refresh,
                      size: context.dimens.iconMd,
                      color: context.colors.textSecondary,
                    ),
                    onPressed: loadingSymbols.isEmpty ? onRefresh : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null && stocks.isNotEmpty)
          ErrorNotice(message: errorMessage!, retry: onRefresh),
        Expanded(
          child: stocks.isEmpty
              ? const EmptyContent(
                  icon: StockIconType.star,
                  title: '관심 종목이 없습니다',
                  message: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
                )
              : ListView.builder(
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    final stock = stocks[index];
                    final quote = quotes[stock.symbol];
                    return InkWell(
                      onTap: () => onOpen(stock),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 60),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dimens.space4,
                          vertical: context.dimens.space3,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: StockIdentity(stock: stock)),
                            SizedBox(width: context.dimens.space3),
                            if (quote != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    number(quote.current),
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 20 / 15,
                                      fontWeight: AppTypography.medium,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${signedNumber(quote.change)} (${percent(quote.changeRate)})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 14 / 11,
                                      color: changeColor(context, quote.change),
                                    ),
                                  ),
                                ],
                              )
                            else if (loadingSymbols.contains(stock.symbol))
                              const QuoteSkeleton()
                            else
                              Text(
                                '시세 없음',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textDisabled,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
