import 'dart:async';

abstract interface class CancelableTask {
  void cancel();
}

abstract interface class AppScheduler {
  CancelableTask schedule(Duration delay, void Function() callback);

  void dispose();
}

final class TimerCancelableTask implements CancelableTask {
  TimerCancelableTask(this._timer);

  final Timer _timer;

  @override
  void cancel() {
    _timer.cancel();
  }
}

final class TimerScheduler implements AppScheduler {
  const TimerScheduler();

  @override
  CancelableTask schedule(Duration delay, void Function() callback) {
    return TimerCancelableTask(Timer(delay, callback));
  }

  @override
  void dispose() {}
}
