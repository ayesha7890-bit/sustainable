import 'dart:math';
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
      version: 5, // 🚀 Version updated to 5 to handle new Recipe fields cleanly
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Creates new tables or alters existing ones on database upgrade without deleting old data
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
    if (oldVersion < 3) {
      // 1. User Carbon Footprint Tracking Logs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS carbon_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          transport_co2 REAL NOT NULL,
          energy_co2 REAL NOT NULL,
          waste_co2 REAL NOT NULL,
          total_co2 REAL NOT NULL
        )
      ''');

      // 2. User Waste Recycling Tracker Logs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS waste_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          total_waste_kg REAL NOT NULL,
          recycling_kg REAL NOT NULL,
          compost_kg REAL NOT NULL
        )
      ''');

      // 3. Track which challenges are completed by the user
      await db.execute('''
        CREATE TABLE IF NOT EXISTS completed_challenges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          challenge_id INTEGER NOT NULL,
          completed_at TEXT NOT NULL
        )
      ''');
    }

    // 💡 AUTOMATIC UPGRADE FOR FORUM TABLE
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS forum_posts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          author TEXT NOT NULL,
          content TEXT NOT NULL,
          likes INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }

    // 🚀 AUTOMATIC UPGRADE FOR RECIPES TABLE (Version 5)
    // Purane users ke app mein tables ko delete kiye bina ye naye columns dynamically add ho jayenge
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE recipes ADD COLUMN category TEXT;");
        await db.execute("ALTER TABLE recipes ADD COLUMN carbon_impact TEXT;");
        await db.execute("ALTER TABLE recipes ADD COLUMN prep_time TEXT;");
        await db.execute("ALTER TABLE recipes ADD COLUMN ingredients_csv TEXT;");
        await db.execute("ALTER TABLE recipes ADD COLUMN instructions_csv TEXT;");
        await db.execute("ALTER TABLE recipes ADD COLUMN eco_benefit TEXT;");
        await db.execute("ALTER TABLE recipes ADD COLUMN icon_name TEXT;");
      } catch (e) {
        // If columns already exist, prevent app crash on dynamic re-runs
        print("Upgrade warning/info: $e");
      }
    }
  }

  // Creates all tables at once when the app is first launched
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        duration_days INTEGER NOT NULL,
        points INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE education_hub (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        description TEXT NOT NULL,
        image_url TEXT
      )
    ''');

    // 🎯 Fully Updated Recipes Table Schema for Fresh Installs
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT,
        carbon_impact TEXT,
        prep_time TEXT,
        ingredients_csv TEXT,
        instructions_csv TEXT,
        eco_benefit TEXT,
        icon_name TEXT,
        is_plant_based INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE travel_tips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE carbon_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        transport_co2 REAL NOT NULL,
        energy_co2 REAL NOT NULL,
        waste_co2 REAL NOT NULL,
        total_co2 REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE waste_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_waste_kg REAL NOT NULL,
        recycling_kg REAL NOT NULL,
        compost_kg REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE completed_challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenge_id INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    // 💡 New Community Forum Table for fresh installs
    await db.execute('''
      CREATE TABLE forum_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        content TEXT NOT NULL,
        likes INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ==========================================
  // 🔥 NEW USER-SIDE CRUD METHODS (V3 & V4)
  // ==========================================

  // --- 💬 Community Forum Methods (NEW) ---
  Future<int> insertForumPost(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('forum_posts', row);
  }

  Future<List<Map<String, dynamic>>> getForumPosts() async {
    final db = await instance.database;
    return await db.query('forum_posts', orderBy: 'id DESC');
  }

  Future<int> likeForumPost(int id, int currentLikes) async {
    final db = await instance.database;
    return await db.update(
      'forum_posts',
      {'likes': currentLikes + 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- 📊 Carbon Logs Methods ---
  Future<int> insertCarbonLog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('carbon_logs', row);
  }

  Future<List<Map<String, dynamic>>> getCarbonLogs() async {
    final db = await instance.database;
    return await db.query('carbon_logs', orderBy: 'id DESC');
  }

  // --- 🗑️ Waste Logs Methods ---
  Future<int> insertWasteLog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('waste_logs', row);
  }

  Future<List<Map<String, dynamic>>> getWasteLogs() async {
    final db = await instance.database;
    return await db.query('waste_logs', orderBy: 'id DESC');
  }

  // --- 🎯 Completed Challenges Track Methods ---
  Future<int> completeChallenge(int challengeId, String date) async {
    final db = await instance.database;
    return await db.insert('completed_challenges', {
      'challenge_id': challengeId,
      'completed_at': date,
    });
  }

  Future<List<Map<String, dynamic>>> fetchCompletedChallenges() async {
    final db = await instance.database;
    return await db.query('completed_challenges');
  }

  // ==========================================
  // 🏛️ ADMIN PANEL & OLD CRUD OPERATIONS (EXISTING)
  // ==========================================

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

  Future<int> insertRecipe(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('recipes', row);
  }

  Future<List<Map<String, dynamic>>> fetchRecipes() async {
    Database db = await instance.database;
    return await db.query('recipes');
  }

  Future<int> deleteRecipe(int id) async {
    Database db = await instance.database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

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
    return await db.update('categories', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> categoryExists(String name) async {
    final db = await instance.database;
    final result = await db.query('categories', where: 'LOWER(name) = ?', whereArgs: [name.toLowerCase()]);
    return result.isNotEmpty;
  }

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

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  Future<int> updateProduct(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('products', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}