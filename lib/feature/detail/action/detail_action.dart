import 'package:edencrew_assignment_starter/core/state/app_action.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';

sealed class DetailAction implements AppAction {
  const DetailAction();
}

final class DetailOpened extends DetailAction {
  const DetailOpened(this.stock);

  final Stock stock;
}

final class DetailClosed extends DetailAction {
  const DetailClosed();
}

final class DetailPeriodSelected extends DetailAction {
  const DetailPeriodSelected(this.period);

  final ChartPeriod period;
}

final class DetailDailyPricesMoreRequested extends DetailAction {
  const DetailDailyPricesMoreRequested();
}

final class DetailHistoryUpdated extends DetailAction {
  const DetailHistoryUpdated({
    required this.requestId,
    required this.stockId,
    required this.period,
    required this.prices,
    required this.isComplete,
  });

  final int requestId;
  final String stockId;
  final ChartPeriod period;
  final List<DailyPrice> prices;
  final bool isComplete;
}

final class DetailHistoryFailed extends DetailAction {
  const DetailHistoryFailed({
    required this.requestId,
    required this.stockId,
    required this.period,
    required this.message,
  });

  final int requestId;
  final String stockId;
  final ChartPeriod period;
  final String message;
}
