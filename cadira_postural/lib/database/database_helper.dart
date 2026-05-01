import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DatabaseHelper {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const _dbName = 'sensorflow.db';
  static const _dbVersion = 6; // Incrementat per afegir la taula de configuracio i modificar calibracions

  // ─── Noms de taules ────────────────────────────────────────────────────────
  static const tableUsuaris        = 'usuaris';
  static const tableEstadistiques  = 'estadistiques_dia';
  static const tableCalibracions   = 'calibracions';
  static const tableAlertes        = 'alertes';
  static const tableConfiguracio   = 'configuracio';

  // ─── Getter de la BD ───────────────────────────────────────────────────────
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
      onUpgrade: _onUpgrade,
    );
  }

  // ─── Creació de taules ─────────────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Si s'actualitza des de la versió 1 (només tenia usuaris), afegim les taules noves
    if (oldVersion < 2) {
      await _createPosturalTables(db);
    }
    // Si s'actualitza a la versió 3, afegeix la columna avatar_path
    // Si s'actualitza a la versió 3, afegeix la columna avatar_path
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableUsuaris ADD COLUMN avatar_path TEXT');
    }
    // Si s'actualitza a la versió 4, unifiquem les taules noves que faltaven (company)
    if (oldVersion < 4) {
      await _createPosturalTables(db);
    }
    // Si s'actualitza a la versió 5, afegeix la taula de configuració
    if (oldVersion < 5) {
      await _createConfiguracioTable(db);
    }
    // Si s'actualitza a la versió 6, recreem la taula de calibracions amb la nova estructura
    if (oldVersion < 6) {
      await db.execute('DROP TABLE IF EXISTS $tableCalibracions');
      await _createPosturalTables(db);
    }
  }

  Future<void> _createAllTables(Database db) async {
    await _createUsuarisTable(db);
    await _createPosturalTables(db);
    await _createConfiguracioTable(db);
  }

  Future<void> _createUsuarisTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableUsuaris (
        id         TEXT PRIMARY KEY,
        username   TEXT UNIQUE NOT NULL,
        email      TEXT UNIQUE NOT NULL,
        password   TEXT NOT NULL,
        nom_complet TEXT,
        avatar_color TEXT,
        avatar_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPosturalTables(Database db) async {
    // Taula d'estadístiques diàries (conclusions del posture_control)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableEstadistiques (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        usuari_id            TEXT NOT NULL,
        data                 TEXT NOT NULL,
        temps_correcte_seg   INTEGER NOT NULL DEFAULT 0,
        postura_mitja_percent REAL NOT NULL DEFAULT 0.0,
        total_alertes        INTEGER NOT NULL DEFAULT 0,
        correccions          INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (usuari_id) REFERENCES $tableUsuaris(id),
        UNIQUE(usuari_id, data)
      )
    ''');

    // Taula de calibracions (historial de referències dels sensors)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCalibracions (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        usuari_id           TEXT NOT NULL,
        data_calibracio     TEXT NOT NULL,
        lat_cul             REAL NOT NULL DEFAULT 0.0,
        front_cul           REAL NOT NULL DEFAULT 0.0,
        dist_cerv           REAL NOT NULL DEFAULT 0.0,
        dist_tor            REAL NOT NULL DEFAULT 0.0,
        dist_lumb           REAL NOT NULL DEFAULT 0.0,
        diff_cerv_lumb      REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (usuari_id) REFERENCES $tableUsuaris(id)
      )
    ''');

    // Taula d'alertes (només quan hi ha un problema real, no cada 500ms)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableAlertes (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        usuari_id   TEXT NOT NULL,
        timestamp   TEXT NOT NULL,
        tipus       TEXT NOT NULL,
        missatge    TEXT NOT NULL,
        FOREIGN KEY (usuari_id) REFERENCES $tableUsuaris(id)
      )
    ''');
  }

  Future<void> _createConfiguracioTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableConfiguracio (
        id                         INTEGER PRIMARY KEY AUTOINCREMENT,
        usuari_id                  TEXT NOT NULL UNIQUE,
        notificacions              INTEGER NOT NULL DEFAULT 1,
        objectiu_temps_max_session INTEGER NOT NULL DEFAULT 60,
        last_updated               TEXT NOT NULL,
        FOREIGN KEY (usuari_id) REFERENCES $tableUsuaris(id)
      )
    ''');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CRUD — USUARIS
  // ══════════════════════════════════════════════════════════════════════════

  /// Registra un nou usuari. Retorna null si tot va bé,
  /// o un missatge d'error si l'usuari o email ja existeixen.
  Future<String?> registrarUsuari({
    required String username,
    required String email,
    required String password,
    String? nomComplet,
    String? avatarColor,
  }) async {
    final db = await database;

    final existsUsername = await db.query(
      tableUsuaris,
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (existsUsername.isNotEmpty) return "El nom d'usuari ja està en ús.";

    final existsEmail = await db.query(
      tableUsuaris,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (existsEmail.isNotEmpty) return 'El correu electrònic ja està registrat.';

    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    try {
      await db.insert(tableUsuaris, {
        'id':           const Uuid().v4(),
        'username':     username.trim().toLowerCase(),
        'email':        email.trim().toLowerCase(),
        'password':     password, // En producció: usar bcrypt o similar
        'nom_complet':  nomComplet ?? '',
        'avatar_color': avatarColor ?? '#B5A1E5',
        'avatar_path':  null,
        'created_at':   now,
      });
      return null; // Èxit
    } catch (e) {
      return "Hi ha hagut un problema al registrar: El correu o usuari sembla que ja existeixen internament.";
    }
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

  Future<void> actualitzarAvatar(String username, String path) async {
    final db = await database;
    await db.update(
      tableUsuaris,
      {'avatar_path': path},
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
  }

  Future<void> actualitzarContrasenya(String username, String newPassword) async {
    final db = await database;
    await db.update(
      tableUsuaris,
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
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

  // ══════════════════════════════════════════════════════════════════════════
  // CRUD — ESTADISTIQUES_DIA
  // ══════════════════════════════════════════════════════════════════════════

  /// Desa o actualitza les estadístiques del dia actual per a un usuari.
  /// Si ja existeix una fila per avui, l'actualitza (UPSERT).
  Future<void> desarEstadistiquesAvui({
    required String usuariId,
    required int tempsCorrectedSeg,
    required double posturaMitjaPercent,
    required int totalAlertes,
    required int correccions,
  }) async {
    final db = await database;
    final avui = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await db.insert(
      tableEstadistiques,
      {
        'usuari_id':             usuariId,
        'data':                  avui,
        'temps_correcte_seg':    tempsCorrectedSeg,
        'postura_mitja_percent': posturaMitjaPercent,
        'total_alertes':         totalAlertes,
        'correccions':           correccions,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // UPSERT per la clau UNIQUE(usuari_id, data)
    );
  }

  /// Retorna les estadístiques dels N darrers dies d'un usuari.
  Future<List<Map<String, dynamic>>> obtenirEstadistiquesRecents(
    String usuariId, {
    int diesEnrere = 7,
  }) async {
    final db = await database;
    return await db.query(
      tableEstadistiques,
      where: 'usuari_id = ?',
      whereArgs: [usuariId],
      orderBy: 'data DESC',
      limit: diesEnrere,
    );
  }

  /// Retorna les estadístiques d'un dia concret.
  Future<Map<String, dynamic>?> obtenirEstadistiquesDia(
    String usuariId,
    String data, // Format: 'yyyy-MM-dd'
  ) async {
    final db = await database;
    final result = await db.query(
      tableEstadistiques,
      where: 'usuari_id = ? AND data = ?',
      whereArgs: [usuariId, data],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CRUD — CALIBRACIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Desa una nova calibració per a un usuari.
  Future<void> desarCalibracio({
    required String usuariId,
    required double latCul,
    required double frontCul,
    required double distCerv,
    required double distTor,
    required double distLumb,
    required double diffCervLumb,
  }) async {
    final db = await database;
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    await db.insert(tableCalibracions, {
      'usuari_id':       usuariId,
      'data_calibracio': now,
      'lat_cul':         latCul,
      'front_cul':       frontCul,
      'dist_cerv':       distCerv,
      'dist_tor':        distTor,
      'dist_lumb':       distLumb,
      'diff_cerv_lumb':  diffCervLumb,
    });
  }

  /// Obté l'última calibració d'un usuari (la més recent).
  Future<Map<String, dynamic>?> obtenirUltimaCalibracio(String usuariId) async {
    final db = await database;
    final result = await db.query(
      tableCalibracions,
      where: 'usuari_id = ?',
      whereArgs: [usuariId],
      orderBy: 'data_calibracio DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Obté l'historial complet de calibracions d'un usuari.
  Future<List<Map<String, dynamic>>> obtenirHistorialCalibracions(
    String usuariId,
  ) async {
    final db = await database;
    return await db.query(
      tableCalibracions,
      where: 'usuari_id = ?',
      whereArgs: [usuariId],
      orderBy: 'data_calibracio DESC',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CRUD — ALERTES
  // ══════════════════════════════════════════════════════════════════════════

  /// Registra una nova alerta. Cridar-la des de posture_control.dart
  /// quan es detecta mala postura persistent.
  Future<void> registrarAlerta({
    required String usuariId,
    required String tipus,   // ex: 'postura_mala', 'temps_assegut'
    required String missatge,
  }) async {
    final db = await database;
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    await db.insert(tableAlertes, {
      'usuari_id': usuariId,
      'timestamp': now,
      'tipus':     tipus,
      'missatge':  missatge,
    });
  }

  /// Retorna les alertes d'avui d'un usuari.
  Future<List<Map<String, dynamic>>> obtenirAlertesAvui(String usuariId) async {
    final db = await database;
    final avui = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return await db.query(
      tableAlertes,
      where: "usuari_id = ? AND timestamp LIKE ?",
      whereArgs: [usuariId, '$avui%'],
      orderBy: 'timestamp DESC',
    );
  }

  /// Retorna totes les alertes d'un usuari (per a la pantalla d'Estadístiques).
  Future<List<Map<String, dynamic>>> obtenirTotesAlertes(
    String usuariId, {
    int limit = 50,
  }) async {
    final db = await database;
    return await db.query(
      tableAlertes,
      where: 'usuari_id = ?',
      whereArgs: [usuariId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CRUD — CONFIGURACIO
  // ══════════════════════════════════════════════════════════════════════════

  /// Desa o actualitza la configuració d'un usuari.
  Future<void> desarConfiguracio({
    required String usuariId,
    required bool notificacions,
    required int objectiuTempsMaxSession,
  }) async {
    final db = await database;
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    await db.insert(
      tableConfiguracio,
      {
        'usuari_id':                  usuariId,
        'notificacions':              notificacions ? 1 : 0,
        'objectiu_temps_max_session': objectiuTempsMaxSession,
        'last_updated':               now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obté la configuració d'un usuari.
  Future<Map<String, dynamic>?> obtenirConfiguracio(String usuariId) async {
    final db = await database;
    final result = await db.query(
      tableConfiguracio,
      where: 'usuari_id = ?',
      whereArgs: [usuariId],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITATS
  // ══════════════════════════════════════════════════════════════════════════

  /// Tanca la connexió (per a tests o reinicis).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
