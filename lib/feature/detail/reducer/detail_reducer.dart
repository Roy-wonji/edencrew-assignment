import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/feature/detail/action/detail_action.dart';
import 'package:edencrew_assignment_starter/feature/detail/state/detail_state.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/load_phase.dart';

typedef DetailReducer =
    DetailState Function(DetailState state, DetailAction action);

DetailState reduceDetail(DetailState state, DetailAction action) {
  switch (action) {
    case DetailOpened(:final stock):
      return state.copyWith(
        stockId: stock.id,
        period: ChartPeriod.month1,
        phase: LoadPhase.loading,
        requestId: state.requestId + 1,
        prices: const <DailyPrice>[],
        clearErrorMessage: true,
      );
    case DetailClosed():
      return state.copyWith(
        phase: LoadPhase.idle,
        prices: const <DailyPrice>[],
        clearStock: true,
        clearErrorMessage: true,
      );
    case DetailPeriodSelected(:final period):
      if (state.stockId == null) {
        return state;
      }
      return state.copyWith(
        period: period,
        phase: LoadPhase.loading,
        requestId: state.requestId + 1,
        prices: const <DailyPrice>[],
        clearErrorMessage: true,
      );
    case DetailHistoryUpdated(
      :final requestId,
      :final stockId,
      :final period,
      :final prices,
      :final isComplete,
    ):
      if (!_isCurrentDetailResponse(state, requestId, stockId, period)) {
        return state;
      }
      return state.copyWith(
        phase: isComplete ? LoadPhase.loaded : LoadPhase.loading,
        prices: prices,
        clearErrorMessage: true,
      );
    case DetailHistoryFailed(
      :final requestId,
      :final stockId,
      :final period,
      :final message,
    ):
      if (!_isCurrentDetailResponse(state, requestId, stockId, period)) {
        return state;
      }
      return state.copyWith(phase: LoadPhase.failed, errorMessage: message);
  }
}

bool _isCurrentDetailResponse(
  DetailState state,
  int requestId,
  String stockId,
  ChartPeriod period,
) {
  return state.requestId == requestId &&
      state.stockId == stockId &&
      state.period == period;
}
