import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;

  DatabaseHelper._init();

  static Future<void> initialize() async {
    if (_initialized) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('control_gastos.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    await initialize();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
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
  }

  Future _createDB(Database db, int version) async {
    // Tabla de productos
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

    // Tabla de facturas
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT,
        subtotal REAL NOT NULL,
        discount_global REAL DEFAULT 0,
        total REAL NOT NULL,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL
      )
    ''');

    // Tabla de líneas de factura (qué productos tiene cada factura)
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

    // Tabla de cotizaciones
    await db.execute('''
      CREATE TABLE quotes (
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

    // Tabla de líneas de cotización
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
  }
}
