import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edencrew_assignment_starter/app/view/app.dart';
import 'package:edencrew_assignment_starter/app/bootstrap.dart';
import 'package:edencrew_assignment_starter/feature/detail/view/candle_chart.dart';
import 'support/immediate_stock_repository.dart';

void main() {
  testWidgets('검색 등록과 상세 해제가 관심 목록에 반영된다', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final composition = bootstrapApp(
      stockRepository: ImmediateStockRepository(),
    );
    addTearDown(composition.dispose);
    await tester.pumpWidget(EdencrewAssignmentApp(store: composition.store));
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('관심 등록'));
    await tester.pumpAndSettle();
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    await tester.tap(find.text('검색').last);
    await tester.tap(find.text('삼성전자'));
    await tester.pumpAndSettle();
    expect(find.byType(CandleChart), findsOneWidget);
    expect(find.text('일별 시세'), findsOneWidget);
    await tester.tap(find.text('3개월'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CandleChart>(find.byType(CandleChart)).prices.length,
      60,
    );
    await tester.tap(find.byTooltip('관심 해제'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('관심').last);
    await tester.pumpAndSettle();
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시스템 뒤로가기는 상세 화면만 닫고 홈을 유지한다', (tester) async {
    final composition = bootstrapApp(
      stockRepository: ImmediateStockRepository(),
    );
    addTearDown(composition.dispose);
    await tester.pumpWidget(EdencrewAssignmentApp(store: composition.store));

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pumpAndSettle();
    await tester.tap(find.text('삼성전자'));
    await tester.pumpAndSettle();
    expect(find.byType(CandleChart), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.byType(CandleChart), findsNothing);
    expect(find.text('검색'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('검색 결과 없음에서 지우면 초기 상태로 돌아간다', (tester) async {
    final composition = bootstrapApp(
      stockRepository: ImmediateStockRepository(),
    );
    addTearDown(composition.dispose);
    await tester.pumpWidget(EdencrewAssignmentApp(store: composition.store));
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '없음');
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다'), findsOneWidget);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
