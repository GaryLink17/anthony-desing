import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_helper.dart';
import '../../core/customer_repository.dart';
import '../../core/app_exception.dart';
import '../../models/customer.dart';
import '../../services/notification_service.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/state_builder.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repo = CustomerRepository();
  final _searchCtrl = TextEditingController();
  List<Customer> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String query = '']) async {
    setState(() => _loading = true);
    try {
      final result = query.isEmpty
          ? await _repo.getAll()
          : await _repo.search(query);
      setState(() {
        _customers = result;
        _loading = false;
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _loading = false);
      NotificationService().error(e.message);
    }
  }

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
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            Text(
              '${_customers.length} clientes registrados',
              style: TextStyle(
                fontSize: 13,
                color: ThemeHelper.getTextLightColor(context),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openNewCustomer,
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Nuevo cliente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentMagenta,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchCtrl,
        onChanged: _load,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, teléfono o RNC...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: ThemeHelper.getHintColor(context),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: ThemeHelper.getHintColor(context),
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
    );
  }

  Widget _buildContent() {
    return StateBuilder(
      isLoading: _loading,
      isEmpty: _customers.isEmpty,
      icon: Icons.people_outline_rounded,
      emptyTitle: 'No hay clientes aún',
      emptyDescription: 'Presiona "Nuevo cliente" para agregar el primero',
      child: Container(
        decoration: BoxDecoration(
          color: ThemeHelper.getCardColor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ThemeHelper.getBorderColor(context),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _customers.length,
                itemBuilder: (_, i) => _buildRow(_customers[i], i),
              ),
            ),
          ],
        ),
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
        border: Border(
          bottom: BorderSide(color: ThemeHelper.getBorderColor(context)),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Nombre', style: style)),
          Expanded(flex: 2, child: Text('Teléfono', style: style)),
          Expanded(flex: 2, child: Text('RNC', style: style)),
          Expanded(flex: 3, child: Text('Dirección', style: style)),
          SizedBox(width: 80, child: Text('', style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(Customer customer, int index) {
    final isEven = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isEven
          ? Colors.transparent
          : ThemeHelper.getAltRowColor(context),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              customer.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              customer.phone ?? '—',
              style: TextStyle(
                fontSize: 12,
                color: ThemeHelper.getTextMediumColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              customer.rnc ?? '—',
              style: TextStyle(
                fontSize: 12,
                color: ThemeHelper.getTextMediumColor(context),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              customer.address ?? '—',
              style: TextStyle(
                fontSize: 12,
                color: ThemeHelper.getTextLightColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _openEditCustomer(customer),
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppTheme.accentOrange,
                  ),
                  tooltip: 'Editar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(customer),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFE24B4A),
                  ),
                  tooltip: 'Eliminar',
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

  void _openNewCustomer() async {
    await showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(
        onSave: (customer) async {
          try {
            await _repo.save(customer);
            NotificationService().success('Cliente guardado correctamente');
            _load();
          } on AppException catch (e) {
            NotificationService().error(e.message);
          }
        },
      ),
    );
  }

  void _openEditCustomer(Customer customer) async {
    await showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(
        existing: customer,
        onSave: (updated) async {
          try {
            await _repo.update(updated);
            NotificationService().success('Cliente actualizado correctamente');
            _load();
          } on AppException catch (e) {
            NotificationService().error(e.message);
          }
        },
      ),
    );
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          '¿Eliminar a "${customer.name}"? Las facturas existentes no se verán afectadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _repo.delete(customer.id!);
                NotificationService().success('Cliente eliminado');
                _load();
              } on AppException catch (e) {
                NotificationService().error(e.message);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE24B4A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final Customer? existing;
  final Function(Customer) onSave;

  const _CustomerFormDialog({this.existing, required this.onSave});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _rncCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _phoneCtrl.text = widget.existing!.phone ?? '';
      _emailCtrl.text = widget.existing!.email ?? '';
      _rncCtrl.text = widget.existing!.rnc ?? '';
      _addressCtrl.text = widget.existing!.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _rncCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      rnc: _rncCtrl.text.trim().isEmpty ? null : _rncCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now().toIso8601String(),
    );

    widget.onSave(customer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Text(
                      isEdit ? 'Editar cliente' : 'Nuevo cliente',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildField(_nameCtrl, 'Nombre *', required: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(_phoneCtrl, 'Teléfono'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(_rncCtrl, 'RNC'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(_emailCtrl, 'Correo electrónico'),
                    const SizedBox(height: 12),
                    _buildField(_addressCtrl, 'Dirección'),
                  ],
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: ThemeHelper.getTextMediumColor(context),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentMagenta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isEdit ? 'Actualizar' : 'Guardar'),
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

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      style: TextStyle(
        fontSize: 13,
        color: ThemeHelper.getTextColor(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: ThemeHelper.getTextMediumColor(context),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }
}
