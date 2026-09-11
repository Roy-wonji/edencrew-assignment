import 'package:get_it/get_it.dart';
import '../time/clock.dart';
import '../time/scheduler.dart';

abstract final class CoreAssembly {
  static void register(
    GetIt container, {
    AppClock clock = const SystemClock(),
    AppScheduler scheduler = const TimerScheduler(),
  }) {
    container.registerSingleton<AppClock>(clock);
    container.registerSingleton<AppScheduler>(scheduler);
  }
}
