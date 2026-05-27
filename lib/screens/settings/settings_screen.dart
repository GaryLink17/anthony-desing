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
import 'thermal_printer_settings_screen.dart';



/// Pantalla de configuración global del negocio.
///
/// Permite editar datos de la empresa (nombre, RNC, teléfono, email,
/// dirección, logo), cambiar el tema claro/oscuro, gestionar respaldos
/// de base de datos y configurar el pie de página de las facturas.
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Carga los valores guardados desde SharedPreferences.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
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
    });
  }

  /// Persiste todos los campos de configuración en SharedPreferences
  /// y recarga los datos de la empresa en el provider global.
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

    if (mounted) {
      await context.read<AppProvider>().loadCompanyData();
    }

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  /// Abre la galería para seleccionar una imagen de logo.
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
            _buildBackupSection(),
            const SizedBox(height: 20),
            _buildThermalPrinterSection(),
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
                      style: TextStyle(
                        fontSize: 11,
                        color: ThemeHelper.getInteractiveColor(context),
                      ),
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


  Widget _buildThermalPrinterSection() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ThermalPrinterSettingsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ThemeHelper.getCardDecoration(context),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentMagenta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 20, color: AppTheme.accentMagenta),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Impresión POS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Configura la impresora térmica para tickets',
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeHelper.getTextLightColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: ThemeHelper.getTextLightColor(context),
            ),
          ],
        ),
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

  /// Exporta la base de datos completa a un archivo de respaldo.
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

  /// Restaura la base de datos desde un archivo de respaldo.
  /// Solicita confirmación antes de proceder.
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

  /// Campo de formulario reutilizable con validación opcional y
  /// formateo para teléfono.
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
