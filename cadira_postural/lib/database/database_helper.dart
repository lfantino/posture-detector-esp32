import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DatabaseHelper {
  // Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const _dbName = 'sensorflow.db';
  static const _dbVersion = 1;
  static const tableUsuaris = 'usuaris';

  // ─── Getters ───────────────────────────────────────────────────────────────

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // ─── Inicialització ────────────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    // En Windows/Linux/macOS cal usar sqflite_common_ffi
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUsuaris (
        id       TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email    TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ─── Operacions ────────────────────────────────────────────────────────────

  /// Registra un nou usuari. Retorna null si tot va bé,
  /// o un missatge d'error si l'usuari o email ja existeixen.
  Future<String?> registrarUsuari({
    required String username,
    required String email,
    required String password,
  }) async {
    final db = await database;

    // Comprovar si el nom d'usuari ja existeix
    final existsUsername = await db.query(
      tableUsuaris,
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (existsUsername.isNotEmpty) {
      return "El nom d'usuari ja està en ús.";
    }

    // Comprovar si el correu ja existeix
    final existsEmail = await db.query(
      tableUsuaris,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (existsEmail.isNotEmpty) {
      return 'El correu electrònic ja està registrat.';
    }

    // Inserir el nou usuari
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await db.insert(tableUsuaris, {
      'id': const Uuid().v4(),
      'username': username.trim().toLowerCase(),
      'email': email.trim().toLowerCase(),
      'password': password, // En producció: usar bcrypt o similar
      'created_at': now,
    });

    return null; // Èxit
  }

  /// Fa login. Retorna el Map de l'usuari si les credencials són correctes,
  /// o null si no coincideixen.
  Future<Map<String, dynamic>?> loginUsuari({
    required String username,
    required String password,
  }) async {
    final db = await database;

    final result = await db.query(
      tableUsuaris,
      where: 'username = ? AND password = ?',
      whereArgs: [username.trim().toLowerCase(), password],
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  /// Obté les dades d'un usuari pel seu ID.
  Future<Map<String, dynamic>?> obtenirUsuari(String id) async {
    final db = await database;
    final result = await db.query(
      tableUsuaris,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Tanca la connexió (per a tests o reinicis).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
