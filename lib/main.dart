import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  final privider = AppProvider();
  await privider.loadCompanyData();

  runApp(ChangeNotifierProvider.value(value: privider, child: const MyApp()));
}
