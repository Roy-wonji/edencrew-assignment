import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/feature/watchlist/view/watchlist_screen.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('정렬 시트는 Figma 실측 높이와 행 배치를 유지한다', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: WatchlistScreen(
            stocks: const <Stock>[_samsung],
            quotes: const <String, Quote>{'005930': _quote},
            loadingSymbols: const <String>{},
            sort: WatchlistSort.currentPrice,
            onRefresh: () {},
            onSort: (_) {},
            onOpen: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('현재가순').first);
    await tester.pumpAndSettle();

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('watchlist-sort-sheet')),
    );
    expect(sheetRect.width, 393);
    expect(sheetRect.height, 267);
    expect(sheetRect.top, 585);

    final titleRowRect = tester.getRect(
      find.byKey(const ValueKey('watchlist-sort-title-row')),
    );
    expect(titleRowRect.left, 0);
    expect(titleRowRect.top, 586);
    expect(titleRowRect.height, 64);

    final firstOptionRect = tester.getRect(
      find.byKey(const ValueKey('watchlist-sort-option-currentPrice')),
    );
    expect(firstOptionRect.top, 650);
    expect(firstOptionRect.height, 56);

    final selectedIconRect = tester.getRect(
      find.byKey(const ValueKey('watchlist-sort-selected-currentPrice')),
    );
    final selectedTextRect = tester.getRect(find.text('현재가순').last);
    final selectedText = tester.widget<Text>(find.text('현재가순').last);
    final unselectedText = tester.widget<Text>(find.text('등락률순'));
    final modalBarrier = tester.widget<ModalBarrier>(
      find.byType(ModalBarrier).last,
    );

    expect(selectedTextRect.left, 24);
    expect(selectedIconRect.left, 347);
    expect(selectedIconRect.width, 22);
    expect(selectedText.style?.color, const AppColors.dark().textPrimary);
    expect(unselectedText.style?.color, const AppColors.dark().textSecondary);
    expect(modalBarrier.color, Colors.black.withValues(alpha: .5));
  });
}

const _samsung = Stock(symbol: '005930', name: '삼성전자', market: 'KOSPI');

const _quote = Quote(
  symbol: '005930',
  current: 70000,
  previousClose: 69000,
  open: 69500,
  high: 70500,
  low: 68800,
  volume: 1000000,
);
