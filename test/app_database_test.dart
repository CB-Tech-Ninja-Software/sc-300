import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/database/seed_importer.dart';
import 'package:sc300_prep/core/models/question.dart';
import 'package:sc300_prep/core/models/flashcard.dart';
import 'package:sc300_prep/core/models/scenario.dart';
import 'package:sc300_prep/core/models/question_attempt.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppDatabase and SeedImporter Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.instance;
      final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.init(dbOverride: inMemoryDb);
    });

    tearDown(() async {
      await db.close();
    });

    test('Questions CRUD and querying', () async {
      final q1 = Question(
        id: 'q1',
        domain: 'Implement and manage user identities',
        question: 'Identities Q1',
        options: ['A', 'B'],
        correctIndex: 0,
        explanation: 'Exp 1',
      );
      final q2 = Question(
        id: 'q2',
        domain: 'Implement authentication and access management',
        question: 'Auth Q2',
        options: ['A', 'B'],
        correctIndex: 1,
        explanation: 'Exp 2',
      );

      await db.batchInsertQuestions([q1, q2]);

      final allQuestions = await db.getAllQuestions();
      expect(allQuestions.length, 2);

      final domainQuestions = await db.getAllQuestions(domain: 'Implement and manage user identities');
      expect(domainQuestions.length, 1);
      expect(domainQuestions.first.id, 'q1');

      final queriedQ1 = await db.getQuestionById('q1');
      expect(queriedQ1, isNotNull);
      expect(queriedQ1!.question, 'Identities Q1');
    });

    test('Flashcards CRUD and querying', () async {
      final fc1 = Flashcard(
        id: 'fc1',
        domain: 'Implement and manage user identities',
        front: 'Front 1',
        back: 'Back 1',
        bucket: 1,
      );

      await db.batchInsertFlashcards([fc1]);

      final allCards = await db.getAllFlashcards();
      expect(allCards.length, 1);
      expect(allCards.first.bucket, 1);

      final updated = fc1.copyWithReview(isCorrect: true);
      await db.updateFlashcard(updated);

      final cardsAfterUpdate = await db.getAllFlashcards();
      expect(cardsAfterUpdate.first.bucket, 2);
    });

    test('Scenarios CRUD and querying', () async {
      final sc1 = Scenario(
        id: 'sc1',
        domain: 'Plan and implement workload identities',
        title: 'Workload Scenario 1',
        scenarioText: 'Scenario Details',
        question: 'Next step?',
        options: ['A', 'B'],
        correctIndex: 0,
        explanation: 'Exp',
      );

      await db.batchInsertScenarios([sc1]);

      final scenarios = await db.getAllScenarios(domain: 'Plan and implement workload identities');
      expect(scenarios.length, 1);
      expect(scenarios.first.title, 'Workload Scenario 1');
    });

    test('Question attempts and domain stats calculation', () async {
      final q1 = Question(
        id: 'q1',
        domain: 'Plan and automate identity governance',
        question: 'Gov Q1',
        options: ['A', 'B'],
        correctIndex: 0,
        explanation: 'Exp 1',
      );
      await db.batchInsertQuestions([q1]);

      final a1 = QuestionAttempt(
        questionId: 'q1',
        selectedIndex: 0,
        isCorrect: true,
        attemptedAt: DateTime.now(),
        mode: 'quiz',
      );
      final a2 = QuestionAttempt(
        questionId: 'q1',
        selectedIndex: 1,
        isCorrect: false,
        attemptedAt: DateTime.now(),
        mode: 'quiz',
      );

      await db.recordAttempt(a1);
      await db.recordAttempt(a2);

      final stats = await db.getDomainStats();
      expect(stats.containsKey('Plan and automate identity governance'), isTrue);
      expect(stats['Plan and automate identity governance']!['total'], 2);
      expect(stats['Plan and automate identity governance']!['correct'], 1);
      expect(stats['Plan and automate identity governance']!['accuracy'], 50.0);
    });

    test('SeedImporter populates tables from JSON overrides', () async {
      final importer = SeedImporter(db: db);
      final summary = await importer.seedFromAssets(
        questionsJsonOverride: '''
        [
          {
            "id": "q_override_1",
            "domain": "Implement and manage user identities",
            "question": "Import test?",
            "options": ["A", "B"],
            "correctIndex": 0,
            "explanation": "Exp"
          }
        ]
        ''',
        flashcardsJsonOverride: '''
        [
          {
            "id": "fc_override_1",
            "domain": "Implement and manage user identities",
            "front": "Front",
            "back": "Back"
          }
        ]
        ''',
        scenariosJsonOverride: '''
        [
          {
            "id": "sc_override_1",
            "domain": "Plan and implement workload identities",
            "title": "Title",
            "scenarioText": "Text",
            "question": "Question",
            "options": ["A", "B"],
            "correctIndex": 0,
            "explanation": "Exp"
          }
        ]
        ''',
      );

      expect(summary.questionsCount, 1);
      expect(summary.flashcardsCount, 1);
      expect(summary.scenariosCount, 1);
      expect(await db.isSeeded(), isTrue);

      final questions = await db.getAllQuestions();
      expect(questions.length, 1);
      expect(questions.first.id, 'q_override_1');
    });
  });
}
