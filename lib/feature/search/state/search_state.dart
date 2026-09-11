import 'package:edencrew_assignment_starter/feature/shared/state/load_phase.dart';

final class SearchState {
  const SearchState({
    this.query = '',
    this.phase = LoadPhase.idle,
    this.requestId = 0,
    this.resultIds = const <String>[],
    this.errorMessage,
  });

  final String query;
  final LoadPhase phase;
  final int requestId;
  final List<String> resultIds;
  final String? errorMessage;

  bool get hasQuery => query.trim().isNotEmpty;

  SearchState copyWith({
    String? query,
    LoadPhase? phase,
    int? requestId,
    List<String>? resultIds,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      phase: phase ?? this.phase,
      requestId: requestId ?? this.requestId,
      resultIds: List<String>.unmodifiable(resultIds ?? this.resultIds),
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
