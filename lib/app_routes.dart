/// Definición centralizada de rutas de navegación de la aplicación.
///
/// Mapea nombres de ruta a índices del menú lateral y viceversa.
class AppRoutes {
  static const home = '/home';
  static const invoices = '/invoices';
  static const quotes = '/quotes';
  static const inventory = '/inventory';
  static const reports = '/reports';
  static const history = '/history';
  static const settings = '/settings';

  static const all = [
    home,
    invoices,
    quotes,
    inventory,
    reports,
    history,
    settings,
  ];

  /// Retorna el índice del menú lateral correspondiente a una ruta.
  static int indexFromRoute(String? route) {
    final idx = all.indexOf(route ?? home);
    return idx < 0 ? 0 : idx;
  }

  /// Retorna la ruta correspondiente a un índice del menú lateral.
  static String routeFromIndex(int index) {
    if (index < 0 || index >= all.length) return home;
    return all[index];
  }
}
