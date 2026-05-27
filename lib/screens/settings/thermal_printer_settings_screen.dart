import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_helper.dart';
import '../../models/thermal_printer_config.dart';
import '../../services/thermal_printer_service.dart';
import '../../core/app_exception.dart';
import '../../services/notification_service.dart';
import '../../utils/responsive_helper.dart';

/// Pantalla de configuración de la impresora térmica POS.
class ThermalPrinterSettingsScreen extends StatefulWidget {
  const ThermalPrinterSettingsScreen({super.key});

  @override
  State<ThermalPrinterSettingsScreen> createState() => _ThermalPrinterSettingsScreenState();
}

class _ThermalPrinterSettingsScreenState extends State<ThermalPrinterSettingsScreen> {
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  String _connectionType = 'network';
  String _usbPortName = '';
  int _paperWidthMM = 80;
  bool _enabled = false;
  bool _testing = false;
  bool _scanning = false;
  List<String> _availablePorts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final config = ThermalPrinterConfig.fromPrefs(prefs);
    setState(() {
      _connectionType = config.connectionType;
      _ipCtrl.text = config.ipAddress;
      _portCtrl.text = config.port.toString();
      _usbPortName = config.usbPortName;
      _paperWidthMM = config.paperWidthMM;
      _enabled = config.enabled;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final config = ThermalPrinterConfig(
      connectionType: _connectionType,
      ipAddress: _ipCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text.trim()) ?? 9100,
      usbPortName: _usbPortName,
      paperWidthMM: _paperWidthMM,
      enabled: _enabled,
    );
    await config.saveToPrefs(prefs);
    if (mounted) {
      NotificationService().success('Configuración guardada');
    }
  }

  Future<void> _scanPorts() async {
    setState(() => _scanning = true);
    try {
      final ports = await ThermalPrinterService.detectUsbPorts();
      if (!mounted) return;
      setState(() {
        _availablePorts = ports;
        _scanning = false;
      });
      if (ports.isEmpty) {
        NotificationService().info('No se detectaron puertos USB. Conecta la impresora.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _scanning = false);
        NotificationService().error('Error al escanear puertos');
      }
    }
  }

  Future<void> _testPrint() async {
    setState(() => _testing = true);
    try {
      await ThermalPrinterService.instance.printTest();
      if (mounted) {
        NotificationService().success('Impresión de prueba enviada');
      }
    } on AppException catch (e) {
      if (mounted) NotificationService().error(e.message);
    } catch (e) {
      if (mounted) {
        NotificationService().error('Error al conectar con la impresora');
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildConnectionSection(),
            const SizedBox(height: 20),
            _buildPaperSection(),
            const SizedBox(height: 20),
            _buildTestSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: ThemeHelper.getTextMediumColor(context),
              tooltip: 'Volver',
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Impresión POS',
                    style: ThemeHelper.getTitleStyle(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configura la impresora térmica para tickets',
                    style: ThemeHelper.getSubtitleStyle(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.print_rounded, size: 16),
              const SizedBox(width: 8),
              Text(
                'Conexión',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const Spacer(),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                activeThumbColor: AppTheme.accentMagenta,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'network', label: Text('Red', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 'usb', label: Text('USB', style: TextStyle(fontSize: 12))),
            ],
            selected: {_connectionType},
            onSelectionChanged: (v) => setState(() => _connectionType = v.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppTheme.accentMagenta.withValues(alpha: 0.15),
              selectedForegroundColor: AppTheme.accentMagenta,
              foregroundColor: ThemeHelper.getTextMediumColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          if (_connectionType == 'network') _buildNetworkFields(),
          if (_connectionType == 'usb') _buildUsbFields(),
        ],
      ),
    );
  }

  Widget _buildNetworkFields() {
    return Column(
      children: [
        TextFormField(
          controller: _ipCtrl,
          enabled: _enabled,
          style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Dirección IP',
            hintText: '192.168.1.100',
            labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _portCtrl,
          enabled: _enabled,
          style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Puerto',
            hintText: '9100',
            labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildUsbFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Puerto USB',
                  hintText: _availablePorts.isEmpty ? 'Conecta la impresora y escanea' : 'Selecciona un puerto',
                  labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _usbPortName.isNotEmpty && _availablePorts.contains(_usbPortName)
                        ? _usbPortName
                        : null,
                    items: _availablePorts.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: _enabled ? (v) => setState(() => _usbPortName = v ?? '') : null,
                    style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                    dropdownColor: ThemeHelper.getCardColor(context),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    isExpanded: true,
                    hint: Text(
                      _availablePorts.isEmpty ? 'Conecta la impresora y escanea' : 'Selecciona un puerto',
                      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextLightColor(context)),
                    ),
                  ),
                ),
              ),
            ),
            if (_usbPortName.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _enabled ? () => setState(() => _usbPortName = '') : null,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: ThemeHelper.getTextMediumColor(context),
                tooltip: 'Limpiar selección',
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _enabled && !_scanning ? _scanPorts : null,
          icon: _scanning
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.usb_rounded, size: 16),
          label: const Text('Detectar puertos USB', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            side: const BorderSide(color: AppTheme.primaryBlue),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaperSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten_rounded, size: 16),
              const SizedBox(width: 8),
              Text(
                'Ancho del papel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPaperOption(58, '58 mm', '32 caracteres'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaperOption(80, '80 mm', '48 caracteres'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaperOption(int width, String label, String subtitle) {
    final selected = _paperWidthMM == width;
    return GestureDetector(
      onTap: _enabled ? () => setState(() => _paperWidthMM = width) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentMagenta.withValues(alpha: 0.1)
              : ThemeHelper.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.accentMagenta : ThemeHelper.getBorderColor(context),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.accentMagenta : ThemeHelper.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: ThemeHelper.getTextLightColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 16),
              const SizedBox(width: 8),
              Text(
                'Probar impresora',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Envía un ticket de prueba para verificar la conexión',
            style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: (_enabled && !_testing) ? _testPrint : null,
            icon: _testing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_rounded, size: 16),
            label: const Text('Imprimir prueba'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentMagenta,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Guardar cambios'),
    );
  }
}
