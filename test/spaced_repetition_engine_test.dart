import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/flashcard.dart';
import 'package:sc300_prep/core/services/spaced_repetition_engine.dart';
import 'package:sc300_prep/core/services/gamification_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SpacedRepetitionEngine Tests', () {
    late AppDatabase db;
    late GamificationService gamification;
    late SpacedRepetitionEngine engine;

    setUp(() async {
      db = AppDatabase.instance;
      final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.init(dbOverride: inMemoryDb);
      gamification = GamificationService(db: db);
      engine = SpacedRepetitionEngine(db: db, gamification: gamification);
    });

    tearDown(() async {
      await db.close();
    });

    test('pickFlashcardsForReview prioritizes Box 1 shaky cards', () async {
      final List<Flashcard> cards = [];
      for (int i = 0; i < 5; i++) {
        cards.add(Flashcard(
          id: 'fc_b1_$i',
          domain: 'Implement and manage user identities',
          front: 'B1 Front $i',
          back: 'B1 Back $i',
          bucket: 1,
        ));
      }
      for (int i = 0; i < 5; i++) {
        cards.add(Flashcard(
          id: 'fc_b2_$i',
          domain: 'Implement and manage user identities',
          front: 'B2 Front $i',
          back: 'B2 Back $i',
          bucket: 2,
        ));
      }
      for (int i = 0; i < 5; i++) {
        cards.add(Flashcard(
          id: 'fc_b3_$i',
          domain: 'Implement and manage user identities',
          front: 'B3 Front $i',
          back: 'B3 Back $i',
          bucket: 3,
        ));
      }

      await db.batchInsertFlashcards(cards);

      final selected = await engine.pickFlashcardsForReview(count: 6);
      expect(selected.length, 6);

      final box1Count = selected.where((c) => c.bucket == 1).length;
      final box2Count = selected.where((c) => c.bucket == 2).length;
      final box3Count = selected.where((c) => c.bucket == 3).length;

      expect(box1Count, inInclusiveRange(3, 5));
      expect(box2Count, inInclusiveRange(1, 3));
      expect(box1Count + box2Count + box3Count, 6);
    });

    test('reviewCard promotes on correct and resets on incorrect', () async {
      final card = Flashcard(
        id: 'fc_test',
        domain: 'Implement authentication and access management',
        front: 'Front',
        back: 'Back',
        bucket: 1,
      );
      await db.batchInsertFlashcards([card]);

      final updated1 = await engine.reviewCard(card: card, isCorrect: true);
      expect(updated1.bucket, 2);
      expect(updated1.reviewCount, 1);
      expect(updated1.correctCount, 1);

      final updated2 = await engine.reviewCard(card: updated1, isCorrect: true);
      expect(updated2.bucket, 3);

      final updated3 = await engine.reviewCard(card: updated2, isCorrect: false);
      expect(updated3.bucket, 1);
      expect(updated3.reviewCount, 3);
      expect(updated3.correctCount, 2);

      final stats = await engine.getDeckStats();
      expect(stats.totalCards, 1);
      expect(stats.box1Count, 1);
      expect(stats.totalReviews, 3);
    });
  });
}
