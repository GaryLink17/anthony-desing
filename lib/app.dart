import 'dart:ui' show AppExitResponse;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/invoices/invoices_screen.dart';
import 'screens/quotes/quotes_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/sidebar.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'core/backup_service.dart';
import 'app_routes.dart';
import 'utils/state_persistence.dart';

/// Widget raíz de la aplicación.
///
/// Configura el MaterialApp con tema claro/oscuro, escucha el ciclo de vida
/// para ejecutar backup automático al cerrar, y define el generador de rutas
/// que envuelve cada pantalla en el [MainLayout].
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runSyncBackupOnClose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  /// Intercepta el cierre de la aplicación para mostrar un modal de progreso
  /// mientras se realiza la copia de seguridad automática.
  @override
  Future<AppExitResponse> didRequestAppExit() async {
    final bs = BackupService.instance;
    if (!bs.cachedEnabled || bs.cachedFrequency != 'on_close') {
      return AppExitResponse.exit;
    }
    try {
      _showBackupProgress();
    } catch (_) {
      // la modal falla silenciosamente si no hay Navigator disponible
    }
    try {
      await bs.performAutoBackup();
    } catch (_) {}
    try {
      _navigatorKey.currentState?.pop();
    } catch (_) {}
    return AppExitResponse.exit;
  }

  /// Ejecuta backup sincrónico en dispose() como fallback por si
  /// didRequestAppExit no es invocado en la plataforma actual.
  void _runSyncBackupOnClose() {
    final bs = BackupService.instance;
    if (!bs.cachedEnabled || bs.cachedFrequency != 'on_close') return;
    bs.performAutoBackupSync();
  }

  void _showBackupProgress() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push<void>(
      PageRouteBuilder<void>(
        barrierDismissible: false,
        barrierColor: Colors.black54,
        opaque: false,
        pageBuilder: (context, _, _) => const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Text('Creando copia de seguridad...'),
            ],
          ),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Route<void> _buildNoAnimationRoute({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
      transitionDuration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Inventario & Facturación',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute:
              StatePersistence().getString(StorageKeys.lastRoute, defaultValue: AppRoutes.home),
          onGenerateRoute: (settings) {
            final routeName = settings.name ?? AppRoutes.home;
            final args = settings.arguments;
            final int? focusInventoryProductId =
                args is int ? args : null;
            if (!AppRoutes.all.contains(routeName)) {
              return _buildNoAnimationRoute(
                builder: (_) => const MainLayoutWrapper(initialRoute: AppRoutes.home),
                settings: const RouteSettings(name: AppRoutes.home),
              );
            }
            return _buildNoAnimationRoute(
              builder: (_) => MainLayoutWrapper(
                initialRoute: routeName,
                focusInventoryProductId: focusInventoryProductId,
              ),
              settings: RouteSettings(name: routeName, arguments: settings.arguments),
            );
          },
        );
      },
    );
  }
}

/// Envoltorio que inicializa el servicio de notificaciones y delega en [MainLayout].
class MainLayoutWrapper extends StatefulWidget {
  final String initialRoute;
  final int? focusInventoryProductId;

  const MainLayoutWrapper({
    super.key,
    required this.initialRoute,
    this.focusInventoryProductId,
  });

  @override
  State<MainLayoutWrapper> createState() => _MainLayoutWrapperState();
}

class _MainLayoutWrapperState extends State<MainLayoutWrapper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar el NotificationService con la referencia a ScaffoldMessenger
    NotificationService().setOverlayState(Overlay.of(context));
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      initialRoute: widget.initialRoute,
      focusInventoryProductId: widget.focusInventoryProductId,
    );
  }
}

/// Layout principal con sidebar persistente y área de contenido dinámico.
///
/// Mantiene la barra lateral fija a la izquierda y cambia la pantalla
/// según la ruta activa sin recargar el layout completo.
class MainLayout extends StatefulWidget {
  final String initialRoute;
  final int? focusInventoryProductId;

  const MainLayout({
    super.key,
    required this.initialRoute,
    this.focusInventoryProductId,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleRawKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleRawKey);
    super.dispose();
  }

  /// Retorna el widget de pantalla correspondiente al índice del menú.
  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const InvoicesScreen();
      case 2:
        return const QuotesScreen();
      case 3:
        return InventoryScreen(focusProductId: widget.focusInventoryProductId);
      case 4:
        return const ReportsScreen();
      case 5:
        return const HistoryScreen();
      case 6:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  void _navigateToIndex(int index, BuildContext context) {
    if (index < 0 || index >= AppRoutes.all.length) return;
    final targetRoute = AppRoutes.routeFromIndex(index);
    if (targetRoute == widget.initialRoute) return;
    StatePersistence().setString(StorageKeys.lastRoute, targetRoute);
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  bool _isTextInputFocused() {
    final node = FocusManager.instance.primaryFocus;
    if (node?.context == null) return false;
    return node!.context!.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _handleRawKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    if (_isTextInputFocused()) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.digit1:
      case LogicalKeyboardKey.numpad1:
        _navigateToIndex(0, context);
        return true;
      case LogicalKeyboardKey.digit2:
      case LogicalKeyboardKey.numpad2:
        _navigateToIndex(1, context);
        return true;
      case LogicalKeyboardKey.digit3:
      case LogicalKeyboardKey.numpad3:
        _navigateToIndex(2, context);
        return true;
      case LogicalKeyboardKey.digit4:
      case LogicalKeyboardKey.numpad4:
        _navigateToIndex(3, context);
        return true;
      case LogicalKeyboardKey.digit5:
      case LogicalKeyboardKey.numpad5:
        _navigateToIndex(4, context);
        return true;
      case LogicalKeyboardKey.digit6:
      case LogicalKeyboardKey.numpad6:
        _navigateToIndex(5, context);
        return true;
      case LogicalKeyboardKey.digit7:
      case LogicalKeyboardKey.numpad7:
        _navigateToIndex(6, context);
        return true;
      case LogicalKeyboardKey.numpadSubtract:
        _navigateToIndex(0, context);
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = AppRoutes.indexFromRoute(widget.initialRoute);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onItemSelected: (index) {
              _navigateToIndex(index, context);
            },
            isCollapsed: isSmallScreen,
          ),
          Expanded(child: _screenForIndex(selectedIndex)),
        ],
      ),
    );
  }
}
