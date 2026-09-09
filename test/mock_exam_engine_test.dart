import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/question.dart';
import 'package:sc300_prep/core/services/mock_exam_engine.dart';
import 'package:sc300_prep/core/services/gamification_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MockExamEngine Tests', () {
    late AppDatabase db;
    late GamificationService gamification;
    late MockExamEngine engine;

    setUp(() async {
      db = AppDatabase.instance;
      final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.init(dbOverride: inMemoryDb);
      gamification = GamificationService(db: db);
      engine = MockExamEngine(db: db, gamification: gamification);
    });

    tearDown(() async {
      await db.close();
    });

    test('startExam creates 60-question session with equal 4-domain distribution (15 per domain)', () async {
      final List<Question> pool = [];
      for (final domain in ExamConstants.domainWeights.keys) {
        for (int i = 0; i < 20; i++) {
          pool.add(Question(
            id: '${domain}_$i',
            domain: domain,
            question: '$domain Q $i',
            options: ['A', 'B', 'C', 'D'],
            correctIndex: 0,
            explanation: 'Exp',
          ));
        }
      }
      await db.batchInsertQuestions(pool);

      final session = await engine.startExam();
      expect(session.totalQuestions, ExamConstants.mockExamQuestionCount); // 60
      expect(session.timeLimitSeconds, ExamConstants.mockExamTimeLimitSeconds); // 6000
      expect(session.currentQuestionIndex, 0);

      for (final entry in ExamConstants.domainWeights.entries) {
        final domainCount = session.questions.where((q) => q.domain == entry.key).length;
        final expectedCount = (ExamConstants.mockExamQuestionCount * entry.value).round(); // 15
        expect(domainCount, expectedCount, reason: 'Domain ${entry.key} should have $expectedCount questions');
      }
    });

    test('sequential answer locking and score computation', () async {
      final List<Question> pool = [];
      for (final domain in ExamConstants.domainWeights.keys) {
        for (int i = 0; i < 20; i++) {
          pool.add(Question(
            id: 'q_${domain}_$i',
            domain: domain,
            question: '$domain Q $i',
            options: ['A', 'B'],
            correctIndex: 0,
            explanation: 'Exp',
          ));
        }
      }
      await db.batchInsertQuestions(pool);

      final session = await engine.startExam();
      final total = session.totalQuestions; // 60

      // Answer first 45 correctly (index 0), remaining 15 incorrectly (index 1) -> 45/60 = 75.0% (Pass >= 70%)
      for (int i = 0; i < total; i++) {
        expect(session.currentQuestionIndex, i);
        final selected = (i < 45) ? 0 : 1;
        final ok = await engine.submitAnswer(session, selectedIndex: selected);
        expect(ok, isTrue);
      }

      expect(session.isFinished, isTrue);

      final result = await engine.completeExam(session, elapsedSecondsOverride: 3600);
      expect(result.totalQuestions, total);
      expect(result.score, 45);
      expect(result.percentage, 75.0);
      expect(result.isPassed, isTrue);

      for (final domain in ExamConstants.domainWeights.keys) {
        expect(result.domainBreakdown.containsKey(domain), isTrue);
      }

      final profile = await gamification.getProfile();
      // 100 XP completion + 50 XP pass bonus = 150 XP
      expect(profile.xp, 150);
      expect(profile.totalMockExamsTaken, 1);
    });
  });
}
