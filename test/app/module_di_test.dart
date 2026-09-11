import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:edencrew_assignment_starter/app/bootstrap.dart';
import 'package:edencrew_assignment_starter/app/action/app_action.dart';
import 'package:edencrew_assignment_starter/app/store/app_store.dart';
import 'package:edencrew_assignment_starter/app/reducer/app_reducer.dart';
import 'package:edencrew_assignment_starter/app/effect/effect_runner.dart';
import 'package:edencrew_assignment_starter/core/time/scheduler.dart';
import 'package:edencrew_assignment_starter/feature/search/reducer/search_reducer.dart';
import 'package:edencrew_assignment_starter/feature/detail/reducer/detail_reducer.dart';
import 'package:edencrew_assignment_starter/core/di/core_assembly.dart';
import 'package:edencrew_assignment_starter/domain/domain_assembly.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/models.dart';
import 'package:edencrew_assignment_starter/feature/feature_assembly.dart';
import 'package:edencrew_assignment_starter/feature/watchlist/reducer/watchlist_reducer.dart';
import '../support/immediate_stock_repository.dart';

void main() {
  test(
    'separate app containers isolate stores and repository cleanup',
    () async {
      final firstRepo = _Repository();
      final secondRepo = _Repository();
      final first = bootstrapApp(stockRepository: firstRepo);
      final second = bootstrapApp(stockRepository: secondRepo);
      first.store.dispatch(const WatchlistSortSelected(WatchlistSort.name));
      expect(second.store.state.watchlistSort, WatchlistSort.currentPrice);
      expect(GetIt.instance.isRegistered<AppStore>(), isFalse);
      await first.dispose();
      expect(firstRepo.closeCount, 1);
      expect(secondRepo.closeCount, 0);
      second.store.dispatch(
        const WatchlistSortSelected(WatchlistSort.changeRate),
      );
      expect(second.store.state.watchlistSort, WatchlistSort.changeRate);
      await second.dispose();
      expect(secondRepo.closeCount, 1);
    },
  );

  test('composition awaits repository close exactly once', () async {
    final gate = Completer<void>();
    final repo = _Repository(closeGate: gate);
    final app = bootstrapApp(stockRepository: repo);
    var finished = false;
    final closing = app.dispose().then((_) => finished = true);
    final duplicate = app.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    expect(repo.closeCount, 1);
    app.store.dispatch(const WatchlistSortSelected(WatchlistSort.name));
    expect(app.store.state.watchlistSort, WatchlistSort.currentPrice);
    gate.complete();
    await Future.wait([closing, duplicate]);
    expect(finished, isTrue);
    expect(repo.closeCount, 1);
  });

  test('Feature registrations supply constructor-injected reducers', () async {
    final container = GetIt.asNewInstance();
    final repo = _Repository();
    CoreAssembly.register(container);
    DomainAssembly.register(container, stockRepository: repo);
    FeatureAssembly.register(container);
    await container.unregister<WatchlistReducer>();
    var calls = 0;
    container.registerSingleton<WatchlistReducer>((state, action) {
      calls++;
      return WatchlistSort.name;
    });
    final store = AppStore(
      effectRunner: AppEffectRunner(
        repository: repo,
        scheduler: container<AppScheduler>(),
      ),
      reducer: ComposedAppReducer(
        search: container<SearchReducer>(),
        detail: container<DetailReducer>(),
        watchlist: container<WatchlistReducer>(),
      ).call,
    );
    store.dispatch(const WatchlistSortSelected(WatchlistSort.changeRate));
    expect(calls, 1);
    expect(store.state.watchlistSort, WatchlistSort.name);
    await store.close();
    await container.reset(dispose: false);
  });
}

class _Repository extends ImmediateStockRepository {
  _Repository({this.closeGate});
  final Completer<void>? closeGate;
  int closeCount = 0;
  @override
  Future<void> close() async {
    closeCount++;
    await closeGate?.future;
  }
}
