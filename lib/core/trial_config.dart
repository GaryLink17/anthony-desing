/// Configuración de la versión de prueba.
/// Para activar la versión completa, cambiar [isTrialVersion] a false.
class TrialConfig {
  TrialConfig._();

  // ── Activa o desactiva el modo de prueba ─────────────────────────────────
  static const bool isTrialVersion = true;

  // ── Límites de registros ─────────────────────────────────────────────────
  static const int maxProducts = 10;
  static const int maxInvoices = 10;
  static const int maxQuotes = 5;

  // ── Funciones habilitadas/deshabilitadas ─────────────────────────────────
  static const bool excelExportEnabled = false;
  static const bool backupEnabled = false;
  static const bool logoUploadEnabled = false;
  static const bool pdfWatermarkEnabled = true;
  static const bool reportDateRangeEnabled = false;

  // ── Texto de aviso ────────────────────────────────────────────────────────
  static const String upgradeMessage = 'Disponible en la versión completa';
}
