import 'package:edencrew_assignment_starter/app/effect/effect_runner.dart';
import 'package:edencrew_assignment_starter/app/store/app_store.dart';
import 'package:edencrew_assignment_starter/core/network/stock_http_client.dart';
import 'package:edencrew_assignment_starter/core/storage/app_preferences.dart';
import 'package:edencrew_assignment_starter/core/time/clock.dart';
import 'package:edencrew_assignment_starter/core/time/scheduler.dart';
import 'package:edencrew_assignment_starter/domain/domain_assembly.dart';
import 'package:edencrew_assignment_starter/domain/stock/interface/stock_repository.dart';
import 'package:edencrew_assignment_starter/feature/shared/action/shared_action.dart';
import 'package:edencrew_assignment_starter/service/service_assembly.dart';

import 'package:get_it/get_it.dart';
import '../core/di/core_assembly.dart';
import '../feature/feature_assembly.dart';
import '../feature/search/reducer/search_reducer.dart';
import '../feature/detail/reducer/detail_reducer.dart';
import '../feature/watchlist/reducer/watchlist_reducer.dart';
import 'reducer/app_reducer.dart';

final class AppComposition {
  AppComposition._({
    required this.store,
    required this.clock,
    required GetIt container,
  }) : _container = container;

  final AppStore store;
  final AppClock clock;
  final GetIt _container;
  Future<void>? _disposal;

  Future<void> dispose() => _disposal ??= _close();

  Future<void> _close() async {
    try {
      await store.close();
    } finally {
      // Store owns effects, scheduler and repository/client cleanup.
      await _container.reset(dispose: false);
    }
  }
}

/// Registers modules and builds the single app-owned store.
AppComposition bootstrapApp({
  StockRepository? stockRepository,
  StockHttpClient? httpClient,
  AppClock clock = const SystemClock(),
  AppScheduler scheduler = const TimerScheduler(),
  AppPreferences preferences = const SharedPreferencesAppPreferences(),
}) {
  final container = GetIt.asNewInstance();
  CoreAssembly.register(container, clock: clock, scheduler: scheduler);
  if (stockRepository == null) {
    ServiceAssembly.register(container, httpClient: httpClient);
  }
  DomainAssembly.register(container, stockRepository: stockRepository);
  FeatureAssembly.register(container);

  final store = AppStore(
    effectRunner: AppEffectRunner(
      repository: container<StockRepository>(),
      scheduler: container<AppScheduler>(),
      preferences: preferences,
    ),
    reducer: ComposedAppReducer(
      search: container<SearchReducer>(),
      detail: container<DetailReducer>(),
      watchlist: container<WatchlistReducer>(),
    ).call,
  );
  store.dispatch(const AppStarted());
  return AppComposition._(
    store: store,
    clock: container<AppClock>(),
    container: container,
  );
}
