import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currency = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Carga los datos al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMetrics(provider),
            const SizedBox(height: 20),
            _buildBottomRow(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resumen del mes actual',
              style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.black.withOpacity(0.07),
              width: 0.5,
            ),
          ),
          child: Text(
            dateStr,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics(AppProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.trending_up_rounded,
            iconBg: AppTheme.lightMagenta,
            iconColor: AppTheme.accentMagenta,
            value: _currency.format(provider.monthlySales),
            label: 'Ventas del mes',
            delta: '+12% vs mes anterior',
            deltaPositive: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.receipt_long_rounded,
            iconBg: AppTheme.lightBlue,
            iconColor: AppTheme.primaryBlue,
            value: '${provider.invoiceCount}',
            label: 'Facturas generadas',
            delta: 'Este mes',
            deltaPositive: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.inventory_2_rounded,
            iconBg: AppTheme.lightOrange,
            iconColor: AppTheme.accentOrange,
            value: '${provider.totalProducts}',
            label: 'Productos activos',
            delta: provider.lowStockProducts.isEmpty
                ? 'Stock OK'
                : '⚠ ${provider.lowStockProducts.length} con stock bajo',
            deltaPositive: provider.lowStockProducts.isEmpty,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.star_rounded,
            iconBg: AppTheme.lightMagenta,
            iconColor: AppTheme.accentMagenta,
            value: _currency.format(provider.monthlyProfit),
            label: 'Ganancia neta',
            delta: provider.monthlySales > 0
                ? 'Margen ${((provider.monthlyProfit / provider.monthlySales) * 100).toStringAsFixed(1)}%'
                : 'Sin ventas aún',
            deltaPositive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(AppProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _SalesPanel(
            weeklySales: provider.weeklySales,
            recentInvoices: provider.recentInvoices,
            currency: _currency,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: _LowStockPanel(products: provider.lowStockProducts),
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

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String delta;
  final bool deltaPositive;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.delta,
    required this.deltaPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: TextStyle(
              fontSize: 10,
              color: deltaPositive
                  ? const Color(0xFF3B6D11)
                  : const Color(0xFF854F0B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesPanel extends StatelessWidget {
  final List<double> weeklySales;
  final List<Map<String, dynamic>> recentInvoices;
  final NumberFormat currency;

  const _SalesPanel({
    required this.weeklySales,
    required this.recentInvoices,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final maxVal = weeklySales.reduce((a, b) => a > b ? a : b);

    // Genera las etiquetas de los últimos 7 días dinámicamente
    final dayLabels = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return names[day.weekday - 1];
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas — últimos 7 días',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final ratio = maxVal > 0 ? weeklySales[i] / maxVal : 0.0;
                final isToday = i == 6;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio < 0.05 ? 0.05 : ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppTheme.accentMagenta
                                    : AppTheme.lightBlue,
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
                            fontSize: 9,
                            color: isToday
                                ? AppTheme.accentMagenta
                                : const Color(0xFFB4B2A9),
                            fontWeight: isToday
                                ? FontWeight.w500
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
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0x12000000)),
          const SizedBox(height: 12),
          const Text(
            'Últimas facturas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
          const SizedBox(height: 8),
          if (recentInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No hay facturas aún',
                style: TextStyle(fontSize: 12, color: Color(0xFF888780)),
              ),
            )
          else
            ...recentInvoices.map(
              (inv) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(
                      '#${inv['id'].toString().padLeft(4, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888780),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        inv['customer_name'] ?? 'Cliente general',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF444441),
                        ),
                      ),
                    ),
                    Text(
                      currency.format(inv['total']),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  final List<dynamic> products;

  const _LowStockPanel({required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stock agotándose',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C2C2A),
                ),
              ),
              if (products.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${products.length} alertas',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFA32D2D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Todo el stock está bien',
                style: TextStyle(fontSize: 12, color: Color(0xFF888780)),
              ),
            )
          else
            ...products.map((p) {
              final ratio = p.minStock > 0 ? p.stock / p.minStock : 0.0;
              final isRed = p.stock <= (p.minStock * 0.3);
              final barColor = isRed
                  ? const Color(0xFFE24B4A)
                  : const Color(0xFFEF9F27);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF444441),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.stock} u.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isRed
                                ? const Color(0xFFA32D2D)
                                : const Color(0xFF854F0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: const Color(0xFFF1EFE8),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
