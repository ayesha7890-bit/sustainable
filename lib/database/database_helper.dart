import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sustainable_living.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // version 1 -> 2 kyunki education_hub table baad mein add hui
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Jab existing users ki DB purani version pe ho, ye missing tables bana dega
  // bina unka purana data delete kiye.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS education_hub (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          subtitle TEXT,
          description TEXT NOT NULL,
          image_url TEXT
        )
      ''');
    }
  }

  // Yahan Admin ke saare zaroori tables bante hain
  Future _createDB(Database db, int version) async {
    // 1. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // 2. Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        image_url TEXT
      )
    ''');

    // 3. Challenges Table
    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        duration_days INTEGER NOT NULL,
        points INTEGER NOT NULL
      )
    ''');

    // 4. Energy & Green Tips Table
    await db.execute('''
      CREATE TABLE tips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    // 5. Education & Certifications Hub Table
    await db.execute('''
      CREATE TABLE education_hub (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,         -- 'Article' ya 'Certification' store hoga
        title TEXT NOT NULL,        -- Article ka naam ya Certificate ka naam
        subtitle TEXT,              -- Article ka author/category ya Certificate ki Organization
        description TEXT NOT NULL,  -- Article ki details ya Certificate ka matlab
        image_url TEXT              -- Article ki cover photo ya Certificate ka Logo
      )
    ''');

    //RECIPS
    await db.execute('''
  CREATE TABLE recipes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    ingredients TEXT NOT NULL,
    instructions TEXT NOT NULL,
    is_plant_based INTEGER DEFAULT 1
  )
''');
    await db.execute('''
  CREATE TABLE travel_tips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT NOT NULL, -- 'Travel', 'Energy', or 'Waste'
    title TEXT NOT NULL,
    description TEXT NOT NULL
  )
''');
  }
  //travel
  Future<int> insertTravelTip(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('travel_tips', row);
  }

  Future<List<Map<String, dynamic>>> fetchTravelTips() async {
    Database db = await instance.database;
    return await db.query('travel_tips');
  }

  Future<int> deleteTravelTip(int id) async {
    Database db = await instance.database;
    return await db.delete('travel_tips', where: 'id = ?', whereArgs: [id]);
  }

  // Recipes insert karne ke liye
  Future<int> insertRecipe(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('recipes', row);
  }

// Recipes fetch/load karne ke liye
  Future<List<Map<String, dynamic>>> fetchRecipes() async {
    Database db = await instance.database;
    return await db.query('recipes');
  }

// Recipe delete karne ke liye
  Future<int> deleteRecipe(int id) async {
    Database db = await instance.database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // --- 📑 CATEGORIES CRUD OPERATIONS ---
  // ==========================================


  Future<int> insertCategory(String name) async {
    final db = await instance.database;
    return await db.insert('categories', {'name': name});
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final db = await instance.database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<int> updateCategory(int id, String name) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> categoryExists(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
    );
    return result.isNotEmpty;
  }

  // ==========================================
  // --- 🎓 EDUCATION & CERTIFICATIONS CRUD ---
  // ==========================================

  Future<int> insertEducationItem(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('education_hub', row);
  }

  Future<List<Map<String, dynamic>>> fetchEducationItems() async {
    final db = await instance.database;
    return await db.query('education_hub', orderBy: 'id DESC');
  }

  Future<int> deleteEducationItem(int id) async {
    final db = await instance.database;
    return await db.delete('education_hub', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // --- 🛒 PRODUCTS CRUD OPERATIONS ---
  // ==========================================

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC'); // Naya product sabsay upar dikhane ke liye
  }

  // Naya add kiya gaya function (Product Edit karne ke liye)
  Future<int> updateProduct(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'products',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // --- 🎯 CHALLENGES CRUD OPERATIONS ---
  // ==========================================

  Future<int> insertChallenge(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('challenges', row);
  }

  Future<List<Map<String, dynamic>>> fetchChallenges() async {
    final db = await instance.database;
    return await db.query('challenges', orderBy: 'id DESC');
  }

  Future<int> deleteChallenge(int id) async {
    final db = await instance.database;
    return await db.delete('challenges', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // --- 💡 GREEN TIPS CRUD OPERATIONS ---
  // ==========================================

  Future<int> insertTip(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('tips', row);
  }

  Future<List<Map<String, dynamic>>> fetchTips() async {
    final db = await instance.database;
    return await db.query('tips', orderBy: 'id DESC');
  }

  Future<int> deleteTip(int id) async {
    final db = await instance.database;
    return await db.delete('tips', where: 'id = ?', whereArgs: [id]);
  }

  // Database close karne ke liye
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}