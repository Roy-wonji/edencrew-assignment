import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/feature/search/state/search_state.dart';
import 'package:edencrew_assignment_starter/feature/search/view/search_screen.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('검색바는 Figma 실측 높이와 외부 여백을 유지한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 393,
            height: 852,
            child: SearchScreen(
              state: const SearchState(),
              results: const <Stock>[],
              favoriteIds: const <String>{},
              onQuery: (_) {},
              onFavorite: (_) {},
              onOpen: (_) {},
            ),
          ),
        ),
      ),
    );

    final textFieldRect = tester.getRect(find.byType(TextField));
    expect(textFieldRect.left, 16);
    expect(textFieldRect.top, 8);
    expect(textFieldRect.width, 361);
    expect(textFieldRect.height, 40);

    final inputDecoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(inputDecoration.isDense, isTrue);
    expect(
      inputDecoration.contentPadding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  });
}
