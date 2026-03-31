import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_helper.dart';
import '../../core/invoice_repository.dart';
import '../../core/pdf_service.dart';
import '../../core/app_exception.dart';
import '../../services/notification_service.dart';
import '../../models/invoice.dart';
import '../invoices/invoice_preview_screen.dart';
import '../../utils/responsive_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repo = InvoiceRepository();
  final _searchCtrl = TextEditingController();
  final _currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'RD\$ ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd/MM/yyyy', 'es');

  List<Invoice> _all = [];
  List<Invoice> _filtered = [];
  late DateTime _startDate;
  late DateTime _endDate;
  String _statusFilter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _repo.getAll();
      if (mounted) {
        setState(() {
          _all = result;
          _applyFilters();
          _loading = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _loading = false);
      NotificationService().error(e.message);
    }
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
        _endDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          23,
          59,
          59,
        );
      });
      _applyFilters();
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
      _applyFilters();
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
    _applyFilters();
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
    _applyFilters();
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();

    setState(() {
      _filtered = _all.where((inv) {
        final matchesQuery =
            query.isEmpty ||
            (inv.customerName ?? '').toLowerCase().contains(query) ||
            inv.id.toString().contains(query);

        final date = DateTime.parse(inv.createdAt);
        final matchesDate =
            !date.isBefore(_startDate) && !date.isAfter(_endDate);

        bool matchesStatus = true;
        if (_statusFilter == 'active') {
          matchesStatus = inv.isActive;
        } else if (_statusFilter == 'cancelled') {
          matchesStatus = inv.isCancelled;
        }

        return matchesQuery && matchesDate && matchesStatus;
      }).toList();
    });
  }

  // Totales del período filtrado (solo activas para métricas)
  double get _filteredTotal => _filtered
      .where((inv) => inv.isActive)
      .fold(0, (sum, inv) => sum + inv.total);
  double get _filteredDiscount => _filtered
      .where((inv) => inv.isActive)
      .fold(0, (sum, inv) => sum + inv.discountGlobal);
  int get _activeCount => _filtered.where((inv) => inv.isActive).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Padding(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSummaryBar(),
            const SizedBox(height: 16),
            _buildToolbar(),
            const SizedBox(height: 12),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount = _filtered.where((inv) => inv.isActive).length;
    final cancelledCount = _filtered.where((inv) => inv.isCancelled).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$activeCount activas${cancelledCount > 0 ? ' • $cancelledCount anuladas' : ''} • ${_filtered.length} total',
              style: TextStyle(fontSize: 13, color: ThemeHelper.getTextLightColor(context)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryBar() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total facturado',
            value: _currency.format(_filteredTotal),
            icon: Icons.trending_up_rounded,
            iconBg: ThemeHelper.getSuccessLightBg(context),
            iconColor: const Color(0xFF0F6E56),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Facturas activas',
            value: '$_activeCount',
            icon: Icons.receipt_long_rounded,
            iconBg: ThemeHelper.getInfoLightBg(context),
            iconColor: const Color(0xFF185FA5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Descuentos aplicados',
            value: _currency.format(_filteredDiscount),
            icon: Icons.discount_rounded,
            iconBg: ThemeHelper.getErrorLightBg(context),
            iconColor: AppTheme.errorDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Promedio por factura',
            value: _activeCount == 0
                ? _currency.format(0)
                : _currency.format(_filteredTotal / _activeCount),
            icon: Icons.point_of_sale_rounded,
            iconBg: ThemeHelper.getWarningLightBg(context),
            iconColor: AppTheme.warningDark,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final now = DateTime.now();
    final isToday =
        _startDate.year == now.year &&
        _startDate.month == now.month &&
        _startDate.day == now.day &&
        _endDate.year == now.year &&
        _endDate.month == now.month &&
        _endDate.day == now.day;

    return Row(
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Buscar por cliente o # factura...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: ThemeHelper.getTextLightColor(context),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 17,
                color: ThemeHelper.getTextLightColor(context),
              ),
              filled: true,
              fillColor: ThemeHelper.getCardColor(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ThemeHelper.getBorderColor(context),
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ThemeHelper.getBorderColor(context),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildDateField('Desde', _startDate, _selectStartDate),
        const SizedBox(width: 8),
        _buildDateField('Hasta', _endDate, _selectEndDate),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: isToday ? ThemeHelper.getSuccessLightBg(context) : ThemeHelper.getCardColor(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isToday
                  ? ThemeHelper.getSuccessTextColor(context)
                  : ThemeHelper.getBorderColor(context),
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
                        ? ThemeHelper.getSuccessTextColor(context)
                        : ThemeHelper.getTextLightColor(context),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusFilter(),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusBtn('Todas', 'all'),
          _statusBtn('Activas', 'active'),
          _statusBtn('Anuladas', 'cancelled'),
        ],
      ),
    );
  }

  Widget _statusBtn(String label, String value) {
    final isActive = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : ThemeHelper.getTextLightColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ThemeHelper.getCardColor(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: ThemeHelper.getBorderColor(context),
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
                        color: ThemeHelper.getBorderColor(context),
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
                            style: TextStyle(
                              fontSize: 9,
                              color: ThemeHelper.getTextLightColor(context),
                            ),
                          ),
                          Text(
                            _dateFormat.format(date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ThemeHelper.getTextColor(context),
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
        child: Icon(icon, size: 16, color: ThemeHelper.getTextLightColor(context)),
      ),
    );
  }

  Widget _buildTable() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 48, color: ThemeHelper.getBorderColor(context)),
            const SizedBox(height: 12),
            Text(
              'No hay facturas en este período',
              style: TextStyle(fontSize: 14, color: ThemeHelper.getTextLightColor(context)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _buildRow(_filtered[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: ThemeHelper.getTextLightColor(context),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ThemeHelper.getBorderColor(context))),
      ),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text('#', style: style)),
          Expanded(flex: 3, child: Text('Cliente', style: style)),
          Expanded(flex: 2, child: Text('Fecha', style: style)),
          Expanded(flex: 2, child: Text('Subtotal', style: style)),
          Expanded(flex: 2, child: Text('Descuento', style: style)),
          Expanded(flex: 2, child: Text('Total', style: style)),
          SizedBox(width: 80, child: Text('', style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(Invoice inv, int index) {
    final date = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.parse(inv.createdAt));
    final isEven = index % 2 == 0;
    final isCancelled = inv.isCancelled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isCancelled
          ? ThemeHelper.getErrorLightBg(context).withOpacity(0.3)
          : isEven
          ? Colors.transparent
          : ThemeHelper.getAltRowColor(context),
      child: Row(
        children: [
          SizedBox(
            width: isCancelled ? 90 : 70,
            child: isCancelled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${inv.id.toString().padLeft(4, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ThemeHelper.getTextLightColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE24B4A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'ANULADA',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    '#${inv.id.toString().padLeft(4, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.getTextLightColor(context),
                    ),
                  ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              inv.customerName ?? 'Cliente general',
              style: TextStyle(
                fontSize: 13,
                color: isCancelled
                    ? ThemeHelper.getTextLightColor(context)
                    : ThemeHelper.getTextColor(context),
                decoration: isCancelled
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: isCancelled
                    ? ThemeHelper.getTextLightColor(context)
                    : ThemeHelper.getTextLightColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(inv.subtotal),
              style: TextStyle(
                fontSize: 12,
                color: isCancelled
                    ? ThemeHelper.getTextLightColor(context)
                    : ThemeHelper.getTextMediumColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              inv.discountGlobal > 0
                  ? '- ${_currency.format(inv.discountGlobal)}'
                  : '—',
              style: TextStyle(
                fontSize: 12,
                color: inv.discountGlobal > 0
                    ? ThemeHelper.getErrorTextColor(context)
                    : ThemeHelper.getTextLightColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _currency.format(inv.total),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isCancelled
                    ? ThemeHelper.getTextLightColor(context)
                    : ThemeHelper.getTextColor(context),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  onPressed: isCancelled ? null : () => _previewInvoice(inv),
                  icon: Icon(
                    Icons.print_rounded,
                    size: 16,
                    color: isCancelled
                        ? ThemeHelper.getTextLightColor(context)
                        : AppTheme.primaryBlue,
                  ),
                  tooltip: isCancelled ? 'Factura anulada' : 'Ver e imprimir',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: isCancelled ? null : () => _confirmCancel(inv),
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: isCancelled
                        ? ThemeHelper.getTextLightColor(context)
                        : const Color(0xFFE24B4A),
                  ),
                  tooltip: isCancelled ? 'Factura anulada' : 'Anular',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewInvoice(Invoice inv) async {
    final items = await _repo.getItems(inv.id!);
    final pdfBytes = await PdfService.generate(inv, items);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(pdfBytes: pdfBytes, invoice: inv),
      ),
    );
  }

  void _confirmCancel(Invoice inv) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Anular factura',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: Colors.white.withAlpha(200),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Anular la factura #${inv.id.toString().padLeft(4, '0')}?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¿Desea reponer el stock de los productos?',
                      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextMediumColor(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seleccione "Sí" si el cliente devolvió los productos.',
                      style: TextStyle(fontSize: 11, color: ThemeHelper.getTextLightColor(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeHelper.getAltRowColor(context),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ThemeHelper.getTextLightColor(context),
                          side: BorderSide(color: ThemeHelper.getTextLightColor(context)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await _repo.cancel(inv.id!, restoreStock: false);
                            if (mounted) {
                              Navigator.pop(context);
                              NotificationService().success('Factura anulada');
                              _load();
                            }
                          } on AppException catch (e) {
                            if (mounted) Navigator.pop(context);
                            NotificationService().error(e.message);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE24B4A),
                          side: const BorderSide(color: Color(0xFFE24B4A)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('No reponer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _repo.cancel(inv.id!, restoreStock: true);
                            if (mounted) {
                              Navigator.pop(context);
                              NotificationService().success('Factura anulada y stock repuesto');
                              _load();
                            }
                          } on AppException catch (e) {
                            if (mounted) Navigator.pop(context);
                            NotificationService().error(e.message);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6E56),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Sí, reponer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: ThemeHelper.getTextLightColor(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
