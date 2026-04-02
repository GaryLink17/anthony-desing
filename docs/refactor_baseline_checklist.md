# Checklist de regresión y línea base

## Regresión manual (antes y después de cada fase)

- Crear factura con 2+ productos y validar total.
- Editar factura y confirmar que preserva `RNC`, `ITBIS`, `ISR`, `status`, `paymentStatus`.
- Anular factura y verificar restitución de stock.
- Crear cotización, editar y convertir a factura.
- Generar e imprimir PDF de factura y cotización.
- Exportar facturas e inventario a Excel.
- Ejecutar backup y restore de datos.
- Cambiar tema claro/oscuro y validar navegación.

## Métricas base sugeridas

- Tiempo de carga dashboard (`AppProvider.loadDashboard`).
- Tiempo de apertura de pantalla de facturas.
- Tiempo de apertura de pantalla de cotizaciones.
- Tiempo de generación de PDF.

## Criterio de aceptación por fase

- Sin errores de linter.
- Pruebas unitarias en verde.
- Flujo de regresión manual completado sin fallos críticos.
