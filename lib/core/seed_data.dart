import 'dart:math';
import 'database.dart';
import 'product_repository.dart';
import 'invoice_repository.dart';
import 'quote_repository.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';

void main() async {
  await DatabaseHelper.initialize();
  
  final productRepo = ProductRepository();
  final invoiceRepo = InvoiceRepository();
  final quoteRepo = QuoteRepository();
  
  final random = Random();
  
  // Lista de productos de ejemplo
  final productNames = [
    ('Laptop HP 15"', 'Electrónica', 25000, 35000),
    ('Mouse Inalámbrico', 'Accesorios', 350, 550),
    ('Teclado Mecánico', 'Accesorios', 1200, 1800),
    ('Monitor 24"', 'Electrónica', 8500, 12000),
    ('Audífonos Bluetooth', 'Audio', 1500, 2500),
    ('USB 32GB', 'Almacenamiento', 200, 350),
    ('Disco SSD 500GB', 'Almacenamiento', 2200, 3200),
    ('Cámara Web HD', 'Electrónica', 1800, 2800),
    ('Impresora Epson', 'Oficina', 4500, 6500),
    ('Papel A4 (500 hojas)', 'Oficina', 180, 280),
    ('Calculadora Científica', 'Oficina', 450, 700),
    ('Organizador de Escritorio', 'Oficina', 350, 550),
    ('Lámpara LED', 'Iluminación', 280, 450),
    ('Cable HDMI 2m', 'Accesorios', 180, 300),
    ('Hub USB 4 puertos', 'Accesorios', 400, 650),
  ];
  
  print('Creando productos...');
  final products = <int>[];
  
  for (final (name, category, purchase, sale) in productNames) {
    final stock = random.nextInt(50) + 10;
    final id = await productRepo.insertRaw(
      name: name,
      category: category,
      purchasePrice: purchase.toDouble(),
      salePrice: sale.toDouble(),
      stock: stock,
      minStock: 5,
    );
    products.add(id);
    print('  - $name (Stock: $stock)');
  }
  
  print('\nGenerando facturas...');
  
  // Generar 8 facturas
  for (int i = 0; i < 8; i++) {
    final customerNames = ['Juan Pérez', 'María García', 'Carlos López', 'Ana Rodríguez', 'Pedro Sánchez', null];
    final customerName = customerNames[random.nextInt(customerNames.length)];
    
    final itemCount = random.nextInt(4) + 1;
    final items = <InvoiceItem>[];
    final selectedProducts = products.toList()..shuffle();
    
    double subtotal = 0;
    
    for (int j = 0; j < itemCount; j++) {
      final productId = selectedProducts[j];
      final productName = productNames.firstWhere((p) => products.indexOf(productId) == productNames.indexOf(p)).$1;
      final quantity = random.nextInt(5) + 1;
      final unitPrice = productNames[products.indexOf(productId)].$3.toDouble();
      final discount = random.nextDouble() * 15;
      final itemSubtotal = (unitPrice * (1 - discount / 100)) * quantity;
      
      items.add(InvoiceItem(
        invoiceId: 0,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        discountItem: discount,
        subtotal: itemSubtotal,
      ));
      
      subtotal += itemSubtotal;
    }
    
    final discountGlobal = random.nextDouble() * 10;
    final total = subtotal * (1 - discountGlobal / 100);
    
    final invoice = Invoice(
      customerName: customerName,
      subtotal: subtotal,
      discountGlobal: discountGlobal,
      total: total,
      createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String(),
    );
    
    await invoiceRepo.save(invoice, items);
    print('  - Factura #${i + 1}: $customerName - RD\$ ${total.toStringAsFixed(0)}');
  }
  
  print('\nGenerando cotizaciones...');
  
  // Generar 5 cotizaciones
  for (int i = 0; i < 5; i++) {
    final customerNames = ['Laura Martínez', 'Roberto Díaz', 'Sofia Hernández', 'Miguel Torres', 'Carmen Ruiz'];
    final customerName = customerNames[i];
    
    final itemCount = random.nextInt(3) + 2;
    final items = <QuoteItem>[];
    final selectedProducts = products.toList()..shuffle();
    
    double subtotal = 0;
    
    for (int j = 0; j < itemCount; j++) {
      final productId = selectedProducts[j];
      final productName = productNames[products.indexOf(productId)].$1;
      final quantity = random.nextInt(3) + 1;
      final unitPrice = productNames[products.indexOf(productId)].$3.toDouble();
      final discount = random.nextDouble() * 10;
      final itemSubtotal = (unitPrice * (1 - discount / 100)) * quantity;
      
      items.add(QuoteItem(
        quoteId: 0,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        discountItem: discount,
        subtotal: itemSubtotal,
      ));
      
      subtotal += itemSubtotal;
    }
    
    final discountGlobal = random.nextDouble() * 5;
    final total = subtotal * (1 - discountGlobal / 100);
    
    final expiresAt = DateTime.now().add(Duration(days: random.nextInt(30) + 1));
    
    final quote = Quote(
      customerName: customerName,
      subtotal: subtotal,
      discountGlobal: discountGlobal,
      total: total,
      createdAt: DateTime.now().subtract(Duration(days: random.nextInt(15))).toIso8601String(),
      expiresAt: expiresAt.toIso8601String(),
    );
    
    await quoteRepo.save(quote, items);
    print('  - Cotización #${i + 1}: $customerName - RD\$ ${total.toStringAsFixed(0)}');
  }
  
  print('\n✅ Datos de prueba generados exitosamente!');
  print('   - 15 productos');
  print('   - 8 facturas');
  print('   - 5 cotizaciones');
}
