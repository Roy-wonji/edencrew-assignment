import 'package:edencrew_assignment_starter/core/state/app_action.dart';
import 'package:edencrew_assignment_starter/core/storage/app_preferences.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/app_tab.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/favorite_change_source.dart';

final class AppStarted implements AppAction {
  const AppStarted();
}

final class PreferencesLoaded implements AppAction {
  const PreferencesLoaded(this.snapshot);

  final AppPreferencesSnapshot snapshot;
}

final class AppTabSelected implements AppAction {
  const AppTabSelected(this.tab);

  final AppTab tab;
}

final class FavoriteToggled implements AppAction {
  const FavoriteToggled(this.stock, {required this.source});

  final Stock stock;
  final FavoriteChangeSource source;
}

final class QuotesSucceeded implements AppAction {
  const QuotesSucceeded({
    required this.requestIdsBySymbol,
    required this.symbols,
    required this.quotes,
  });

  final Map<String, int> requestIdsBySymbol;
  final List<String> symbols;
  final Map<String, Quote> quotes;
}

final class QuotesFailed implements AppAction {
  const QuotesFailed({
    required this.requestIdsBySymbol,
    required this.symbols,
    required this.message,
  });

  final Map<String, int> requestIdsBySymbol;
  final List<String> symbols;
  final String message;
}

final class MetadataSucceeded implements AppAction {
  const MetadataSucceeded(this.stock);

  final Stock stock;
}

final class MetadataFailed implements AppAction {
  const MetadataFailed({required this.symbol, required this.message});

  final String symbol;
  final String message;
}

final class NoticeExpired implements AppAction {
  const NoticeExpired(this.noticeId);

  final int noticeId;
}
