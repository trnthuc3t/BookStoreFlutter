import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  
  DatabaseService._();

  Database? _database;

  Future<void> initialize() async {
    await database; // Initialize database
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'booksell.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create product table for offline cart
    await db.execute('''
      CREATE TABLE ${AppConstants.productTable} (
        id INTEGER PRIMARY KEY,
        name TEXT,
        description TEXT,
        price INTEGER,
        image TEXT,
        banner TEXT,
        category_id INTEGER,
        category_name TEXT,
        sale INTEGER,
        isFeatured INTEGER,
        info TEXT,
        count INTEGER,
        totalPrice INTEGER,
        priceOneProduct INTEGER
      )
    ''');

    // Create cart table
    await db.execute('''
      CREATE TABLE ${AppConstants.cartTable} (
        id INTEGER PRIMARY KEY,
        product_id INTEGER,
        quantity INTEGER,
        user_email TEXT,
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.productTable} (id)
      )
    ''');
  }

  // Product operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert(
      AppConstants.productTable,
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.productTable);
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.productTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      AppConstants.productTable,
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.productTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cart operations
  Future<int> addToCart(int productId, int quantity, String userEmail) async {
    final db = await database;
    
    // Check if product already in cart
    final existingCart = await db.query(
      AppConstants.cartTable,
      where: 'product_id = ? AND user_email = ?',
      whereArgs: [productId, userEmail],
    );

    if (existingCart.isNotEmpty) {
      // Update quantity
      return await db.update(
        AppConstants.cartTable,
        {'quantity': quantity},
        where: 'product_id = ? AND user_email = ?',
        whereArgs: [productId, userEmail],
      );
    } else {
      // Insert new cart item
      return await db.insert(AppConstants.cartTable, {
        'product_id': productId,
        'quantity': quantity,
        'user_email': userEmail,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems(String userEmail) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, p.name, p.price, p.image, p.sale, p.category_name
      FROM ${AppConstants.cartTable} c
      JOIN ${AppConstants.productTable} p ON c.product_id = p.id
      WHERE c.user_email = ?
    ''', [userEmail]);
  }

  Future<int> updateCartQuantity(int productId, int quantity, String userEmail) async {
    final db = await database;
    return await db.update(
      AppConstants.cartTable,
      {'quantity': quantity},
      where: 'product_id = ? AND user_email = ?',
      whereArgs: [productId, userEmail],
    );
  }

  Future<int> removeFromCart(int productId, String userEmail) async {
    final db = await database;
    return await db.delete(
      AppConstants.cartTable,
      where: 'product_id = ? AND user_email = ?',
      whereArgs: [productId, userEmail],
    );
  }

  Future<int> clearCart(String userEmail) async {
    final db = await database;
    return await db.delete(
      AppConstants.cartTable,
      where: 'user_email = ?',
      whereArgs: [userEmail],
    );
  }

  Future<int> getCartItemCount(String userEmail) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.cartTable} 
      WHERE user_email = ?
    ''', [userEmail]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
