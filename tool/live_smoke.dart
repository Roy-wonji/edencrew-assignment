import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:edencrew_assignment_starter/core/di/core_assembly.dart';
import 'package:edencrew_assignment_starter/domain/stock/interface/stock_repository.dart';
import 'package:edencrew_assignment_starter/domain/domain_assembly.dart';
import 'package:edencrew_assignment_starter/domain/stock/entity/chart_period.dart';
import 'package:edencrew_assignment_starter/service/service_assembly.dart';

Future<void> main() async {
  final container = GetIt.asNewInstance();
  CoreAssembly.register(container);
  ServiceAssembly.register(container);
  DomainAssembly.register(container);
  final repository = container<StockRepository>();
  try {
    final stocks = await repository.search('삼성전자');
    final stock = await repository.metadata('005930');
    final quotes = await repository.quotes(['005930']);
    final historyCounts = <int>[];
    for (final period in ChartPeriod.values) {
      final history = await repository.history('005930', period).last;
      if (history.length != period.days) {
        throw StateError('${period.name}: ${history.length}/${period.days}');
      }
      historyCounts.add(history.length);
    }
    if (!stocks.any((s) => s.symbol == '005930') ||
        stock.symbol != '005930' ||
        quotes['005930'] == null) {
      throw StateError('Naver smoke check failed');
    }
    stdout.writeln(
      'PASS search=${stocks.length}, metadata=${stock.symbol}, quotes=${quotes.length}, history=$historyCounts',
    );
  } finally {
    await repository.close();
    await container.reset(dispose: false);
  }
}
