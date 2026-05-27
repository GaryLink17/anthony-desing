/// Excepción personalizada de la aplicación.
///
/// Separa el mensaje que ve el usuario del detalle técnico interno.
/// Todos los repositorios lanzan este tipo de excepción en lugar de
/// dejar que los errores crudos de SQLite lleguen hasta la UI.
/// Excepción personalizada de la aplicación.
/// Separa el mensaje para el usuario (message) del detalle técnico (technical)
/// para no exponer errores internos en la UI.
class AppException implements Exception {
  final String message;
  final String? technical;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.technical, this.stackTrace});

  @override
  String toString() => 'AppException: $message${technical != null ? ' ($technical)' : ''}';
}
