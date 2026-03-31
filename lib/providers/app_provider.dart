import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database.dart';
import '../core/app_exception.dart';
import '../models/product.dart';

class AppProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  // Datos de la empresa
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

  double get monthlySales => _monthlySales;
  int get invoiceCount => _invoiceCount;
  int get totalProducts => _totalProducts;
  double get monthlyProfit => _monthlyProfit;
  List<Product> get lowStockProducts => _lowStockProducts;
  List<Map<String, dynamic>> get recentInvoices => _recentInvoices;
  List<double> get weeklySales => _weeklySales;

  // Carga los datos de la empresa desde SharedPreferences
  Future<void> loadCompanyData() async {
    final prefs = await SharedPreferences.getInstance();
    _companyName = prefs.getString('company_name') ?? 'Mi Negocio';
    _companyPhone = prefs.getString('company_phone') ?? '';
    _companyLogo = prefs.getString('company_logo');
    notifyListeners();
  }

  // Carga todos los datos del dashboard de una vez
  Future<void> loadDashboard() async {
    final db = await _db.database;
    try {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

    final salesResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) as total
      FROM invoices WHERE created_at >= ? AND status = 'active'
    ''',
      [monthStart],
    );
    _monthlySales = (salesResult.first['total'] as num).toDouble();

    final invoiceResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM invoices WHERE created_at >= ? AND status = 'active'
    ''',
      [monthStart],
    );
    _invoiceCount = (invoiceResult.first['count'] as num).toInt();

    final productResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products',
    );
    _totalProducts = (productResult.first['count'] as num).toInt();

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

    final lowStockResult = await db.query(
      'products',
      where: 'stock <= min_stock',
      orderBy: 'stock ASC',
      limit: 5,
    );
    _lowStockProducts = lowStockResult.map(Product.fromMap).toList();

    _recentInvoices = await db.query(
      'invoices',
      orderBy: 'created_at DESC',
      limit: 5,
    );

    _weeklySales = List.filled(7, 0);
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day).toIso8601String();
      final dayEnd = DateTime(
        day.year,
        day.month,
        day.day,
        23,
        59,
        59,
      ).toIso8601String();

      final dayResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(total), 0) as total
        FROM invoices WHERE created_at BETWEEN ? AND ? AND status = 'active'
      ''',
        [dayStart, dayEnd],
      );

      _weeklySales[6 - i] = (dayResult.first['total'] as num).toDouble();
    }

    notifyListeners();
    } catch (e) {
      throw AppException(
        'No se pudo cargar el dashboard.',
        technical: e.toString(),
      );
    }
  }

  Future<void> reloadAfterRestore() async {
    await loadCompanyData();
    await loadDashboard();
  }
}
