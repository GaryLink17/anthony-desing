import 'package:shared_preferences/shared_preferences.dart';

/// Configuración de la impresora térmica POS.
class ThermalPrinterConfig {
  final String connectionType; // 'network' | 'usb'
  final String ipAddress;
  final int port;
  final String usbPortName;
  final int paperWidthMM;
  final bool enabled;

  const ThermalPrinterConfig({
    this.connectionType = 'network',
    this.ipAddress = '',
    this.port = 9100,
    this.usbPortName = '',
    this.paperWidthMM = 80,
    this.enabled = false,
  });

  static const _keyConnectionType = 'thermal_printer_connection_type';
  static const _keyIp = 'thermal_printer_ip';
  static const _keyPort = 'thermal_printer_port';
  static const _keyUsbPortName = 'thermal_printer_usb_port_name';
  static const _keyPaperWidth = 'thermal_printer_paper_width';
  static const _keyEnabled = 'thermal_printer_enabled';

  ThermalPrinterConfig copyWith({
    String? connectionType,
    String? ipAddress,
    int? port,
    String? usbPortName,
    int? paperWidthMM,
    bool? enabled,
  }) {
    return ThermalPrinterConfig(
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      usbPortName: usbPortName ?? this.usbPortName,
      paperWidthMM: paperWidthMM ?? this.paperWidthMM,
      enabled: enabled ?? this.enabled,
    );
  }

  factory ThermalPrinterConfig.fromPrefs(SharedPreferences prefs) {
    return ThermalPrinterConfig(
      connectionType: prefs.getString(_keyConnectionType) ?? 'network',
      ipAddress: prefs.getString(_keyIp) ?? '',
      port: prefs.getInt(_keyPort) ?? 9100,
      usbPortName: prefs.getString(_keyUsbPortName) ?? '',
      paperWidthMM: prefs.getInt(_keyPaperWidth) ?? 80,
      enabled: prefs.getBool(_keyEnabled) ?? false,
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setString(_keyConnectionType, connectionType);
    await prefs.setString(_keyIp, ipAddress);
    await prefs.setInt(_keyPort, port);
    await prefs.setString(_keyUsbPortName, usbPortName);
    await prefs.setInt(_keyPaperWidth, paperWidthMM);
    await prefs.setBool(_keyEnabled, enabled);
  }
}
