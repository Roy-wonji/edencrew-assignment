import 'package:get_it/get_it.dart';
import '../reducer/detail_reducer.dart';

abstract final class DetailAssembly {
  static void register(GetIt container) {
    container.registerSingleton<DetailReducer>(reduceDetail);
  }
}
