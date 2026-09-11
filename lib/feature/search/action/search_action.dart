import 'package:edencrew_assignment_starter/core/state/app_action.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';

sealed class SearchAction implements AppAction {
  const SearchAction();
}

final class SearchQueryChanged extends SearchAction {
  const SearchQueryChanged(this.query);

  final String query;
}

final class SearchSucceeded extends SearchAction {
  const SearchSucceeded({
    required this.requestId,
    required this.query,
    required this.results,
  });

  final int requestId;
  final String query;
  final List<Stock> results;
}

final class SearchFailed extends SearchAction {
  const SearchFailed({
    required this.requestId,
    required this.query,
    required this.message,
  });

  final int requestId;
  final String query;
  final String message;
}
