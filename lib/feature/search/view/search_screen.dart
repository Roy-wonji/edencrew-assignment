import 'package:edencrew_assignment_starter/shared/design_system/stock_icon.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import '../state/search_state.dart';
import '../../shared/state/load_phase.dart';
import 'package:flutter/material.dart';
import 'package:edencrew_assignment_starter/shared/design_system/stock_widgets.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.state,
    required this.results,
    required this.favoriteIds,
    required this.onQuery,
    required this.onFavorite,
    required this.onOpen,
  });
  final SearchState state;
  final List<Stock> results;
  final Set<String> favoriteIds;
  final ValueChanged<String> onQuery;
  final ValueChanged<Stock> onFavorite;
  final ValueChanged<Stock> onOpen;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.query,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = widget.state;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.dimens.space4,
            context.dimens.space2,
            context.dimens.space4,
            context.dimens.space3,
          ),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _controller,
              style: TextStyle(
                fontSize: 15,
                height: 20 / 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                color: context.colors.textPrimary,
              ),
              textInputAction: TextInputAction.search,
              onChanged: widget.onQuery,
              decoration: InputDecoration(
                hintText: '종목명 또는 종목코드',
                hintStyle: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: 15,
                  height: 20 / 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
                filled: true,
                fillColor: context.colors.surfaceSunken,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.dimens.space3,
                  vertical: context.dimens.space2 + 2,
                ),
                isDense: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    left: context.dimens.space3,
                    right: context.dimens.space2,
                  ),
                  child: StockIcon(
                    StockIconType.search,
                    color: context.colors.textTertiary,
                    size: context.dimens.iconSm,
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth:
                      context.dimens.space3 +
                      context.dimens.iconSm +
                      context.dimens.space2,
                  minHeight: context.dimens.iconSm,
                ),
                suffixIcon: IconButton(
                  tooltip: '검색어 지우기',
                  icon: StockIcon(
                    StockIconType.close,
                    size: context.dimens.iconSm,
                    color: context.colors.textTertiary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _controller.clear();
                    widget.onQuery('');
                  },
                ),
                suffixIconConstraints: BoxConstraints(
                  minWidth:
                      context.dimens.space2 +
                      context.dimens.iconSm +
                      context.dimens.space3,
                  minHeight: context.dimens.iconSm,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.dimens.radiusMd),
                  borderSide: BorderSide(color: context.colors.borderStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.dimens.radiusMd),
                  borderSide: BorderSide(color: context.colors.borderStrong),
                ),
              ),
            ),
          ),
        ),
        if (search.phase == LoadPhase.loading ||
            search.phase == LoadPhase.refreshing)
          LinearProgressIndicator(
            minHeight: 2,
            color: context.colors.accentDefault,
            backgroundColor: context.colors.surfaceRaised,
          ),
        if (search.errorMessage != null)
          ErrorNotice(
            message: search.errorMessage!,
            retry: () => widget.onQuery(search.query),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            reverseDuration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                ?currentChild,
              ],
            ),
            child: _SearchResultsContent(
              key: ValueKey(
                '${search.hasQuery}_${search.phase}_${widget.results.length}',
              ),
              search: search,
              results: widget.results,
              favoriteIds: widget.favoriteIds,
              onFavorite: widget.onFavorite,
              onOpen: widget.onOpen,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultsContent extends StatelessWidget {
  const _SearchResultsContent({
    super.key,
    required this.search,
    required this.results,
    required this.favoriteIds,
    required this.onFavorite,
    required this.onOpen,
  });

  final SearchState search;
  final List<Stock> results;
  final Set<String> favoriteIds;
  final ValueChanged<Stock> onFavorite;
  final ValueChanged<Stock> onOpen;

  @override
  Widget build(BuildContext context) {
    if (!search.hasQuery) {
      return const EmptyContent(
        icon: StockIconType.search,
        title: '종목을 검색해 보세요',
        message: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }
    if (search.phase == LoadPhase.loading ||
        search.phase == LoadPhase.refreshing) {
      return const _SearchResultSkeletonList();
    }
    if (search.phase == LoadPhase.loaded && results.isEmpty) {
      return EmptyContent(
        icon: StockIconType.searchOff,
        title: '검색 결과가 없습니다',
        message: "‘${search.query}'와\n일치하는 검색 결과를 찾지 못했습니다.",
      );
    }
    if (search.phase == LoadPhase.failed && results.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      key: const PageStorageKey('search-results'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final stock = results[index];
        return InkWell(
          onTap: () {
            FocusScope.of(context).unfocus();
            onOpen(stock);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: EdgeInsets.only(
              left: context.dimens.space4,
              right: context.dimens.space1 + context.dimens.borderHairline,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.dimens.space3,
                    ),
                    child: StockIdentity(stock: stock, query: search.query),
                  ),
                ),
                FavoriteButton(
                  selected: favoriteIds.contains(stock.id),
                  onPressed: () => onFavorite(stock),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchResultSkeletonList extends StatelessWidget {
  const _SearchResultSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('search-result-skeleton'),
      itemCount: 6,
      itemBuilder: (context, index) => const _SearchResultSkeletonRow(),
    );
  }
}

class _SearchResultSkeletonRow extends StatelessWidget {
  const _SearchResultSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '검색 결과 불러오는 중',
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: EdgeInsets.symmetric(
          horizontal: context.dimens.space4,
          vertical: context.dimens.space3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBar(width: 112, height: 14),
                  SizedBox(height: context.dimens.space1),
                  _SkeletonBar(width: 64, height: 11),
                ],
              ),
            ),
            _SkeletonBar(width: 22, height: 22, radius: 11),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.colors.feedbackSkeleton,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
