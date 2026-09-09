import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/question.dart';
import 'package:sc300_prep/core/services/question_engine.dart';
import 'package:sc300_prep/core/services/gamification_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('QuestionEngine Tests', () {
    late AppDatabase db;
    late GamificationService gamification;
    late QuestionEngine engine;

    setUp(() async {
      db = AppDatabase.instance;
      final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.init(dbOverride: inMemoryDb);
      gamification = GamificationService(db: db);
      engine = QuestionEngine(db: db, gamification: gamification);
    });

    tearDown(() async {
      await db.close();
    });

    test('pickWeightedQuestions allocates domain distribution equally across 4 domains', () async {
      final List<Question> pool = [];
      for (final domain in ExamConstants.domainWeights.keys) {
        for (int i = 0; i < 15; i++) {
          pool.add(Question(
            id: '${domain}_$i',
            domain: domain,
            question: '$domain Question $i',
            options: ['A', 'B', 'C', 'D'],
            correctIndex: 0,
            explanation: 'Exp',
          ));
        }
      }

      await db.batchInsertQuestions(pool);

      final selected = await engine.pickWeightedQuestions(count: 20);
      expect(selected.length, 20);

      for (final entry in ExamConstants.domainWeights.entries) {
        final count = selected.where((q) => q.domain == entry.key).length;
        final target = (20 * entry.value).round(); // 5
        expect(count, inInclusiveRange(target - 1, target + 1),
            reason: 'Domain ${entry.key} count ($count) should match target ($target)');
      }
    });

    test('submitAnswer evaluates correctness and awards XP', () async {
      final q = Question(
        id: 'q_test',
        domain: 'Implement and manage user identities',
        question: 'Test Q',
        options: ['Wrong', 'Right'],
        correctIndex: 1,
        explanation: 'Right is index 1',
      );
      await db.batchInsertQuestions([q]);

      final res1 = await engine.submitAnswer(
        question: q,
        selectedIndex: 1,
        timeSpentSeconds: 5,
        mode: 'quiz',
      );
      expect(res1.isCorrect, isTrue);
      expect(res1.xpEarned, 10);

      final profileAfterCorrect = await gamification.getProfile();
      expect(profileAfterCorrect.xp, 10);

      final res2 = await engine.submitAnswer(
        question: q,
        selectedIndex: 0,
        timeSpentSeconds: 5,
        mode: 'quiz',
      );
      expect(res2.isCorrect, isFalse);
      expect(res2.xpEarned, 0);

      final profileAfterIncorrect = await gamification.getProfile();
      expect(profileAfterIncorrect.xp, 10);
    });
  });
}
