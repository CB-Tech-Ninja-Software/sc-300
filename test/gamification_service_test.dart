import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/question.dart';
import 'package:sc300_prep/core/models/question_attempt.dart';
import 'package:sc300_prep/core/services/gamification_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GamificationService Tests', () {
    late AppDatabase db;
    late GamificationService service;

    setUp(() async {
      db = AppDatabase.instance;
      final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.init(dbOverride: inMemoryDb);
      service = GamificationService(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('XP awards and level progression', () async {
      var profile = await service.getProfile();
      expect(profile.xp, 0);
      expect(profile.level, 1);

      profile = await service.awardXp(50);
      expect(profile.xp, 50);
      expect(profile.level, 1);

      profile = await service.awardXp(60);
      expect(profile.xp, 110);
      expect(profile.level, 2);
    });

    test('Active streak calculation across dates', () async {
      final day1 = DateTime(2026, 9, 1);
      final day2 = DateTime(2026, 9, 2);
      final day3 = DateTime(2026, 9, 3);
      final day5 = DateTime(2026, 9, 5);

      var profile = await service.recordActivity(nowOverride: day1);
      expect(profile.streakDays, 1);
      expect(profile.lastActiveDate, '2026-09-01');

      profile = await service.recordActivity(nowOverride: day1);
      expect(profile.streakDays, 1);

      profile = await service.recordActivity(nowOverride: day2);
      expect(profile.streakDays, 2);
      expect(profile.lastActiveDate, '2026-09-02');

      profile = await service.recordActivity(nowOverride: day3);
      expect(profile.streakDays, 3);
      expect(profile.unlockedBadgeIds.contains('streak_warrior'), isTrue);

      profile = await service.recordActivity(nowOverride: day5);
      expect(profile.streakDays, 1);
      expect(profile.lastActiveDate, '2026-09-05');
    });

    test('Badge unlock for domain mastery', () async {
      const testDomain = 'Implement and manage user identities';
      final questions = List.generate(
        10,
        (i) => Question(
          id: 'q_identities_$i',
          domain: testDomain,
          question: 'Q',
          options: ['A', 'B'],
          correctIndex: 0,
          explanation: 'Exp',
        ),
      );
      await db.batchInsertQuestions(questions);

      for (final q in questions) {
        await db.recordAttempt(QuestionAttempt(
          questionId: q.id,
          selectedIndex: 0,
          isCorrect: true,
          attemptedAt: DateTime.now(),
          mode: 'quiz',
        ));
      }

      final profile = await service.getProfile();
      final awarded = await service.checkAndAwardBadges(profile);

      expect(awarded.any((b) => b.id == 'domain_master'), isTrue);
      final updatedProfile = await service.getProfile();
      expect(updatedProfile.unlockedBadgeIds.contains('domain_master'), isTrue);
    });
  });
}
