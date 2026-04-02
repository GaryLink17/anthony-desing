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

  static int indexFromRoute(String? route) {
    final idx = all.indexOf(route ?? home);
    return idx < 0 ? 0 : idx;
  }

  static String routeFromIndex(int index) {
    if (index < 0 || index >= all.length) return home;
    return all[index];
  }
}
