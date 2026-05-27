import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Helper singleton para manejar la base de datos SQLite.
/// Proporciona inicialización, creación y migración de esquema.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;

  DatabaseHelper._init();

  /// Inicializa el motor FFI de SQLite (necesario en Windows/desktop).
  /// Solo debe llamarse una vez.
  static Future<void> initialize() async {
    if (_initialized) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _initialized = true;
  }

  /// Obtiene la instancia de la base de datos, creándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('control_gastos.db');
    return _database!;
  }

  /// Abre (o crea) la base de datos en el directorio de soporte de la app.
  Future<Database> _initDB(String fileName) async {
    await initialize();

    final appDir = await getApplicationSupportDirectory();
    final path = join(appDir.path, fileName);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  /// Migraciones progresivas de esquema de base de datos.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: Agrega columna status a invoices, crea tablas quotes y quote_items
      await db.execute(
        "ALTER TABLE invoices ADD COLUMN status TEXT DEFAULT 'active'",
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quotes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_name TEXT,
        subtotal REAL NOT NULL,
        discount_global REAL DEFAULT 0,
        total REAL NOT NULL,
          created_at TEXT NOT NULL,
          expires_at TEXT,
          is_converted INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quote_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quote_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          discount_item REAL DEFAULT 0,
          subtotal REAL NOT NULL,
          FOREIGN KEY (quote_id) REFERENCES quotes(id),
          FOREIGN KEY (product_id) REFERENCES products(id)
        )
      ''');
    }
    if (oldVersion < 3) {
      // v3: Agrega columna payment_status a invoices
      await db.execute(
        "ALTER TABLE invoices ADD COLUMN payment_status TEXT DEFAULT 'pending'",
      );
    }
    if (oldVersion < 5) {
      // v5: Crea tabla de clientes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          rnc TEXT,
          address TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      // v6: Agrega RNC del cliente a facturas y cotizaciones
      await db.execute(
        'ALTER TABLE invoices ADD COLUMN customer_rnc TEXT',
      );
      await db.execute(
        'ALTER TABLE quotes ADD COLUMN customer_rnc TEXT',
      );
    }
  }

  /// Crea todas las tablas desde cero (base nueva).
  Future _createDB(Database db, int version) async {
    // Tabla de productos del inventario
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        purchase_price REAL NOT NULL,
        sale_price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 5,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabla de facturas (cabecera)
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT,
        customer_rnc TEXT,
        subtotal REAL NOT NULL,
        discount_global REAL DEFAULT 0,
        total REAL NOT NULL,
        status TEXT DEFAULT 'active',
        payment_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    // Tabla de líneas de factura (detalle: productos en cada factura)
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        discount_item REAL DEFAULT 0,
        subtotal REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Tabla de cotizaciones (cabecera)
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT,
        customer_rnc TEXT,
        subtotal REAL NOT NULL,
        discount_global REAL DEFAULT 0,
        total REAL NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT,
        is_converted INTEGER DEFAULT 0
      )
    ''');

    // Tabla de líneas de cotización (detalle)
    await db.execute('''
      CREATE TABLE quote_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        discount_item REAL DEFAULT 0,
        subtotal REAL NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Tabla de clientes
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        rnc TEXT,
        address TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Cierra la conexión y reinicia el estado interno de la base de datos.
  /// NO reinicia _initialized porque sqfliteFfiInit() solo debe llamarse una vez.
  static Future<void> closeAndReset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
