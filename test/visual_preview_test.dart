import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edencrew_assignment_starter/app/view/app.dart';
import 'package:edencrew_assignment_starter/app/bootstrap.dart';
import 'package:edencrew_assignment_starter/app/action/app_action.dart';
import 'package:edencrew_assignment_starter/core/storage/app_preferences.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/app_tab.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/favorite_change_source.dart';
import 'support/immediate_stock_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final family in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(family['family'] as String);
      for (final font
          in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });
  testWidgets('393×852에서 관심·검색·상세 화면에 렌더링 오류가 없다', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);
    final composition = bootstrapApp(
      stockRepository: ImmediateStockRepository(),
      preferences: MemoryAppPreferences(),
    );
    addTearDown(composition.dispose);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: EdencrewAssignmentApp(store: composition.store),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      if (Platform.environment['CAPTURE_UI'] != '1') return;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('.omx/visual/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('watchlist-empty');
    composition.store.dispatch(
      const FavoriteToggled(
        ImmediateStockRepository.samsung,
        source: FavoriteChangeSource.watchlist,
      ),
    );
    await tester.pumpAndSettle();
    await capture('watchlist');
    await tester.tap(find.text('현재가순').first);
    await tester.pumpAndSettle();
    await capture('watchlist-sort');
    await tester.tap(find.text('가나다순').last);
    await tester.pumpAndSettle();
    composition.store.dispatch(const AppTabSelected(AppTab.search));
    await tester.pumpAndSettle();
    await capture('search-empty');
    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pumpAndSettle();
    await capture('search');
    composition.store.dispatch(
      const FavoriteToggled(
        ImmediateStockRepository.samsung,
        source: FavoriteChangeSource.search,
      ),
    );
    await tester.pumpAndSettle();
    await capture('search-favorite-removed');
    composition.store.dispatch(
      const FavoriteToggled(
        ImmediateStockRepository.samsung,
        source: FavoriteChangeSource.search,
      ),
    );
    await tester.pumpAndSettle();
    await capture('search-favorite-added');
    await tester.pump(const Duration(seconds: 3));
    await tester.enterText(find.byType(TextField), '없음');
    await tester.pumpAndSettle();
    await capture('search-no-results');
    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pumpAndSettle();
    composition.store.dispatch(
      const DetailOpened(ImmediateStockRepository.samsung),
    );
    await tester.pumpAndSettle();
    await capture('detail');
  });
}
