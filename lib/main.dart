import 'package:flutter/material.dart';
import 'app/view/app.dart';
import 'app/bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _LiveApp());
}

class _LiveApp extends StatefulWidget {
  const _LiveApp();
  @override
  State<_LiveApp> createState() => _LiveAppState();
}

class _LiveAppState extends State<_LiveApp> {
  late final AppComposition composition = bootstrapApp();
  @override
  void dispose() {
    composition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      EdencrewAssignmentApp(store: composition.store);
}
