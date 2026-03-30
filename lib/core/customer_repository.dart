import 'database.dart';
import 'app_exception.dart';
import '../models/customer.dart';

class CustomerRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Customer>> getAll() async {
    try {
      final db = await _db.database;
      final result = await db.query('customers', orderBy: 'name ASC');
      return result.map(Customer.fromMap).toList();
    } catch (e) {
      throw AppException(
        'No se pudieron cargar los clientes.',
        technical: e.toString(),
      );
    }
  }

  Future<List<Customer>> search(String query) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ? OR rnc LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return result.map(Customer.fromMap).toList();
    } catch (e) {
      throw AppException(
        'Error al buscar clientes.',
        technical: e.toString(),
      );
    }
  }

  Future<Customer?> getById(int id) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return Customer.fromMap(result.first);
    } catch (e) {
      throw AppException(
        'No se pudo obtener el cliente.',
        technical: e.toString(),
      );
    }
  }

  Future<int> save(Customer customer) async {
    try {
      final db = await _db.database;
      return await db.insert('customers', {
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'rnc': customer.rnc,
        'address': customer.address,
        'created_at': customer.createdAt,
      });
    } catch (e) {
      throw AppException(
        'No se pudo guardar el cliente.',
        technical: e.toString(),
      );
    }
  }

  Future<void> update(Customer customer) async {
    try {
      final db = await _db.database;
      await db.update(
        'customers',
        {
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email,
          'rnc': customer.rnc,
          'address': customer.address,
        },
        where: 'id = ?',
        whereArgs: [customer.id],
      );
    } catch (e) {
      throw AppException(
        'No se pudo actualizar el cliente.',
        technical: e.toString(),
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await _db.database;
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw AppException(
        'No se pudo eliminar el cliente.',
        technical: e.toString(),
      );
    }
  }
}
