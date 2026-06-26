import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'core/database.dart';
import 'core/backup_service.dart';
import 'utils/state_persistence.dart';

/// Punto de entrada de la aplicación.
///
/// Inicializa la base de datos, la persistencia de estado, los providers
/// globales y lanza la interfaz con el tema y datos de la empresa cargados.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exception}');
    debugPrint('[FlutterError] Stack: ${details.stack}');
    if (kReleaseMode) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error/n$stack');
    return true;
  };

  await initializeDateFormatting('es', null);
  await DatabaseHelper.initialize();
  await StatePersistence().initialize();

  final appProvider = AppProvider();
  await appProvider.loadCompanyData();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Inicializar caché de backup para uso sincrónico al cerrar la app
  await BackupService.instance.initAutoBackupCache();
  _scheduleStartupBackup();

  ErrorWidget.builder = (details) {
    return const Center(
      child: Text(
        'Algo salio mal. Reinicia la aplicacion.',
        style: TextStyle(color: Colors.grey),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

/// Ejecuta un backup automático al inicio si la frecuencia programada lo requiere.
/// No bloquea el arranque de la aplicación (fire-and-forget).
void _scheduleStartupBackup() {
  Future(() async {
    try {
      final settings = await BackupService.instance.getAutoBackupSettings();
      if (settings['enabled'] != true) return;
      if (settings['frequency'] == 'on_close') return;

      final shouldRun = await BackupService.instance.shouldRunBackup(
        enabled: settings['enabled'] as bool,
        frequency: settings['frequency'] as String,
        lastTime: settings['lastTime'] as String?,
      );

      if (shouldRun) {
        await BackupService.instance.performAutoBackup();
      }
    } catch (_) {
      // No impedir el inicio de la app por un error de backup
    }
  });
}
