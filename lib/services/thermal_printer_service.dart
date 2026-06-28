import 'dart:io';
import 'dart:typed_data';
import 'package:esc_pos_printer_lts/esc_pos_printer_lts.dart';
import 'package:esc_pos_utils_lts/esc_pos_utils_lts.dart';
import 'package:libserialport_plus/libserialport_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../models/thermal_printer_config.dart';
import '../utils/currency_config.dart';
import '../core/app_exception.dart';

/// Servicio para imprimir tickets fiscales en impresoras térmicas POS
/// compatibles con ESC/POS a través de red TCP/IP o USB.
class ThermalPrinterService {
  ThermalPrinterService._();

  static final ThermalPrinterService instance = ThermalPrinterService._();

  static NumberFormat _currency() => currencyFormatter();

  static NumberFormat _qty() => NumberFormat.decimalPattern('en_US');

  Future<ThermalPrinterConfig> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return ThermalPrinterConfig.fromPrefs(prefs);
  }

  Future<_CompanyConfig> _loadCompanyConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return _CompanyConfig(
      companyName: prefs.getString('company_name') ?? 'Mi Negocio',
      companyPhone: prefs.getString('company_phone') ?? '',
      // companyRnc: prefs.getString('company_rnc') ?? '', // RNC deshabilitado
      companyAddress: prefs.getString('company_address') ?? '',
      companyEmail: prefs.getString('company_email') ?? '',
      footerMessage:
          prefs.getString('footer_message') ?? '¡Gracias por su compra!',
      footerTerms: prefs.getString('footer_terms') ?? '',
    );
  }

  Future<Generator> _getGenerator(ThermalPrinterConfig config) async {
    final paperSize = config.paperWidthMM == 58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    return Generator(paperSize, profile);
  }

  Future<void> _sendNetwork(
    List<int> bytes,
    ThermalPrinterConfig config,
  ) async {
    final paperSize = config.paperWidthMM == 58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paperSize, profile);

    try {
      final result = await printer.connect(
        config.ipAddress,
        port: config.port,
        timeout: const Duration(seconds: 5),
      );

      if (result != PosPrintResult.success) {
        throw AppException(
          'No se pudo conectar a la impresora en ${config.ipAddress}:${config.port}',
          technical: result.msg,
        );
      }

      try {
        printer.rawBytes(bytes);
      } on Exception catch (e) {
        throw AppException(
          'Error al enviar datos a la impresora',
          technical: e.toString(),
        );
      }
    } finally {
      printer.disconnect();
    }
  }

  Future<void> _sendUsb(List<int> bytes, ThermalPrinterConfig config) async {
    final path = config.usbPortName;

    if (path.isEmpty) {
      throw const AppException('Puerto USB no especificado.');
    }

    // Linux raw USB printer device
    if (path.startsWith('/dev/usb/lp')) {
      await _sendRawFile(bytes, path);
      return;
    }

    // Windows printer share path (\\localhost\PrinterName o \\COMPUTER\Printer)
    if (path.startsWith('\\\\') || path.startsWith('\\localhost\\')) {
      await _sendWindowsPrinter(bytes, path);
      return;
    }

    // Windows named printer or COM port
    if (Platform.isWindows) {
      if (path.startsWith('COM')) {
        await _sendSerialPort(bytes, path);
        return;
      }
      // Es un nombre de impresora Windows (ej. "POS-58", "TM-T20")
      await _sendWindowsPrinter(bytes, path);
      return;
    }

    // Fallback: intentar como puerto serie
    await _sendSerialPort(bytes, path);
  }

  Future<void> _sendSerialPort(List<int> bytes, String path) async {
    final port = SerialPort(path);
    try {
      port.open(SerialPortMode.readWrite);
      port.write(Uint8List.fromList(bytes));
    } on Exception catch (e) {
      throw AppException(
        'No se pudo conectar al puerto serie $path',
        technical: e.toString(),
      );
    } finally {
      try {
        port.close();
      } catch (_) {}
      port.dispose();
    }
  }

  /// Escapa caracteres peligrosos del nombre de impresora para evitar
  /// inyección de comandos PowerShell.
  String _sanitizePrinterName(String name) {
    return name
        .replaceAll('`', '``')
        .replaceAll('"', '`"')
        .replaceAll(r'$', r'`$')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();
  }

  static String _sanitizeText(String text) {
    return text
        .replaceAll('Á', 'A').replaceAll('á', 'a')
        .replaceAll('É', 'E').replaceAll('é', 'e')
        .replaceAll('Í', 'I').replaceAll('í', 'i')
        .replaceAll('Ó', 'O').replaceAll('ó', 'o')
        .replaceAll('Ú', 'U').replaceAll('ú', 'u')
        .replaceAll('Ü', 'U').replaceAll('ü', 'u')
        .replaceAll('Ñ', 'N').replaceAll('ñ', 'n')
        .replaceAll('¿', '?').replaceAll('¡', '!');
  }

  /// Envía bytes raw a una impresora Windows por su nombre de dispositivo.
  /// Usa Write-Printer de PowerShell 5+ (no requiere compartir la impresora)
  /// con fallback a copy /b (requiere compartir).
  Future<void> _sendWindowsPrinter(List<int> bytes, String printerName) async {
    try {
      final safeName = _sanitizePrinterName(printerName);
      final tempFile = File(
        p.join(
          Directory.systemTemp.path,
          'pos_${DateTime.now().millisecondsSinceEpoch}.bin',
        ),
      );
      await tempFile.writeAsBytes(bytes);

      // Estrategia 1: PowerShell Write-Printer (no requiere compartir)
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '\$data = [System.IO.File]::ReadAllBytes(\'${tempFile.path}\'); '
            'Write-Printer -Name "$safeName" -Data \$data',
      ], runInShell: true);

      // Estrategia 2 (fallback): copy /b a ruta compartida
      if (result.exitCode != 0) {
        final target = printerName.startsWith('\\\\')
            ? printerName
            : '\\\\localhost\\$printerName';
        final result2 = await Process.run('cmd', [
          '/c',
          'copy',
          '/b',
          tempFile.path,
          target,
        ], runInShell: true);

        if (result2.exitCode != 0) {
          throw AppException(
            'No se pudo imprimir en "$printerName". '
            'Asegúrate de que: (1) la impresora esté instalada, '
            '(2) tenga un driver "Generic / Text Only" instalado, '
            'o (3) comparte la impresora en Windows y usa el nombre de recurso.',
          );
        }
      }

      try {
        await tempFile.delete();
      } catch (_) {}
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      throw AppException(
        'Error al enviar a la impresora Windows',
        technical: e.toString(),
      );
    }
  }

  Future<void> _sendRawFile(List<int> bytes, String path) async {
    try {
      final file = File(path);
      await file.writeAsBytes(bytes);
    } on Exception catch (e) {
      throw AppException(
        'No se pudo escribir en $path',
        technical: e.toString(),
      );
    }
  }

  Future<void> _routeBytes(List<int> bytes, ThermalPrinterConfig config) async {
    if (!config.enabled) {
      throw const AppException(
        'Impresora POS no configurada. Actívala en Configuración > Impresión POS.',
      );
    }

    if (config.connectionType == 'usb') {
      if (config.usbPortName.isEmpty) {
        throw const AppException(
          'Puerto USB no seleccionado. Ve a Configuración > Impresión POS.',
        );
      }
      await _sendUsb(bytes, config);
    } else {
      if (config.ipAddress.isEmpty) {
        throw const AppException(
          'Dirección IP no configurada. Ve a Configuración > Impresión POS.',
        );
      }
      await _sendNetwork(bytes, config);
    }
  }

  /// Detecta puertos disponibles para la impresora POS.
  /// - Linux: /dev/usb/lp* y puertos serie (ttyUSB*, ttyS*)
  /// - Windows: COM* y nombres de impresoras compartidas
  static Future<List<String>> detectUsbPorts() async {
    final ports = <String>{};

    try {
      ports.addAll(SerialPort.getAvailablePorts());
    } catch (_) {}

    if (Platform.isLinux) {
      try {
        final dir = Directory('/dev/usb');
        if (await dir.exists()) {
          await for (final entry in dir.list()) {
            final path = entry.path;
            if (path.startsWith('/dev/usb/lp')) {
              ports.add(path);
            }
          }
        }
      } catch (_) {}
    }

    if (Platform.isWindows) {
      // Detectar impresoras locales instaladas (para Write-Printer)
      try {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Get-CimInstance Win32_Printer | '
              'Where-Object { \$_.Local -and \$_.DeviceName } | '
              'ForEach-Object { "IMPRESORA: \$(\$_.Name)" }',
        ], runInShell: true);
        if (result.exitCode == 0) {
          for (final line in result.stdout.toString().split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty && trimmed.startsWith('IMPRESORA:')) {
              ports.add(trimmed.substring('IMPRESORA: '.length).trim());
            }
          }
        }
      } catch (_) {}

      // Detectar impresoras compartidas (para copy /b)
      try {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Get-CimInstance Win32_Printer | '
              'Where-Object { \$_.Shared } | '
              'ForEach-Object { "COMPARTIDA: \$(\$_.ShareName)" }',
        ], runInShell: true);
        if (result.exitCode == 0) {
          for (final line in result.stdout.toString().split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty && trimmed.startsWith('COMPARTIDA:')) {
              ports.add(
                '\\\\localhost\\${trimmed.substring('COMPARTIDA: '.length)}',
              );
            }
          }
        }
      } catch (_) {}
    }

    return ports.toList();
  }

  Future<void> printInvoice(Invoice invoice, List<InvoiceItem> items) async {
    try {
      final config = await _loadConfig();
      final gen = await _getGenerator(config);
      final company = await _loadCompanyConfig();
      final bytes = _buildInvoiceBytes(gen, company, invoice, items);
      await _routeBytes(bytes, config);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Error al imprimir factura: $e',
        technical: e.toString(),
      );
    }
  }

  Future<void> printQuote(Quote quote, List<QuoteItem> items) async {
    try {
      final config = await _loadConfig();
      final gen = await _getGenerator(config);
      final company = await _loadCompanyConfig();
      final bytes = _buildQuoteBytes(gen, company, quote, items);
      await _routeBytes(bytes, config);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Error al imprimir cotización: ${e.runtimeType}',
        technical: e.toString(),
      );
    }
  }

  Future<void> printTest() async {
    final config = await _loadConfig();
    final gen = await _getGenerator(config);

    final bytes = _buildTestBytes(gen);
    await _routeBytes(bytes, config);
  }

  List<int> _buildInvoiceBytes(
    Generator gen,
    _CompanyConfig company,
    Invoice invoice,
    List<InvoiceItem> items,
  ) {
    var bytes = <int>[];
    final docNum = invoice.id != null
        ? '#${invoice.id.toString().padLeft(4, '0')}'
        : '';
    bytes += _companyHeaderBytes(gen, company);
    bytes += _documentHeaderBytes(
      gen,
      'FACTURA',
      docNum,
      invoice.createdAt,
      invoice.customerName,
    );
    bytes += _itemsHeaderBytes(gen);
    for (final item in items) {
      bytes += _itemRowBytes(
        gen,
        item.productName,
        item.quantity,
        item.unitPrice,
        item.discountItem,
        item.subtotal,
      );
    }
    bytes += _totalsBytes(
      gen,
      invoice.subtotal,
      invoice.discountGlobal,
      invoice.total,
    );
    bytes += _footerBytes(gen, company);
    bytes += gen.cut();
    return bytes;
  }

  List<int> _buildQuoteBytes(
    Generator gen,
    _CompanyConfig company,
    Quote quote,
    List<QuoteItem> items,
  ) {
    var bytes = <int>[];
    final docNum = quote.id != null
        ? '#${quote.id.toString().padLeft(4, '0')}'
        : '';
    bytes += _companyHeaderBytes(gen, company);
    bytes += _documentHeaderBytes(
      gen,
      'COTIZACIÓN',
      docNum,
      quote.createdAt,
      quote.customerName,
    );
    if (quote.expiresAt != null && quote.expiresAt!.isNotEmpty) {
      String expires;
      try {
        expires = DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.parse(quote.expiresAt!));
      } catch (_) {
        expires = quote.expiresAt!;
      }
      bytes += gen.text(
        'Válida hasta:  $expires',
        styles: const PosStyles(align: PosAlign.left),
      );
    }
    bytes += _itemsHeaderBytes(gen);
    for (final item in items) {
      bytes += _itemRowBytes(
        gen,
        item.productName,
        item.quantity,
        item.unitPrice,
        item.discountItem,
        item.subtotal,
      );
    }
    bytes += _totalsBytes(
      gen,
      quote.subtotal,
      quote.discountGlobal,
      quote.total,
    );
    bytes += _footerBytes(gen, company);
    bytes += gen.cut();
    return bytes;
  }

  List<int> _buildTestBytes(Generator gen) {
    var bytes = <int>[];
    bytes += gen.setStyles(const PosStyles(
      align: PosAlign.center,
      codeTable: 'CP1252',
    ));
    bytes += gen.text(
      'IMPRESIÓN DE PRUEBA',
      styles: const PosStyles(
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += gen.feed(1);
    bytes += gen.hr();
    bytes += gen.text('Si puedes leer esto, la impresora');
    bytes += gen.text('funciona correctamente.');
    bytes += gen.feed(1);
    bytes += gen.hr(ch: '=');
    bytes += gen.setStyles(const PosStyles());
    bytes += gen.text('Anthony Design - POS');
    bytes += gen.text(
      'Fecha: ${DateFormat('dd/MM/yyyy   HH:mm').format(DateTime.now())}',
    );
    bytes += gen.feed(2);
    bytes += gen.cut();
    return bytes;
  }

  List<int> _companyHeaderBytes(Generator gen, _CompanyConfig company) {
    var bytes = <int>[];
    bytes += gen.setStyles(const PosStyles(
      align: PosAlign.center,
      codeTable: 'CP1252',
    ));
    bytes += gen.feed(1);
    bytes += gen.text(
      _sanitizeText(company.companyName),
      styles: const PosStyles(
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        align: PosAlign.center,
      ),
    );
    bytes += gen.feed(1);
    if (company.companyAddress.isNotEmpty) {
      bytes += gen.text(
        _sanitizeText(company.companyAddress),
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (company.companyPhone.isNotEmpty) {
      bytes += gen.text(
        'Tel: ${_sanitizeText(company.companyPhone)}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (company.companyEmail.isNotEmpty) {
      bytes += gen.text(
        _sanitizeText(company.companyEmail),
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += gen.setStyles(const PosStyles());
    bytes += gen.feed(1);
    return bytes;
  }

  List<int> _documentHeaderBytes(
    Generator gen,
    String docType,
    String docNumber,
    String createdAt,
    String? customerName,
  ) {
    var bytes = <int>[];
    bytes += gen.hr(ch: '=');
    bytes += gen.feed(1);
    final abbr = docType == 'COTIZACIÓN' ? 'C.' : 'F.';
    final number = docNumber.replaceAll('#', '');
    if (number.isNotEmpty) {
      bytes += gen.text(
        '$abbr No: $number',
        styles: const PosStyles(bold: true, align: PosAlign.left),
      );
    }
    String safeDate;
    String safeTime;
    try {
      final dt = DateTime.parse(createdAt);
      safeDate = DateFormat('dd/MM/yyyy').format(dt);
      safeTime = DateFormat('HH:mm').format(dt);
    } catch (_) {
      safeDate = createdAt.isNotEmpty ? createdAt : '--/--/----';
      safeTime = '--:--';
    }
    final date = safeDate;
    final time = safeTime;
    bytes += gen.text(
      'Fecha:  $date  $time',
      styles: const PosStyles(align: PosAlign.left),
    );
    if (customerName != null && customerName.isNotEmpty) {
      bytes += gen.text(
        'Cliente:  ${_sanitizeText(customerName)}',
        styles: const PosStyles(align: PosAlign.left),
      );
    }
    bytes += gen.feed(1);
    return bytes;
  }

  List<int> _itemsHeaderBytes(Generator gen) {
    var bytes = <int>[];
    bytes += gen.row([
      PosColumn(
        text: 'CTD',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
      PosColumn(
        text: 'DESCRIPCIÓN',
        width: 5,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'P/U',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: 'TOTAL',
        width: 3,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += gen.hr();
    return bytes;
  }

  List<int> _itemRowBytes(
    Generator gen,
    String productName,
    int quantity,
    double unitPrice,
    double discountItem,
    double subtotal,
  ) {
    var bytes = <int>[];
    final currency = _currency();
    final sanitized = _sanitizeText(productName);
    final truncatedName = sanitized.length > 15
        ? '${sanitized.substring(0, 14)}.'
        : sanitized;
    bytes += gen.row([
      PosColumn(
        text: _qty().format(quantity),
        width: 2,
        styles: const PosStyles(align: PosAlign.center),
      ),
      PosColumn(text: truncatedName, width: 5),
      PosColumn(
        text: currency.format(unitPrice),
        width: 2,
        styles: const PosStyles(align: PosAlign.right),
      ),
      PosColumn(
        text: currency.format(subtotal),
        width: 3,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (discountItem > 0) {
      bytes += gen.text(
        '  Desc. ${discountItem.toStringAsFixed(0)}%',
        styles: const PosStyles(align: PosAlign.right),
      );
    }
    return bytes;
  }

  List<int> _totalsBytes(
    Generator gen,
    double subtotal,
    double discountGlobal,
    double total,
  ) {
    var bytes = <int>[];
    final currency = _currency();
    bytes += gen.hr();
    bytes += gen.row([
      PosColumn(
        text: 'Subtotal',
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
      PosColumn(
        text: currency.format(subtotal),
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (discountGlobal > 0) {
      bytes += gen.row([
        PosColumn(
          text: 'Descuento',
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: '-${currency.format(discountGlobal)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += gen.row([
      PosColumn(text: '', width: 8),
      PosColumn(
        text: '----------------',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += gen.row([
      PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: currency.format(total),
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += gen.feed(1);
    return bytes;
  }

  List<int> _footerBytes(Generator gen, _CompanyConfig company) {
    var bytes = <int>[];
    bytes += gen.hr(ch: '=');
    bytes += gen.setStyles(const PosStyles(align: PosAlign.center));
    bytes += gen.feed(1);
    bytes += gen.text(
      _sanitizeText(company.footerMessage),
      styles: const PosStyles(align: PosAlign.center),
    );
    if (company.footerTerms.isNotEmpty) {
      bytes += gen.feed(1);
      bytes += gen.text(
        _sanitizeText(company.footerTerms),
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += gen.setStyles(const PosStyles());
    bytes += gen.feed(3);
    return bytes;
  }
}

class _CompanyConfig {
  final String companyName;
  final String companyPhone;
  // final String companyRnc; // RNC deshabilitado
  final String companyAddress;
  final String companyEmail;
  final String footerMessage;
  final String footerTerms;

  const _CompanyConfig({
    required this.companyName,
    required this.companyPhone,
    // required this.companyRnc, // RNC deshabilitado
    required this.companyAddress,
    required this.companyEmail,
    required this.footerMessage,
    required this.footerTerms,
  });
}
