import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_helper.dart';
import '../../core/app_exception.dart';
import '../../services/notification_service.dart';
import '../../models/product.dart';
import '../../app_routes.dart';
import '../../utils/state_persistence.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Evita repetir la notificación al volver al Dashboard en la misma sesión.
  static bool _lowStockWarningShownThisSession = false;

  final _currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final provider = context.read<AppProvider>();
        await provider.loadDashboard();
        _notifyLowStock(provider);
      } on AppException catch (e) {
        NotificationService().error(e.message);
      }
    });
  }

  void _notifyLowStock(AppProvider provider) {
    if (_lowStockWarningShownThisSession) return;
    final lowStock = provider.lowStockProducts;
    if (lowStock.isEmpty) return;
    _lowStockWarningShownThisSession = true;
    final names = lowStock.map((p) => p.name).take(3).join(', ');
    final extra = lowStock.length > 3 ? ' y ${lowStock.length - 3} más' : '';
    NotificationService().warning(
      'Stock bajo: $names$extra',
      duration: const Duration(seconds: 7),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            // Fila 1: Hero + Facturas
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _HeroSalesCard(
                      sales: provider.monthlySales,
                      weeklySales: provider.weeklySales,
                      currency: _currency,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _InvoiceStatCard(count: provider.invoiceCount),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Fila 2: Inventario + Ganancia + Stock
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SmallStatCard(
                      icon: Icons.inventory_2_rounded,
                      iconBg: AppTheme.lightOrange,
                      iconColor: AppTheme.accentOrange,
                      value: '${provider.totalProducts}',
                      label: 'Productos activos',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SmallStatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      iconBg: AppTheme.lightMagenta,
                      iconColor: AppTheme.accentMagenta,
                      value: _currency.format(provider.monthlyProfit),
                      label: 'Ganancia neta',
                      sublabel: provider.monthlySales > 0
                          ? 'Margen ${((provider.monthlyProfit / provider.monthlySales) * 100).toStringAsFixed(1)}%'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StockCard(
                      products: provider.lowStockProducts,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Fila 3: Últimas facturas full-width
            _RecentInvoicesCard(
              invoices: provider.recentInvoices,
              currency: _currency,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat("d 'de' MMMM, yyyy", 'es').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ThemeHelper.getTextColor(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Resumen del mes actual',
              style: TextStyle(
                fontSize: 12,
                color: ThemeHelper.getTextLightColor(context),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ThemeHelper.getCardColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ThemeHelper.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 11,
                color: ThemeHelper.getTextLightColor(context),
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: ThemeHelper.getTextLightColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

// ─── Card héroe: ventas + gráfico ────────────────────────────────────────────

class _HeroSalesCard extends StatelessWidget {
  final double sales;
  final List<double> weeklySales;
  final NumberFormat currency;

  const _HeroSalesCard({
    required this.sales,
    required this.weeklySales,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final maxVal = weeklySales.isNotEmpty
        ? weeklySales.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final dayLabels = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return names[day.weekday - 1];
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta superior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.accentMagenta.withValues(alpha: 0.15)
                          : AppTheme.lightMagenta,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: AppTheme.accentMagenta,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ventas del mes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.getTextMediumColor(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: ThemeHelper.getSuccessLightBg(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+12% vs anterior',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.getSuccessTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Monto principal
          Text(
            currency.format(sales),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: ThemeHelper.getTextColor(context),
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Total facturado este mes',
            style: TextStyle(
              fontSize: 11,
              color: ThemeHelper.getTextLightColor(context),
            ),
          ),
          const SizedBox(height: 12),
          // Gráfico de barras
          Text(
            'Últimos 7 días',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextLightColor(context),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final ratio = maxVal > 0 ? weeklySales[i] / maxVal : 0.0;
                final isToday = i == 6;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio < 0.06 ? 0.06 : ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppTheme.accentMagenta
                                    : (isDark
                                          ? AppTheme.darkBorderColor
                                          : AppTheme.lightBlue),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isToday ? 'Hoy' : dayLabels[i],
                          style: TextStyle(
                            fontSize: 8,
                            color: isToday
                                ? AppTheme.accentMagenta
                                : ThemeHelper.getTextLightColor(context),
                            fontWeight: isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card facturas ────────────────────────────────────────────────────────────

class _InvoiceStatCard extends StatelessWidget {
  final int count;

  const _InvoiceStatCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                  : AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextLight : AppTheme.primaryBlue,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Facturas generadas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppTheme.darkTextMedium
                  : AppTheme.primaryBlue.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Este mes',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.darkTextMedium
                  : AppTheme.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cards pequeños (fila 2) ──────────────────────────────────────────────────

class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String? sublabel;

  const _SmallStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ThemeHelper.getTextColor(context),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: ThemeHelper.getTextLightColor(context),
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 3),
            Text(
              sublabel!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getSuccessTextColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Card stock bajo ──────────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final List<Product> products;

  const _StockCard({required this.products});

  void _goToProduct(BuildContext context, Product p) {
    final id = p.id;
    if (id == null) return;
    StatePersistence().setString('last_route', AppRoutes.inventory);
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.inventory,
      arguments: id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = products.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isEmpty
        ? (isDark
              ? AppTheme.successColor.withValues(alpha: 0.1)
              : AppTheme.successLight)
        : (isDark
              ? AppTheme.warningColor.withValues(alpha: 0.08)
              : AppTheme.warningLight);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                isEmpty
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                size: 17,
                color: isEmpty
                    ? ThemeHelper.getSuccessTextColor(context)
                    : ThemeHelper.getWarningTextColor(context),
              ),
              if (!isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeHelper.getWarningLightBg(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${products.length} alertas',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.getWarningTextColor(context),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isEmpty ? 'Stock OK' : 'Stock bajo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isEmpty
                  ? ThemeHelper.getSuccessTextColor(context)
                  : ThemeHelper.getWarningTextColor(context),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isEmpty
                ? 'Todo el inventario\nestá en orden'
                : '${products.length} producto${products.length > 1 ? 's' : ''} con\nnivel crítico',
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              color: isEmpty
                  ? ThemeHelper.getSuccessTextColor(
                      context,
                    ).withValues(alpha: 0.75)
                  : ThemeHelper.getWarningTextColor(
                      context,
                    ).withValues(alpha: 0.75),
            ),
          ),
          if (!isEmpty) ...[
            const Spacer(),
            ...products.take(2).map((p) {
              final ratio = p.minStock > 0 ? p.stock / p.minStock : 0.0;
              return Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: ThemeHelper.getTextMediumColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: p.id == null
                              ? null
                              : () => _goToProduct(context, p),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppTheme.accentMagenta,
                          ),
                          child: Text(
                            'Ir al producto',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: ThemeHelper.getTextMediumColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${p.stock}u',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.getWarningTextColor(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: ThemeHelper.getWarningTextColor(
                          context,
                        ).withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeHelper.getWarningTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Card últimas facturas (full-width) ───────────────────────────────────────

class _RecentInvoicesCard extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  final NumberFormat currency;

  const _RecentInvoicesCard({required this.invoices, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimas facturas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              if (invoices.isNotEmpty)
                Text(
                  '${invoices.length} registros',
                  style: TextStyle(
                    fontSize: 10,
                    color: ThemeHelper.getTextLightColor(context),
                  ),
                ),
            ],
          ),
          if (invoices.isEmpty) ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                'No hay facturas aún',
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeHelper.getTextLightColor(context),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ] else ...[
            const SizedBox(height: 8),
            // Cabecera de tabla
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      'No.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.getTextLightColor(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'CLIENTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.getTextLightColor(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.getTextLightColor(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: ThemeHelper.getBorderColor(context)),
            ...invoices.asMap().entries.map((entry) {
              final i = entry.key;
              final inv = entry.value;
              final isAlt = i.isOdd;
              return Container(
                color: isAlt
                    ? ThemeHelper.getAltRowColor(context)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        '#${inv['id'].toString().padLeft(4, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ThemeHelper.getInteractiveColor(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        inv['customer_name'] ?? 'Cliente general',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.getTextMediumColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      currency.format(inv['total']),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
