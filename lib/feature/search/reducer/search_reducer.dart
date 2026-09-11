import 'package:edencrew_assignment_starter/feature/search/action/search_action.dart';
import 'package:edencrew_assignment_starter/feature/search/state/search_state.dart';
import 'package:edencrew_assignment_starter/feature/shared/state/load_phase.dart';

typedef SearchReducer =
    SearchState Function(SearchState state, SearchAction action);

SearchState reduceSearch(SearchState state, SearchAction action) {
  switch (action) {
    case SearchQueryChanged(:final query):
      final requestId = state.requestId + 1;
      if (query.trim().isEmpty) {
        return state.copyWith(
          query: query,
          phase: LoadPhase.idle,
          requestId: requestId,
          resultIds: const <String>[],
          clearErrorMessage: true,
        );
      }
      return state.copyWith(
        query: query,
        phase: LoadPhase.loading,
        requestId: requestId,
        clearErrorMessage: true,
      );
    case SearchSucceeded(:final requestId, :final query, :final results):
      if (!_isCurrentSearchResponse(state, requestId, query)) {
        return state;
      }
      return state.copyWith(
        phase: LoadPhase.loaded,
        resultIds: results.map((stock) => stock.id).toList(growable: false),
        clearErrorMessage: true,
      );
    case SearchFailed(:final requestId, :final query, :final message):
      if (!_isCurrentSearchResponse(state, requestId, query)) {
        return state;
      }
      return state.copyWith(
        phase: LoadPhase.failed,
        resultIds: const <String>[],
        errorMessage: message,
      );
  }
}

bool _isCurrentSearchResponse(SearchState state, int requestId, String query) {
  return state.requestId == requestId && state.query.trim() == query;
}
