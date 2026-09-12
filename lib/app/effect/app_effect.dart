import 'package:edencrew_assignment_starter/core/storage/app_preferences.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';

sealed class AppEffect {
  const AppEffect();
}

final class RefreshQuotesEffect extends AppEffect {
  const RefreshQuotesEffect({
    required this.requestIdsBySymbol,
    required this.symbols,
  });

  final Map<String, int> requestIdsBySymbol;
  final List<String> symbols;
}

final class LoadMetadataEffect extends AppEffect {
  const LoadMetadataEffect(this.symbol);

  final String symbol;
}

final class SearchStocksEffect extends AppEffect {
  const SearchStocksEffect({required this.requestId, required this.query});

  final int requestId;
  final String query;
}

final class CancelSearchEffect extends AppEffect {
  const CancelSearchEffect();
}

final class LoadPreferencesEffect extends AppEffect {
  const LoadPreferencesEffect();
}

final class SavePreferencesEffect extends AppEffect {
  const SavePreferencesEffect(this.snapshot);

  final AppPreferencesSnapshot snapshot;
}

final class LoadDetailHistoryEffect extends AppEffect {
  const LoadDetailHistoryEffect({
    required this.requestId,
    required this.stock,
    required this.period,
  });

  final int requestId;
  final Stock stock;
  final ChartPeriod period;
}

final class DismissNoticeEffect extends AppEffect {
  const DismissNoticeEffect(this.noticeId);

  final int noticeId;
}

final class CancelDetailHistoryEffect extends AppEffect {
  const CancelDetailHistoryEffect();
}
