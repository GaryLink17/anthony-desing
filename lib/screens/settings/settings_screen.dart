import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../theme/theme_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/responsive_helper.dart';
import '../../core/app_exception.dart';
import '../../core/backup_service.dart';
import '../../services/notification_service.dart';
import '../../services/tax_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _rncCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _footerMsgCtrl = TextEditingController();
  final _footerTermsCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _logoPath;
  bool _saved = false;
  bool _backupLoading = false;
  bool _restoreLoading = false;

  TaxConfig _taxConfig = const TaxConfig(
    applyItbis: false,
    itbisRate: TaxService.defaultItbisRate,
    applyIsr: false,
    isrRate: TaxService.defaultIsrRate,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final taxConfig = await TaxService.getConfig();
    setState(() {
      _nameCtrl.text = prefs.getString('company_name') ?? '';
      _phoneCtrl.text = prefs.getString('company_phone') ?? '';
      _rncCtrl.text = prefs.getString('company_rnc') ?? '';
      _addressCtrl.text = prefs.getString('company_address') ?? '';
      _emailCtrl.text = prefs.getString('company_email') ?? '';
      _logoPath = prefs.getString('company_logo');
      _footerMsgCtrl.text =
          prefs.getString('footer_message') ?? '¡Gracias por su compra!';
      _footerTermsCtrl.text =
          prefs.getString('footer_terms') ??
          'Mercancía no se acepta devolución después de 24 horas.';
      _taxConfig = taxConfig;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', _nameCtrl.text.trim());
    await prefs.setString('company_phone', _phoneCtrl.text.trim());
    await prefs.setString('company_rnc', _rncCtrl.text.trim());
    await prefs.setString('company_address', _addressCtrl.text.trim());
    await prefs.setString('company_email', _emailCtrl.text.trim());
    await prefs.setString('footer_message', _footerMsgCtrl.text.trim());
    await prefs.setString('footer_terms', _footerTermsCtrl.text.trim());
    if (_logoPath != null) {
      await prefs.setString('company_logo', _logoPath!);
    }

    await TaxService.saveConfig(_taxConfig);

    if (mounted) {
      await context.read<AppProvider>().loadCompanyData();
    }

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _logoPath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCompanySection(),
            const SizedBox(height: 20),
            _buildAppearanceSection(),
            const SizedBox(height: 20),
            _buildTaxSection(),
            const SizedBox(height: 20),
            _buildBackupSection(),
            const SizedBox(height: 20),
            _buildFooterSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: ThemeHelper.getTitleStyle(context),
        ),
        const SizedBox(height: 4),
        Text(
          'Datos del negocio y opciones de factura',
          style: ThemeHelper.getSubtitleStyle(context),
        ),
      ],
    );
  }

  Widget _buildCompanySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos del negocio',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: ThemeHelper.getHoverColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ThemeHelper.getBorderColor(context),
                          width: 0.5,
                        ),
                      ),
                      child: _logoPath != null && File(_logoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_logoPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 24,
                                  color: ThemeHelper.getTextLightColor(context),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Logo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ThemeHelper.getTextLightColor(context),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _pickLogo,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(90, 20),
                    ),
                    child: Text(
                      'Cambiar',
                      style: TextStyle(fontSize: 11, color: ThemeHelper.getInteractiveColor(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Campos
              Expanded(
                child: Column(
                  children: [
                    _field(_nameCtrl, 'Nombre del negocio', required: true),
                    const SizedBox(height: 12),
                    _field(_rncCtrl, 'RNC'),
                    const SizedBox(height: 12),
                    _field(_phoneCtrl, 'Teléfono', isPhone: true),
                    const SizedBox(height: 12),
                    _field(_emailCtrl, 'Email'),
                    const SizedBox(height: 12),
                    _field(_addressCtrl, 'Dirección'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeHelper.getCardColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ThemeHelper.getBorderColor(context),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apariencia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            size: 16,
                            color: ThemeHelper.getInteractiveColor(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            themeProvider.isDarkMode
                                ? 'Modo oscuro'
                                : 'Modo claro',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: ThemeHelper.getTextColor(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cambia entre tema claro y oscuro',
                        style: TextStyle(
                          fontSize: 11,
                          color: ThemeHelper.getTextLightColor(context),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setDarkMode(value);
                    },
                    activeThumbColor: AppTheme.accentMagenta,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ThemeHelper.getBorderColor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pie de página de la factura',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ambos textos aparecen al final de cada factura impresa',
            style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
          ),
          const SizedBox(height: 16),
          _field(_footerMsgCtrl, 'Mensaje de agradecimiento'),
          const SizedBox(height: 12),
          TextField(
            controller: _footerTermsCtrl,
            maxLines: 3,
            style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
            decoration: InputDecoration(
              labelText: 'Términos y condiciones',
              labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTaxSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impuestos (RD)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Activa los impuestos que se aplicarán por defecto al crear una factura',
            style: TextStyle(fontSize: 12, color: ThemeHelper.getTextLightColor(context)),
          ),
          const SizedBox(height: 16),
          // ITBIS
          Row(
            children: [
              Switch(
                value: _taxConfig.applyItbis,
                onChanged: (v) =>
                    setState(() => _taxConfig = _taxConfig.copyWith(applyItbis: v)),
                activeThumbColor: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITBIS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    Text(
                      'Impuesto sobre Transferencias de Bienes y Servicios',
                      style: TextStyle(fontSize: 11, color: ThemeHelper.getTextLightColor(context)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: _taxConfig.itbisRate.toStringAsFixed(0),
                  enabled: _taxConfig.applyItbis,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                  decoration: InputDecoration(
                    suffixText: '%',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) {
                    final rate = double.tryParse(v);
                    if (rate != null && rate >= 0 && rate <= 100) {
                      setState(() => _taxConfig = _taxConfig.copyWith(itbisRate: rate));
                    }
                  },
                  validator: _taxConfig.applyItbis
                      ? (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null) return 'Inválido';
                          if (n < 0 || n > 100) return '0-100';
                          return null;
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ISR
          Row(
            children: [
              Switch(
                value: _taxConfig.applyIsr,
                onChanged: (v) =>
                    setState(() => _taxConfig = _taxConfig.copyWith(applyIsr: v)),
                activeThumbColor: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retención ISR',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    Text(
                      'Retención sobre servicios (se descuenta del total)',
                      style: TextStyle(fontSize: 11, color: ThemeHelper.getTextLightColor(context)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: _taxConfig.isrRate.toStringAsFixed(0),
                  enabled: _taxConfig.applyIsr,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                  decoration: InputDecoration(
                    suffixText: '%',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (v) {
                    final rate = double.tryParse(v);
                    if (rate != null && rate >= 0 && rate <= 100) {
                      setState(() => _taxConfig = _taxConfig.copyWith(isrRate: rate));
                    }
                  },
                  validator: _taxConfig.applyIsr
                      ? (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null) return 'Inválido';
                          if (n < 0 || n > 100) return '0-100';
                          return null;
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentMagenta,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Guardar cambios'),
        ),
        if (_saved) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: ThemeHelper.getSuccessTextColor(context),
          ),
          const SizedBox(width: 6),
          Text(
            'Guardado correctamente',
            style: TextStyle(fontSize: 13, color: ThemeHelper.getSuccessTextColor(context)),
          ),
        ],
      ],
    );
  }

  Widget _buildBackupSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ThemeHelper.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respaldo de datos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Exporta o restaura la base de datos de la aplicación',
            style: TextStyle(
              fontSize: 12,
              color: ThemeHelper.getTextLightColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _backupLoading ? null : _exportBackup,
                icon: _backupLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_rounded, size: 16),
                label: const Text('Exportar respaldo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeHelper.getInteractiveColor(context),
                  side: BorderSide(color: ThemeHelper.getInteractiveColor(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _restoreLoading ? null : _restoreBackup,
                icon: _restoreLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 16),
                label: const Text('Restaurar respaldo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeHelper.getWarningTextColor(context),
                  side: BorderSide(color: ThemeHelper.getWarningTextColor(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _backupLoading = true);
    try {
      final path = await BackupService.instance.exportBackup();
      if (path != null && mounted) {
        NotificationService().success('Respaldo guardado correctamente');
      }
    } on AppException catch (e) {
      if (mounted) NotificationService().error(e.message);
    } catch (e) {
      if (mounted) NotificationService().error('Error inesperado al exportar el respaldo.');
    } finally {
      if (mounted) setState(() => _backupLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Restaurar respaldo?'),
        content: const Text(
          'Esta acción reemplazará todos los datos actuales '
          '(productos, facturas, cotizaciones) con los del archivo seleccionado. '
          'Esta operación no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _restoreLoading = true);
    try {
      final result = await BackupService.instance.restoreBackup();
      if (result == true && mounted) {
        await context.read<AppProvider>().reloadAfterRestore();
        NotificationService().success('Base de datos restaurada correctamente');
      }
    } on AppException catch (e) {
      if (mounted) NotificationService().error(e.message);
    } catch (e) {
      if (mounted) {
        NotificationService().error(
          'Error inesperado al restaurar. La base de datos anterior se conservó.',
        );
      }
    } finally {
      if (mounted) setState(() => _restoreLoading = false);
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: ctrl,
      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhone
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\+\(\)]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: ThemeHelper.getTextMediumColor(context)),
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
