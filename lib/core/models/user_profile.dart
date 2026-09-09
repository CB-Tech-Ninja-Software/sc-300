import 'dart:convert';
import 'package:sc300_prep/core/constants/exam_constants.dart';

/// Represents local user profile, XP, streak, and unlocked achievements.
class UserProfile {
  final String id;
  final int xp;
  final int level;
  final int streakDays;
  final String? lastActiveDate; // 'YYYY-MM-DD'
  final int totalQuizzesTaken;
  final int totalFlashcardsReviewed;
  final int totalMockExamsTaken;
  final List<String> unlockedBadgeIds;

  const UserProfile({
    this.id = 'default',
    this.xp = 0,
    this.level = 1,
    this.streakDays = 0,
    this.lastActiveDate,
    this.totalQuizzesTaken = 0,
    this.totalFlashcardsReviewed = 0,
    this.totalMockExamsTaken = 0,
    this.unlockedBadgeIds = const [],
  });

  /// Factory constructor from SQLite database map.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    List<String> badges = [];
    if (map['badges'] != null) {
      if (map['badges'] is String) {
        final decoded = jsonDecode(map['badges'] as String);
        if (decoded is List) {
          badges = decoded.map((e) => e.toString()).toList();
        }
      } else if (map['badges'] is List) {
        badges = (map['badges'] as List).map((e) => e.toString()).toList();
      }
    }

    return UserProfile(
      id: map['id'] as String? ?? 'default',
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      streakDays: map['streak_days'] as int? ?? 0,
      lastActiveDate: map['last_active_date'] as String?,
      totalQuizzesTaken: map['total_quizzes_taken'] as int? ?? 0,
      totalFlashcardsReviewed: map['total_flashcards_reviewed'] as int? ?? 0,
      totalMockExamsTaken: map['total_mock_exams_taken'] as int? ?? 0,
      unlockedBadgeIds: badges,
    );
  }

  /// Serialize to SQLite database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'xp': xp,
      'level': level,
      'streak_days': streakDays,
      'last_active_date': lastActiveDate,
      'total_quizzes_taken': totalQuizzesTaken,
      'total_flashcards_reviewed': totalFlashcardsReviewed,
      'total_mock_exams_taken': totalMockExamsTaken,
      'badges': jsonEncode(unlockedBadgeIds),
    };
  }

  /// Calculates level from XP: 100 XP per level.
  static int calculateLevel(int totalXp) {
    return 1 + (totalXp ~/ ExamConstants.xpPerLevel);
  }

  /// Calculates XP progress into current level (0 to 100).
  int get currentLevelXpProgress => xp % ExamConstants.xpPerLevel;

  /// Calculates percentage progress to next level (0.0 to 1.0).
  double get currentLevelProgressFraction => currentLevelXpProgress / ExamConstants.xpPerLevel;

  UserProfile copyWith({
    int? xp,
    int? level,
    int? streakDays,
    String? lastActiveDate,
    int? totalQuizzesTaken,
    int? totalFlashcardsReviewed,
    int? totalMockExamsTaken,
    List<String>? unlockedBadgeIds,
  }) {
    return UserProfile(
      id: id,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      totalFlashcardsReviewed: totalFlashcardsReviewed ?? this.totalFlashcardsReviewed,
      totalMockExamsTaken: totalMockExamsTaken ?? this.totalMockExamsTaken,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
    );
  }
}
