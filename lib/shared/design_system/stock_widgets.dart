import 'stock_icon.dart';
import 'package:flutter/material.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import '../../theme/theme.dart';

Color changeColor(BuildContext context, int change) => change > 0
    ? context.colors.priceUpText
    : change < 0
    ? context.colors.priceDownText
    : context.colors.priceFlatText;

class StockIdentity extends StatelessWidget {
  const StockIdentity({super.key, required this.stock, this.query = ''});
  final Stock stock;
  final String query;

  @override
  Widget build(BuildContext context) {
    final name = stock.name;
    final spans = <TextSpan>[];
    var cursor = 0;
    final needle = query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      final lower = name.toLowerCase();
      var index = lower.indexOf(needle);
      while (index >= 0) {
        spans.add(TextSpan(text: name.substring(cursor, index)));
        spans.add(
          TextSpan(
            text: name.substring(index, index + needle.length),
            style: TextStyle(color: context.colors.searchHighlight),
          ),
        );
        cursor = index + needle.length;
        index = lower.indexOf(needle, cursor);
      }
    }
    spans.add(TextSpan(text: name.substring(cursor)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(children: spans),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            height: 20 / 15,
            letterSpacing: -.1,
            fontWeight: AppTypography.medium,
            color: context.colors.textPrimary,
          ),
        ),
        SizedBox(height: context.dimens.space1 / 2),
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
            fontSize: 11,
            height: 14 / 11,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.selected,
    required this.onPressed,
  });
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: selected ? '관심 해제' : '관심 등록',
    isSelected: selected,
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    icon: StockIcon(
      selected ? StockIconType.starFilled : StockIconType.star,
      size: 22,
      color: selected
          ? context.colors.favoriteActive
          : context.colors.favoriteInactive,
    ),
  );
}

class EmptyContent extends StatelessWidget {
  const EmptyContent({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final StockIconType icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(context.dimens.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StockIcon(icon, size: 40, color: context.colors.textTertiary),
          SizedBox(height: context.dimens.space3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              height: 22 / 19,
              letterSpacing: -0.2,
              fontWeight: AppTypography.bold,
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: context.dimens.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: AppTypography.regular,
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.dimens.space4,
      vertical: context.dimens.space2,
    ),
    child: Row(
      children: [
        Icon(
          Icons.error_outline,
          color: context.colors.feedbackWarning,
          size: context.dimens.iconMd,
        ),
        SizedBox(width: context.dimens.space2),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ),
        TextButton(onPressed: retry, child: const Text('재시도')),
      ],
    ),
  );
}

class QuoteSkeleton extends StatelessWidget {
  const QuoteSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: '시세 불러오는 중',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final width in [64.0, 48.0])
          Padding(
            padding: EdgeInsets.only(bottom: context.dimens.space1),
            child: Container(
              width: width,
              height: 12,
              decoration: BoxDecoration(
                color: context.colors.feedbackSkeleton,
                borderRadius: BorderRadius.circular(context.dimens.radiusSm),
              ),
            ),
          ),
      ],
    ),
  );
}
