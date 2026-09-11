import 'package:edencrew_assignment_starter/app/effect/app_effect.dart';
import 'package:edencrew_assignment_starter/app/effect/effect_runner.dart';
import 'package:edencrew_assignment_starter/app/reducer/app_reducer.dart';
import 'package:edencrew_assignment_starter/app/state/app_state.dart';
import 'package:edencrew_assignment_starter/core/state/app_action.dart';
import 'package:flutter/foundation.dart';

final class AppStore extends ChangeNotifier {
  AppStore({
    AppState initialState = const AppState(),
    AppReducer reducer = appReducer,
    required AppEffectRunner effectRunner,
  }) : _state = initialState,
       _reducer = reducer,
       _effectRunner = effectRunner;

  AppState _state;
  final AppReducer _reducer;
  final AppEffectRunner _effectRunner;
  bool _isDisposed = false;
  Future<void>? _disposal;

  AppState get state => _state;

  void dispatch(AppAction action) {
    if (_isDisposed) {
      return;
    }

    final result = _reducer(_state, action);
    if (!identical(result.state, _state)) {
      _state = result.state;
      notifyListeners();
    }
    for (final AppEffect effect in result.effects) {
      _effectRunner.run(effect, dispatch);
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _disposal = _effectRunner.dispose();
    super.dispose();
  }

  Future<void> close() {
    dispose();
    return _disposal!;
  }
}
