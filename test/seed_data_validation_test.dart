import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/database/seed_importer.dart';
import 'package:sc300_prep/core/services/question_engine.dart';
import 'package:sc300_prep/core/services/spaced_repetition_engine.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Seed Data Validation & Scale Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.instance;
      final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.init(dbOverride: inMemoryDb);
    });

    tearDown(() async {
      await db.close();
    });

    test('Validates and loads live assets/data files into SQLite without hardcoded count limits', () async {
      final questionsFile = File('assets/data/questions.json');
      final flashcardsFile = File('assets/data/flashcards.json');
      final scenariosFile = File('assets/data/scenarios.json');
      final referenceNotesFile = File('assets/data/reference_notes.json');

      expect(questionsFile.existsSync(), isTrue);
      expect(flashcardsFile.existsSync(), isTrue);
      expect(scenariosFile.existsSync(), isTrue);
      expect(referenceNotesFile.existsSync(), isTrue);

      final qJson = await questionsFile.readAsString();
      final fcJson = await flashcardsFile.readAsString();
      final scJson = await scenariosFile.readAsString();
      final rnJson = await referenceNotesFile.readAsString();

      final importer = SeedImporter(db: db);
      final summary = await importer.seedFromAssets(
        forceReload: true,
        questionsJsonOverride: qJson,
        flashcardsJsonOverride: fcJson,
        scenariosJsonOverride: scJson,
        referenceNotesJsonOverride: rnJson,
      );

      // Verify baseline counts for placeholder/Creed's real dataset
      expect(summary.questionsCount, greaterThanOrEqualTo(4));
      expect(summary.flashcardsCount, greaterThanOrEqualTo(4));
      expect(summary.scenariosCount, greaterThanOrEqualTo(4));
      expect(summary.referenceNotesCount, greaterThanOrEqualTo(4));

      // Validate Questions Integrity
      final allQ = await db.getAllQuestions();
      expect(allQ.length, summary.questionsCount);
      for (final q in allQ) {
        expect(q.id.isNotEmpty, isTrue);
        expect(q.domain.isNotEmpty, isTrue);
        expect(ExamConstants.allDomains.contains(q.domain), isTrue,
            reason: 'Question domain ${q.domain} must be one of ExamConstants.allDomains');
        expect(q.question.isNotEmpty, isTrue);
        expect(q.options.length, 4);
        expect(q.correctIndex, inInclusiveRange(0, 3));
        expect(q.explanation.isNotEmpty, isTrue);
      }

      // Validate Flashcards Integrity
      final allFc = await db.getAllFlashcards();
      expect(allFc.length, summary.flashcardsCount);
      for (final fc in allFc) {
        expect(fc.id.isNotEmpty, isTrue);
        expect(fc.domain.isNotEmpty, isTrue);
        expect(ExamConstants.allDomains.contains(fc.domain), isTrue);
        expect(fc.front.isNotEmpty, isTrue);
        expect(fc.back.isNotEmpty, isTrue);
        expect(fc.bucket, inInclusiveRange(1, 3));
      }

      // Validate Scenarios Integrity
      final allSc = await db.getAllScenarios();
      expect(allSc.length, summary.scenariosCount);
      for (final sc in allSc) {
        expect(sc.id.isNotEmpty, isTrue);
        expect(sc.domain.isNotEmpty, isTrue);
        expect(ExamConstants.allDomains.contains(sc.domain), isTrue);
        expect(sc.title.isNotEmpty, isTrue);
        expect(sc.scenarioText.isNotEmpty, isTrue);
        expect(sc.options.length, greaterThanOrEqualTo(2));
        expect(sc.correctIndex, inInclusiveRange(0, sc.options.length - 1));
      }

      // Validate Reference Notes Integrity
      final allNotes = await db.getAllReferenceNotes();
      expect(allNotes.length, summary.referenceNotesCount);
      for (final note in allNotes) {
        expect(note.id.isNotEmpty, isTrue);
        expect(note.domain.isNotEmpty, isTrue);
        expect(ExamConstants.allDomains.contains(note.domain), isTrue);
        expect(note.topic.isNotEmpty, isTrue);
        expect(note.title.isNotEmpty, isTrue);
        expect(note.body.isNotEmpty, isTrue);
      }

      // Test QuestionEngine
      final qEngine = QuestionEngine(db: db);
      final quiz4 = await qEngine.pickWeightedQuestions(count: 4);
      expect(quiz4.length, 4);

      // Test SpacedRepetitionEngine
      final srEngine = SpacedRepetitionEngine(db: db);
      final cards = await srEngine.pickFlashcardsForReview(count: 4);
      expect(cards.length, 4);
    });
  });
}
