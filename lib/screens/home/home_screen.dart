import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/metric_card.dart';
import '../../utils/responsive_helper.dart';
import '../../theme/theme_helper.dart';
import '../../core/app_exception.dart';
import '../../services/notification_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<AppProvider>().loadDashboard();
      } on AppException catch (e) {
        NotificationService().error(e.message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        padding: context.responsivePadding,
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resumen del mes actual',
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextLightColor(context)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ThemeHelper.getCardColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ThemeHelper.getBorderColor(context),
              width: 0.5,
            ),
          ),
          child: Text(
            dateStr,
            style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics(AppProvider provider) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
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
          child: MetricCard(
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
          child: MetricCard(
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
          child: MetricCard(
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
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas — últimos 7 días',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextColor(context),
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
                                : ThemeHelper.getTextLightColor(context),
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
          Divider(height: 1, color: ThemeHelper.getBorderColor(context)),
          const SizedBox(height: 12),
          Text(
            'Últimas facturas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          if (recentInvoices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No hay facturas aún',
                style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.getTextLightColor(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        inv['customer_name'] ?? 'Cliente general',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.getTextMediumColor(context),
                        ),
                      ),
                    ),
                    Text(
                      currency.format(inv['total']),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ThemeHelper.getTextColor(context),
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
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock agotándose',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              if (products.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeHelper.getErrorLightBg(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${products.length} alertas',
                    style: TextStyle(
                      fontSize: 10,
                      color: ThemeHelper.getErrorTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Todo el stock está bien',
                style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeHelper.getTextMediumColor(context),
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
                                ? ThemeHelper.getErrorTextColor(context)
                                : ThemeHelper.getWarningTextColor(context),
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
                        backgroundColor: ThemeHelper.getHoverColor(context),
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
