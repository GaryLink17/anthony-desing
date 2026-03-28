/// Excepción personalizada de la aplicación.
///
/// Separa el mensaje que ve el usuario del detalle técnico interno.
/// Todos los repositorios lanzan este tipo de excepción en lugar de
/// dejar que los errores crudos de SQLite lleguen hasta la UI.
class AppException implements Exception {
  /// Mensaje legible para mostrar al usuario.
  final String message;

  /// Detalle técnico original (para debugging). Nunca se muestra al usuario.
  final String? technical;

  const AppException(this.message, {this.technical});

  @override
  String toString() => 'AppException: $message${technical != null ? ' ($technical)' : ''}';
}
