import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'screens/invoices/invoices_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/sidebar.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ControlGastos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainLayout(),
    );
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
    HomeScreen(),
    InvoicesScreen(),
    InventoryScreen(),
    ReportsScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class AppTheme {
  // Colores principales
  static const primaryBlue = Color(0xFF1B3A6B);
  static const accentMagenta = Color(0xFFE8147A);
  static const accentOrange = Color(0xFFF5A623);
  static const bgColor = Color(0xFFF5F4F0);

  // Fondos claros para iconos de métricas
  static const lightBlue = Color(0xFFE6EEF8);
  static const lightMagenta = Color(0xFFFDE8F2);
  static const lightOrange = Color(0xFFFEF3E2);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: accentMagenta,
        tertiary: accentOrange,
        surface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.black.withOpacity(0.07), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentMagenta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        headerBackgroundColor: primaryBlue,
        headerForegroundColor: Colors.white,
        dayStyle: const TextStyle(fontSize: 13),
        yearStyle: const TextStyle(fontSize: 13),
        surfaceTintColor: Colors.transparent,
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(primaryBlue),
        ),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(primaryBlue),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C2C2A),
        ),
        bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF444441)),
        bodySmall: TextStyle(fontSize: 11, color: Color(0xFF888780)),
      ),
    );
  }
}
