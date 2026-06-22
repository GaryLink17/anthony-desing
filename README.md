# Anthony Design — Inventario & Facturación

Sistema de inventario y facturación para tienda de ropa, construido con Flutter.

## Funcionalidades

- **Inventario**: gestión de productos con control de stock mínimo.
- **Facturación**: creación, anulación y seguimiento de facturas.
- **Cotizaciones**: presupuestos convertibles a facturas.
- **Reportes**: ventas mensuales, productos más vendidos, rentabilidad.
- **Historial**: registro de cambios en precios de compra y venta.
- **Backup**: exportación e importación de base de datos.
- **Impresión**: PDF y tickets POS (red y serie).
- **Exportación Excel**: inventario, facturas, cotizaciones.

## Requisitos

- Flutter SDK 3.11+
- Windows (MSIX) / Linux / macOS
- Solo desktop: usa `sqflite_common_ffi` (incompatible con web)

## Compilar

```bash
flutter pub get
flutter build windows --release
```

Para empaquetar MSIX:
```bash
dart run msix:create
```

## Stack técnico

| Capa | Tecnología |
|------|-----------|
| UI | Flutter + Material Design |
| Estado | Provider + ChangeNotifier |
| DB | SQLite (`sqflite_common_ffi`) |
| PDF | `pdf` + `printing` |
| POS | `esc_pos_printer_lts` + `libserialport_plus` |
| Excel | `excel` |
| CI/CD | GitHub Actions (build + analyze + test) |

## Moneda

Toda la interfaz usa **RD$** (Peso Dominicano). Centralizado en `lib/utils/currency_config.dart`.
