import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app.dart';
import '../../core/reports_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = ReportsRepository();
  final _currency = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd/MM/yyyy', 'es');

  late DateTime _startDate;
  late DateTime _endDate;

  Map<String, dynamic> _summary = {
    'total': 0.0,
    'profit': 0.0,
    'count': 0,
    'avgTicket': 0.0,
  };
  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _topCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _load();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      });
      _load();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
      _load();
    }
  }

  void _prevDay(bool isStart) {
    setState(() {
      if (isStart) {
        _startDate = _startDate.subtract(const Duration(days: 1));
      } else {
        _endDate = _endDate.subtract(const Duration(days: 1));
      }
    });
    _load();
  }

  void _nextDay(bool isStart) {
    final now = DateTime.now();
    setState(() {
      if (isStart) {
        final newDate = _startDate.add(const Duration(days: 1));
        if (!newDate.isAfter(_endDate) && !newDate.isAfter(now)) {
          _startDate = newDate;
        }
      } else {
        final newDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day + 1,
          23,
          59,
          59,
        );
        if (!newDate.isAfter(
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        )) {
          _endDate = newDate;
        }
      }
    });
    _load();
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final results = await Future.wait([
      _repo.getSummary(_startDate, _endDate),
      _repo.getSalesByDay(_startDate, _endDate),
      _repo.getTopProducts(_startDate, _endDate),
      _repo.getTopCategories(_startDate, _endDate),
    ]);

    setState(() {
      _summary = results[0] as Map<String, dynamic>;
      _chartData = results[1] as List<Map<String, dynamic>>;
      _topProducts = results[2] as List<Map<String, dynamic>>;
      _topCategories = results[3] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildMetrics(),
                  const SizedBox(height: 20),
                  _buildChart(),
                  const SizedBox(height: 20),
                  _buildBottomRow(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final isToday =
        _startDate.year == now.year &&
        _startDate.month == now.month &&
        _startDate.day == now.day &&
        _endDate.year == now.year &&
        _endDate.month == now.month &&
        _endDate.day == now.day;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Resumen de ventas y ganancias',
              style: TextStyle(fontSize: 13, color: Color(0xFF888780)),
            ),
          ],
        ),
        Row(
          children: [
            _buildDateField('Desde', _startDate, _selectStartDate),
            const SizedBox(width: 8),
            _buildDateField('Hasta', _endDate, _selectEndDate),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFFEAF3DE) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFF3B6D11)
                      : Colors.black.withOpacity(0.07),
                  width: 0.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _setToday,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      'Hoy',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF27500A)
                            : const Color(0xFF888780),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.black.withOpacity(0.07),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateArrow(
                Icons.chevron_left_rounded,
                label == 'Desde' ? true : false,
                true,
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: Colors.black.withOpacity(0.07),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF888780),
                            ),
                          ),
                          Text(
                            _dateFormat.format(date),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C2C2A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _dateArrow(
                Icons.chevron_right_rounded,
                label == 'Desde' ? true : false,
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateArrow(IconData icon, bool isStart, bool isPrev) {
    return InkWell(
      onTap: () => isPrev ? _prevDay(isStart) : _nextDay(isStart),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: const Color(0xFF888780)),
      ),
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.trending_up_rounded,
            iconBg: const Color(0xFFE1F5EE),
            iconColor: const Color(0xFF0F6E56),
            label: 'Total vendido',
            value: _currency.format(_summary['total']),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.star_rounded,
            iconBg: const Color(0xFFEAF3DE),
            iconColor: const Color(0xFF639922),
            label: 'Ganancia neta',
            value: _currency.format(_summary['profit']),
            sub: _summary['total'] > 0
                ? 'Margen ${((_summary['profit'] / _summary['total']) * 100).toStringAsFixed(1)}%'
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.receipt_long_rounded,
            iconBg: const Color(0xFFE6F1FB),
            iconColor: const Color(0xFF185FA5),
            label: 'Facturas',
            value: '${_summary['count']}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.point_of_sale_rounded,
            iconBg: const Color(0xFFFAEEDA),
            iconColor: const Color(0xFFBA7517),
            label: 'Venta promedio por factura',
            value: _currency.format(_summary['avgTicket']),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_chartData.isEmpty) {
      return _panel(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Sin ventas en este período',
              style: TextStyle(fontSize: 12, color: Color(0xFF888780)),
            ),
          ),
        ),
        title: 'Ventas por día',
      );
    }

    final maxVal = _chartData
        .map((d) => (d['total'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    final monthLabels = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    final daysDiff = _endDate.difference(_startDate).inDays;
    final showByMonth = daysDiff > 60;

    return _panel(
      title: showByMonth ? 'Ventas por mes' : 'Ventas por día',
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _chartData.map((d) {
            final val = (d['total'] as num).toDouble();
            final ratio = maxVal > 0 ? val / maxVal : 0.0;
            String label;
            if (showByMonth) {
              final idx = int.tryParse(d['month'].toString()) ?? 1;
              label = monthLabels[idx - 1];
            } else {
              final day = DateTime.tryParse(d['day'].toString());
              label = day != null ? '${day.day}' : '';
            }
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: ratio < 0.04 ? 0.04 : ratio,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFB4B2A9),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTopProducts()),
        const SizedBox(width: 14),
        Expanded(child: _buildTopCategories()),
      ],
    );
  }

  Widget _buildTopProducts() {
    return _panel(
      title: 'Productos más vendidos',
      child: _topProducts.isEmpty
          ? const Text(
              'Sin datos para este período',
              style: TextStyle(fontSize: 12, color: Color(0xFF888780)),
            )
          : Column(
              children: _topProducts.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final qty = (p['total_qty'] as num).toInt();
                final amount = (p['total_amount'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? const Color(0xFFFAEEDA)
                              : const Color(0xFFF1EFE8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: i == 0
                                  ? const Color(0xFFBA7517)
                                  : const Color(0xFF888780),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p['product_name'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444441),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$qty u.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888780),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currency.format(amount),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C2C2A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTopCategories() {
    final catTotal = _topCategories.fold(
      0.0,
      (sum, c) => sum + (c['total_amount'] as num).toDouble(),
    );

    return _panel(
      title: 'Categorías más vendidas',
      child: _topCategories.isEmpty
          ? const Text(
              'Sin datos para este período',
              style: TextStyle(fontSize: 12, color: Color(0xFF888780)),
            )
          : Column(
              children: _topCategories.map((cat) {
                final amount = (cat['total_amount'] as num).toDouble();
                final pct = catTotal > 0 ? amount / catTotal : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat['category'].toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF444441),
                            ),
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888780),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFF1EFE8),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currency.format(amount),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF888780),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String? sub;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sub,
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
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888780)),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: const TextStyle(fontSize: 10, color: Color(0xFF3B6D11)),
            ),
          ],
        ],
      ),
    );
  }
}
