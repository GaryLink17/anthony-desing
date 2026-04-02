import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_y_facturacion/app_routes.dart';

void main() {
  test('mapea índice y ruta de forma estable', () {
    expect(AppRoutes.routeFromIndex(0), AppRoutes.home);
    expect(AppRoutes.routeFromIndex(1), AppRoutes.invoices);
    expect(AppRoutes.indexFromRoute(AppRoutes.settings), 6);
    expect(AppRoutes.indexFromRoute('/no-existe'), 0);
  });
}
