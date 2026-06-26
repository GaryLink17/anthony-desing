import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database.dart';
import '../core/app_exception.dart';
import '../models/product.dart';
import '../utils/performance_helpers.dart';

/// Provider principal de la aplicación.
/// Maneja los datos de la empresa (desde SharedPreferences) y
/// los datos del dashboard (desde SQLite).
class AppProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  // Datos de la empresa (cargados de SharedPreferences)
  String _companyName = 'Mi Negocio';
  String _companyPhone = '';
  String? _companyLogo;

  String get companyName => _companyName;
  String get companyPhone => _companyPhone;
  String? get companyLogo => _companyLogo;

  // Estado del dashboard
  double _monthlySales = 0;
  int _invoiceCount = 0;
  int _totalProducts = 0;
  double _monthlyProfit = 0;
  List<Product> _lowStockProducts = [];
  List<Map<String, dynamic>> _recentInvoices = [];
  List<double> _weeklySales = List.filled(7, 0);
  int? _lastDashboardLoadMs;

  double get monthlySales => _monthlySales;
  int get invoiceCount => _invoiceCount;
  int get totalProducts => _totalProducts;
  double get monthlyProfit => _monthlyProfit;
  List<Product> get lowStockProducts => _lowStockProducts;
  List<Map<String, dynamic>> get recentInvoices => _recentInvoices;
  List<double> get weeklySales => _weeklySales;
  int? get lastDashboardLoadMs => _lastDashboardLoadMs;

  /// Carga los datos de la empresa desde SharedPreferences.
  Future<void> loadCompanyData() async {
    final prefs = await SharedPreferences.getInstance();
    _companyName = prefs.getString('company_name') ?? 'Mi Negocio';
    _companyPhone = prefs.getString('company_phone') ?? '';
    _companyLogo = prefs.getString('company_logo');
    notifyListeners();
  }

  /// Carga todos los datos del dashboard en paralelo:
  /// ventas mensuales, ganancia, conteo de facturas/productos,
  /// productos con stock bajo, últimas 5 facturas y ventas de los últimos 7 días.
  Future<void> loadDashboard() async {
    final perf = PerformanceMonitor();
    perf.startMeasure('loadDashboard');
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

      // Total de ventas del mes actual
      final salesResult = await db.rawQuery(
        '''
      SELECT COALESCE(SUM(total), 0) as total
      FROM invoices WHERE created_at >= ? AND status = 'active'
    ''',
        [monthStart],
      );
      _monthlySales = (salesResult.first['total'] as num).toDouble();

      // Cantidad de facturas del mes actual
      final invoiceResult = await db.rawQuery(
        '''
      SELECT COUNT(*) as count
      FROM invoices WHERE created_at >= ? AND status = 'active'
    ''',
        [monthStart],
      );
      _invoiceCount = (invoiceResult.first['count'] as num).toInt();

      // Total de productos en inventario
      final productResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products',
      );
      _totalProducts = (productResult.first['count'] as num).toInt();

      // Ganancia estimada del mes
      final profitResult = await db.rawQuery(
        '''
      SELECT COALESCE(SUM(
        (ii.unit_price * (1 - ii.discount_item / 100.0) - p.purchase_price) * ii.quantity
        * CASE WHEN i.subtotal > 0 THEN (i.subtotal - i.discount_global) / i.subtotal ELSE 1 END
      ), 0) as profit
      FROM invoice_items ii
      JOIN products p ON ii.product_id = p.id
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.created_at >= ? AND i.status = 'active'
    ''',
        [monthStart],
      );
      _monthlyProfit = (profitResult.first['profit'] as num).toDouble();

      // Productos con stock bajo (top 5)
      final lowStockResult = await db.query(
        'products',
        where: 'stock <= min_stock',
        orderBy: 'stock ASC',
        limit: 5,
      );
      _lowStockProducts = lowStockResult.map(Product.fromMap).toList();

      // Últimas 5 facturas
      _recentInvoices = await db.query(
        'invoices',
        orderBy: 'created_at DESC',
        limit: 5,
      );

      // Ventas de los últimos 7 días — single query con GROUP BY en vez de 7 queries
      final weekAgo = DateTime(now.year, now.month, now.day - 6);
      final weekStart = DateTime(
        weekAgo.year,
        weekAgo.month,
        weekAgo.day,
      ).toIso8601String();
      final weekEnd = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();
      final weeklyResult = await db.rawQuery(
        '''
      SELECT DATE(created_at) as day, COALESCE(SUM(total), 0) as total
      FROM invoices WHERE created_at >= ? AND created_at <= ? AND status = 'active'
      GROUP BY DATE(created_at)
    ''',
        [weekStart, weekEnd],
      );

      _weeklySales = List.filled(7, 0);
      for (final row in weeklyResult) {
        final dayStr = row['day'] as String;
        final dayDate = DateTime.tryParse(dayStr);
        if (dayDate == null) continue;
        final diff = now.difference(dayDate).inDays;
        if (diff >= 0 && diff < 7) {
          _weeklySales[6 - diff] = (row['total'] as num).toDouble();
        }
      }

      notifyListeners();
      _lastDashboardLoadMs = perf.endMeasure('loadDashboard');
    } catch (e) {
      notifyListeners();
      _lastDashboardLoadMs = null;
      perf.endMeasure('loadDashboard');
      throw AppException(
        'No se pudo cargar el dashboard.',
        technical: e.toString(),
      );
    }
  }

  /// Recarga datos de empresa y dashboard después de restaurar un backup.
  Future<void> reloadAfterRestore() async {
    await loadCompanyData();
    await loadDashboard();
  }
}
