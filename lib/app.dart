import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/invoices/invoices_screen.dart';
import 'screens/quotes/quotes_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/sidebar.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'ControlGastos',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const MainLayoutWrapper(),
        );
      },
    );
  }
}

class MainLayoutWrapper extends StatefulWidget {
  const MainLayoutWrapper({super.key});

  @override
  State<MainLayoutWrapper> createState() => _MainLayoutWrapperState();
}

class _MainLayoutWrapperState extends State<MainLayoutWrapper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar el NotificationService con la referencia a ScaffoldMessenger
    NotificationService().setScaffoldMessenger(ScaffoldMessenger.of(context));
  }

  @override
  Widget build(BuildContext context) {
    return const MainLayout();
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),         // 0
    InvoicesScreen(),     // 1
    QuotesScreen(),       // 2
    InventoryScreen(),    // 3
    CustomersScreen(),    // 4
    ReportsScreen(),      // 5
    HistoryScreen(),      // 6
    SettingsScreen(),     // 7
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            isCollapsed: isSmallScreen,
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
