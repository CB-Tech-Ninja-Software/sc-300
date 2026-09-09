import 'dart:math';
import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/flashcard.dart';
import 'package:sc300_prep/core/services/gamification_service.dart';

/// Engine managing Leitner-box spaced repetition for flashcard study sessions.
class SpacedRepetitionEngine {
  final AppDatabase database;
  final GamificationService gamificationService;
  final Random _random;

  SpacedRepetitionEngine({
    AppDatabase? db,
    GamificationService? gamification,
    Random? random,
  })  : database = db ?? AppDatabase.instance,
        gamificationService = gamification ?? GamificationService(db: db ?? AppDatabase.instance),
        _random = random ?? Random();

  /// Selects [count] flashcards for a review session, prioritizing Box 1 ('Still Shaky').
  Future<List<Flashcard>> pickFlashcardsForReview({
    int count = 10,
    String? domain,
    List<Flashcard>? poolOverride,
  }) async {
    final pool = poolOverride ?? await database.getAllFlashcards(domain: domain);
    if (pool.isEmpty) return [];
    if (pool.length <= count) {
      final shuffled = List<Flashcard>.from(pool)..shuffle(_random);
      return shuffled;
    }

    final Map<int, List<Flashcard>> boxMap = {
      1: [],
      2: [],
      3: [],
    };

    for (final fc in pool) {
      final b = (fc.bucket >= 1 && fc.bucket <= 3) ? fc.bucket : 1;
      boxMap[b]!.add(fc);
    }

    boxMap.forEach((_, list) => list.shuffle(_random));

    final List<Flashcard> selected = [];
    final Set<String> selectedIds = {};

    // Target distribution: 60% Box 1, 30% Box 2, 10% Box 3
    final int targetBox1 = (count * ExamConstants.box1SelectionWeight).round();
    final int targetBox2 = (count * ExamConstants.box2SelectionWeight).round();
    final int targetBox3 = count - (targetBox1 + targetBox2);

    void takeFromBox(int boxNumber, int target) {
      final available = boxMap[boxNumber] ?? [];
      final toTake = min(target, available.length);
      for (int i = 0; i < toTake; i++) {
        final card = available[i];
        selected.add(card);
        selectedIds.add(card.id);
      }
    }

    takeFromBox(1, targetBox1);
    takeFromBox(2, targetBox2);
    takeFromBox(3, targetBox3);

    final remaining = pool.where((fc) => !selectedIds.contains(fc.id)).toList()
      ..sort((a, b) => a.bucket.compareTo(b.bucket));

    while (selected.length < count && remaining.isNotEmpty) {
      final nextCard = remaining.removeAt(0);
      selected.add(nextCard);
      selectedIds.add(nextCard.id);
    }

    selected.shuffle(_random);
    return selected;
  }

  /// Processes a user's self-assessment on a flashcard.
  Future<Flashcard> reviewCard({
    required Flashcard card,
    required bool isCorrect,
  }) async {
    final updated = card.copyWithReview(isCorrect: isCorrect);
    await database.updateFlashcard(updated);
    await gamificationService.recordFlashcardReview(isCorrect: isCorrect);
    return updated;
  }

  /// Calculates statistics on flashcard mastery.
  Future<FlashcardDeckStats> getDeckStats({String? domain}) async {
    final allCards = await database.getAllFlashcards(domain: domain);
    int box1 = 0;
    int box2 = 0;
    int box3 = 0;
    int totalReviews = 0;

    for (final card in allCards) {
      if (card.bucket == 1) box1++;
      if (card.bucket == 2) box2++;
      if (card.bucket >= 3) box3++;
      totalReviews += card.reviewCount;
    }

    final double masteryPercentage = allCards.isNotEmpty
        ? ((box3 * 1.0 + box2 * 0.5) / allCards.length) * 100
        : 0.0;

    return FlashcardDeckStats(
      totalCards: allCards.length,
      box1Count: box1,
      box2Count: box2,
      box3Count: box3,
      totalReviews: totalReviews,
      masteryPercentage: masteryPercentage,
    );
  }
}

class FlashcardDeckStats {
  final int totalCards;
  final int box1Count;
  final int box2Count;
  final int box3Count;
  final int totalReviews;
  final double masteryPercentage;

  const FlashcardDeckStats({
    required this.totalCards,
    required this.box1Count,
    required this.box2Count,
    required this.box3Count,
    required this.totalReviews,
    required this.masteryPercentage,
  });
}
