import 'package:flutter/material.dart';
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
import 'app_routes.dart';
import 'utils/state_persistence.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  PageRouteBuilder<void> _buildNoAnimationRoute({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
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
              final targetRoute = AppRoutes.routeFromIndex(index);
              if (targetRoute == widget.initialRoute) return;
              StatePersistence().setString(StorageKeys.lastRoute, targetRoute);
              Navigator.of(context).pushReplacementNamed(targetRoute);
            },
            isCollapsed: isSmallScreen,
          ),
          Expanded(child: _screenForIndex(selectedIndex)),
        ],
      ),
    );
  }
}
