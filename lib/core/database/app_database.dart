import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sc300_prep/core/models/question.dart';
import 'package:sc300_prep/core/models/flashcard.dart';
import 'package:sc300_prep/core/models/scenario.dart';
import 'package:sc300_prep/core/models/question_attempt.dart';
import 'package:sc300_prep/core/models/mock_exam.dart';
import 'package:sc300_prep/core/models/user_profile.dart';
import 'package:sc300_prep/core/models/reference_note.dart';

/// SQLite Database Manager for Microsoft SC-300 Training.
/// Offline-first, single source of truth for all study data and progress.
class AppDatabase {
  static AppDatabase? _instance;
  Database? _db;

  AppDatabase._();

  static AppDatabase get instance => _instance ??= AppDatabase._();

  /// Internal getter for the database.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  /// Initialize database instance or override with a test database.
  Future<void> init({Database? dbOverride, String dbName = 'sc300_prep.db'}) async {
    if (dbOverride != null) {
      _db = dbOverride;
      await _createTables(_db!);
      return;
    }
    _db = await _initDatabase(dbName: dbName);
  }

  Future<Database> _initDatabase({String dbName = 'sc300_prep.db'}) async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, dbName);

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Questions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS questions (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        subtopic TEXT,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_index INTEGER NOT NULL,
        explanation TEXT NOT NULL
      )
    ''');

    // Flashcards table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS flashcards (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        subtopic TEXT,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        bucket INTEGER NOT NULL DEFAULT 1,
        last_reviewed_at INTEGER,
        review_count INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Scenarios table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scenarios (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        title TEXT NOT NULL,
        scenario_text TEXT NOT NULL,
        steps TEXT,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_index INTEGER NOT NULL,
        explanation TEXT NOT NULL
      )
    ''');

    // Question Attempts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS question_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT NOT NULL,
        selected_index INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        attempted_at INTEGER NOT NULL,
        time_spent_seconds INTEGER NOT NULL DEFAULT 0,
        mode TEXT NOT NULL
      )
    ''');

    // Mock Exams table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mock_exams (
        id TEXT PRIMARY KEY,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        time_limit_seconds INTEGER NOT NULL DEFAULT 6000,
        time_spent_seconds INTEGER NOT NULL DEFAULT 0,
        total_questions INTEGER NOT NULL DEFAULT 60,
        score INTEGER NOT NULL DEFAULT 0,
        percentage REAL NOT NULL DEFAULT 0.0,
        is_passed INTEGER NOT NULL DEFAULT 0,
        domain_breakdown TEXT NOT NULL,
        question_ids TEXT NOT NULL,
        user_answers TEXT NOT NULL
      )
    ''');

    // User Profile table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id TEXT PRIMARY KEY,
        xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        streak_days INTEGER NOT NULL DEFAULT 0,
        last_active_date TEXT,
        total_quizzes_taken INTEGER NOT NULL DEFAULT 0,
        total_flashcards_reviewed INTEGER NOT NULL DEFAULT 0,
        total_mock_exams_taken INTEGER NOT NULL DEFAULT 0,
        badges TEXT NOT NULL DEFAULT '[]'
      )
    ''');

    // Reference Notes table (Reference Library)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reference_notes (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        topic TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        source_url TEXT,
        bookmarked INTEGER NOT NULL DEFAULT 0,
        last_read_at INTEGER
      )
    ''');

    // Metadata table (for seed status & versioning)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Initialize default user profile if none exists
    await db.rawInsert('''
      INSERT OR IGNORE INTO user_profile (id, xp, level, streak_days, badges)
      VALUES ('default', 0, 1, 0, '[]')
    ''');
  }

  // --- Seed Metadata Operations ---

  Future<bool> isSeeded() async {
    final db = await database;
    final res = await db.query('app_metadata', where: 'key = ?', whereArgs: ['is_seeded']);
    if (res.isEmpty) return false;
    return res.first['value'] == 'true';
  }

  Future<void> setSeeded(bool seeded) async {
    final db = await database;
    await db.insert(
      'app_metadata',
      {'key': 'is_seeded', 'value': seeded ? 'true' : 'false'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Questions Operations ---

  Future<void> batchInsertQuestions(List<Question> questions) async {
    final db = await database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert('questions', q.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Question>> getAllQuestions({String? domain}) async {
    final db = await database;
    final res = await db.query(
      'questions',
      where: domain != null ? 'domain = ?' : null,
      whereArgs: domain != null ? [domain] : null,
    );
    return res.map((e) => Question.fromMap(e)).toList();
  }

  Future<Question?> getQuestionById(String id) async {
    final db = await database;
    final res = await db.query('questions', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return Question.fromMap(res.first);
  }

  // --- Flashcards Operations ---

  Future<void> batchInsertFlashcards(List<Flashcard> flashcards) async {
    final db = await database;
    final batch = db.batch();
    for (final fc in flashcards) {
      batch.insert('flashcards', fc.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Flashcard>> getAllFlashcards({String? domain, int? bucket}) async {
    final db = await database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (domain != null && bucket != null) {
      whereClause = 'domain = ? AND bucket = ?';
      whereArgs = [domain, bucket];
    } else if (domain != null) {
      whereClause = 'domain = ?';
      whereArgs = [domain];
    } else if (bucket != null) {
      whereClause = 'bucket = ?';
      whereArgs = [bucket];
    }

    final res = await db.query('flashcards', where: whereClause, whereArgs: whereArgs.isEmpty ? null : whereArgs);
    return res.map((e) => Flashcard.fromMap(e)).toList();
  }

  Future<void> updateFlashcard(Flashcard card) async {
    final db = await database;
    await db.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  // --- Scenarios Operations ---

  Future<void> batchInsertScenarios(List<Scenario> scenarios) async {
    final db = await database;
    final batch = db.batch();
    for (final sc in scenarios) {
      batch.insert('scenarios', sc.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Scenario>> getAllScenarios({String? domain}) async {
    final db = await database;
    final res = await db.query(
      'scenarios',
      where: domain != null ? 'domain = ?' : null,
      whereArgs: domain != null ? [domain] : null,
    );
    return res.map((e) => Scenario.fromMap(e)).toList();
  }

  // --- Reference Notes Operations ---

  Future<void> batchInsertReferenceNotes(List<ReferenceNote> notes) async {
    final db = await database;
    final batch = db.batch();
    for (final n in notes) {
      batch.insert('reference_notes', n.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ReferenceNote>> getAllReferenceNotes({
    String? domain,
    String? topic,
    bool? bookmarkedOnly,
  }) async {
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (domain != null) {
      whereClauses.add('domain = ?');
      whereArgs.add(domain);
    }
    if (topic != null) {
      whereClauses.add('topic = ?');
      whereArgs.add(topic);
    }
    if (bookmarkedOnly == true) {
      whereClauses.add('bookmarked = 1');
    }

    final String? where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final res = await db.query(
      'reference_notes',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'domain ASC, topic ASC, title ASC',
    );
    return res.map((e) => ReferenceNote.fromMap(e)).toList();
  }

  Future<ReferenceNote?> getReferenceNoteById(String id) async {
    final db = await database;
    final res = await db.query('reference_notes', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return ReferenceNote.fromMap(res.first);
  }

  Future<void> updateReferenceNote(ReferenceNote note) async {
    final db = await database;
    await db.update(
      'reference_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> toggleReferenceNoteBookmark(String id, bool isBookmarked) async {
    final db = await database;
    await db.update(
      'reference_notes',
      {'bookmarked': isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markReferenceNoteAsRead(String id) async {
    final db = await database;
    await db.update(
      'reference_notes',
      {'last_read_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Attempts & Progress Operations ---

  Future<void> recordAttempt(QuestionAttempt attempt) async {
    final db = await database;
    await db.insert('question_attempts', attempt.toMap());
  }

  Future<Map<String, Map<String, dynamic>>> getDomainStats() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT 
        q.domain,
        COUNT(a.id) as total_attempts,
        SUM(CASE WHEN a.is_correct = 1 THEN 1 ELSE 0 END) as correct_count
      FROM question_attempts a
      JOIN questions q ON a.question_id = q.id
      GROUP BY q.domain
    ''');

    Map<String, Map<String, dynamic>> stats = {};
    for (final row in res) {
      final domain = row['domain'] as String;
      final total = row['total_attempts'] as int? ?? 0;
      final correct = row['correct_count'] as int? ?? 0;
      final accuracy = total > 0 ? (correct / total) * 100 : 0.0;
      stats[domain] = {
        'total': total,
        'correct': correct,
        'accuracy': accuracy,
      };
    }
    return stats;
  }

  // --- Mock Exams Operations ---

  Future<void> recordMockExam(MockExamResult result) async {
    final db = await database;
    await db.insert(
      'mock_exams',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MockExamResult>> getAllMockExams() async {
    final db = await database;
    final res = await db.query('mock_exams', orderBy: 'started_at DESC');
    return res.map((e) => MockExamResult.fromMap(e)).toList();
  }

  // --- User Profile Operations ---

  Future<UserProfile> getUserProfile() async {
    final db = await database;
    final res = await db.query('user_profile', where: "id = 'default'");
    if (res.isEmpty) {
      final defaultProfile = const UserProfile();
      await db.insert('user_profile', defaultProfile.toMap());
      return defaultProfile;
    }
    return UserProfile.fromMap(res.first);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await database;
    await db.update(
      'user_profile',
      profile.toMap(),
      where: "id = 'default'",
    );
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
