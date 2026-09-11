import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/load_phase.dart';

final class DetailState {
  const DetailState({
    this.stockId,
    this.period = ChartPeriod.month1,
    this.phase = LoadPhase.idle,
    this.requestId = 0,
    this.prices = const <DailyPrice>[],
    this.errorMessage,
  });

  final String? stockId;
  final ChartPeriod period;
  final LoadPhase phase;
  final int requestId;
  final List<DailyPrice> prices;
  final String? errorMessage;

  bool get isOpen => stockId != null;

  DetailState copyWith({
    String? stockId,
    ChartPeriod? period,
    LoadPhase? phase,
    int? requestId,
    List<DailyPrice>? prices,
    String? errorMessage,
    bool clearStock = false,
    bool clearErrorMessage = false,
  }) {
    return DetailState(
      stockId: clearStock ? null : stockId ?? this.stockId,
      period: period ?? this.period,
      phase: phase ?? this.phase,
      requestId: requestId ?? this.requestId,
      prices: List<DailyPrice>.unmodifiable(prices ?? this.prices),
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
