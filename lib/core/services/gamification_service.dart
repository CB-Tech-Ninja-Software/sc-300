import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/badge.dart';
import 'package:sc300_prep/core/models/user_profile.dart';

/// Manages XP rewards, streak calculation, level progression, and badge unlocks.
class GamificationService {
  final AppDatabase database;

  GamificationService({AppDatabase? db}) : database = db ?? AppDatabase.instance;

  Future<UserProfile> getProfile() async {
    return await database.getUserProfile();
  }

  /// Updates active streak based on the current date (YYYY-MM-DD).
  Future<UserProfile> recordActivity({DateTime? nowOverride}) async {
    final now = nowOverride ?? DateTime.now();
    final todayStr = _formatDate(now);
    final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));

    final profile = await database.getUserProfile();
    int newStreak = profile.streakDays;

    if (profile.lastActiveDate == null) {
      newStreak = 1;
    } else if (profile.lastActiveDate == todayStr) {
      return profile;
    } else if (profile.lastActiveDate == yesterdayStr) {
      newStreak += 1;
    } else {
      newStreak = 1;
    }

    final updated = profile.copyWith(
      streakDays: newStreak,
      lastActiveDate: todayStr,
    );

    await database.updateUserProfile(updated);
    await checkAndAwardBadges(updated);
    return (await database.getUserProfile());
  }

  Future<UserProfile> awardXp(int xpEarned) async {
    final profile = await database.getUserProfile();
    final newXp = profile.xp + xpEarned;
    final newLevel = UserProfile.calculateLevel(newXp);

    final updated = profile.copyWith(
      xp: newXp,
      level: newLevel,
    );

    await database.updateUserProfile(updated);
    await checkAndAwardBadges(updated);
    return (await database.getUserProfile());
  }

  Future<UserProfile> recordQuizCompletion({int correctCount = 0, int totalCount = 0}) async {
    await recordActivity();
    final profile = await database.getUserProfile();
    final xpToAdd = correctCount * ExamConstants.xpQuestionCorrect;

    final updated = profile.copyWith(
      totalQuizzesTaken: profile.totalQuizzesTaken + 1,
      xp: profile.xp + xpToAdd,
      level: UserProfile.calculateLevel(profile.xp + xpToAdd),
    );

    await database.updateUserProfile(updated);
    await checkAndAwardBadges(updated);
    return (await database.getUserProfile());
  }

  Future<UserProfile> recordFlashcardReview({required bool isCorrect}) async {
    await recordActivity();
    final profile = await database.getUserProfile();
    final xpToAdd = ExamConstants.xpFlashcardReviewed;

    final updated = profile.copyWith(
      totalFlashcardsReviewed: profile.totalFlashcardsReviewed + 1,
      xp: profile.xp + xpToAdd,
      level: UserProfile.calculateLevel(profile.xp + xpToAdd),
    );

    await database.updateUserProfile(updated);
    await checkAndAwardBadges(updated);
    return (await database.getUserProfile());
  }

  Future<UserProfile> recordMockExamOutcome({required bool isPassed, required int score}) async {
    await recordActivity();
    final profile = await database.getUserProfile();
    int xpToAdd = ExamConstants.xpMockExamCompleted;
    if (isPassed) {
      xpToAdd += ExamConstants.xpMockExamPassedBonus;
    }

    final updated = profile.copyWith(
      totalMockExamsTaken: profile.totalMockExamsTaken + 1,
      xp: profile.xp + xpToAdd,
      level: UserProfile.calculateLevel(profile.xp + xpToAdd),
    );

    await database.updateUserProfile(updated);
    await checkAndAwardBadges(updated);
    return (await database.getUserProfile());
  }

  /// Evaluates badge unlock criteria and unlocks newly earned badges.
  Future<List<AppBadge>> checkAndAwardBadges(UserProfile profile) async {
    final unlockedIds = Set<String>.from(profile.unlockedBadgeIds);
    final List<AppBadge> newlyAwarded = [];

    final domainStats = await database.getDomainStats();

    // 1. Domain Master Badge (90%+ accuracy on ANY domain with min 10 attempts)
    if (!unlockedIds.contains('domain_master')) {
      final hasMastery = domainStats.values.any((stats) =>
          (stats['total'] as int? ?? 0) >= 10 &&
          (stats['accuracy'] as double? ?? 0.0) >= 90.0);
      if (hasMastery) {
        unlockedIds.add('domain_master');
        final badge = AppBadge.predefinedBadges.firstWhere(
          (b) => b.id == 'domain_master',
          orElse: () => AppBadge.predefinedBadges.first,
        );
        newlyAwarded.add(badge);
      }
    }

    // 2. Streak Warrior Badge (3-day streak)
    if (!unlockedIds.contains('streak_warrior') && profile.streakDays >= 3) {
      unlockedIds.add('streak_warrior');
      newlyAwarded.add(AppBadge.predefinedBadges.firstWhere((b) => b.id == 'streak_warrior'));
    }

    // 3. SC-300 Master Badge (Level 5+)
    if (!unlockedIds.contains('sc300_master') && profile.level >= 5) {
      unlockedIds.add('sc300_master');
      newlyAwarded.add(AppBadge.predefinedBadges.firstWhere((b) => b.id == 'sc300_master'));
    }

    // 4. Flashcard Fiend Badge (25+ flashcards reviewed)
    if (!unlockedIds.contains('flashcard_fiend') && profile.totalFlashcardsReviewed >= 25) {
      unlockedIds.add('flashcard_fiend');
      newlyAwarded.add(AppBadge.predefinedBadges.firstWhere((b) => b.id == 'flashcard_fiend'));
    }

    // 5. Mock Champion Badge
    if (!unlockedIds.contains('mock_champion')) {
      final mockExams = await database.getAllMockExams();
      if (mockExams.any((e) => e.isPassed)) {
        unlockedIds.add('mock_champion');
        newlyAwarded.add(AppBadge.predefinedBadges.firstWhere((b) => b.id == 'mock_champion'));
      }
    }

    if (newlyAwarded.isNotEmpty) {
      final updated = profile.copyWith(unlockedBadgeIds: unlockedIds.toList());
      await database.updateUserProfile(updated);
    }

    return newlyAwarded;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
