import 'package:get_it/get_it.dart';
import '../reducer/search_reducer.dart';

abstract final class SearchAssembly {
  static void register(GetIt container) {
    container.registerSingleton<SearchReducer>(reduceSearch);
  }
}
