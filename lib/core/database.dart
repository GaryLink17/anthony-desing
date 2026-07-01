import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Helper singleton para manejar la base de datos SQLite.
/// Proporciona inicialización, creación y migración de esquema.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _dbFuture;
  static bool _initialized = false;

  /// Nombre del archivo de base de datos.
  static const String dbName = 'inventario.db';
  static const String _oldDbName = 'control_gastos.db';

  DatabaseHelper._init();

  /// Inicializa el motor FFI de SQLite (necesario en Windows/desktop).
  /// Solo debe llamarse una vez.
  /// Lanza [UnsupportedError] si se ejecuta en web.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      throw UnsupportedError('Web no soportado. Usa la versión de escritorio.');
    }
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _initialized = true;
  }

  /// Obtiene la instancia de la base de datos, creándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _dbFuture ??= _initDB(dbName);
    _database = await _dbFuture;
    return _database!;
  }

  /// Abre (o crea) la base de datos en el directorio de soporte de la app.
  Future<Database> _initDB(String fileName) async {
    await initialize();

    final appDir = await getApplicationSupportDirectory();
    final path = join(appDir.path, fileName);

    // Migrar desde el nombre antiguo si existe
    final oldPath = join(appDir.path, _oldDbName);
    final oldFile = File(oldPath);
    if (await oldFile.exists() && !await File(path).exists()) {
      await oldFile.rename(path);
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');
        },
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
          address TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      // v6: Agrega columna rnc a customers (schema drift entre _createDB y _upgradeDB v5)
      await db.execute('ALTER TABLE customers ADD COLUMN rnc TEXT');
    }
    if (oldVersion < 7) {
      // v7: Índices para rendimiento con >10k registros
      await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_created_status ON invoices(created_at, status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_customer_name ON invoices(customer_name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON invoice_items(invoice_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_stock_min ON products(stock, min_stock)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_quotes_created ON quotes(created_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_quotes_customer_name ON quotes(customer_name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_quote_items_quote_id ON quote_items(quote_id)');
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

    // Índices para rendimiento
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_created_status ON invoices(created_at, status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoices_customer_name ON invoices(customer_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON invoice_items(invoice_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_stock_min ON products(stock, min_stock)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quotes_created ON quotes(created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quotes_customer_name ON quotes(customer_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quote_items_quote_id ON quote_items(quote_id)');
  }

  /// Cierra la conexión y reinicia el estado interno de la base de datos.
  /// NO reinicia _initialized porque sqfliteFfiInit() solo debe llamarse una vez.
  static Future<void> closeAndReset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _dbFuture = null;
  }

  /// Hace checkpoint del WAL y copia el archivo de BD a [destPath] sin cerrar la conexión.
  /// La base de datos permanece abierta y operativa durante la copia.
  /// Retorna true si la copia fue exitosa.
  static Future<bool> copyDatabaseFile(String destPath) async {
    try {
      final db = await instance.database;
      // Forzar checkpoint para volcar WAL al archivo principal
      await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      final appDir = await getApplicationSupportDirectory();
      final sourcePath = join(appDir.path, dbName);
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return false;
      await sourceFile.copy(destPath);
      return true;
    } catch (e) {
      debugPrint('copyDatabaseFile: $e');
      return false;
    }
  }
}
