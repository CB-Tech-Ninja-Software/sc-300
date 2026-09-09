import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/question.dart';
import 'package:sc300_prep/core/models/flashcard.dart';
import 'package:sc300_prep/core/models/scenario.dart';
import 'package:sc300_prep/core/models/reference_note.dart';

/// Service to import initial JSON assets into SQLite database.
class SeedImporter {
  final AppDatabase database;

  SeedImporter({AppDatabase? db}) : database = db ?? AppDatabase.instance;

  /// Loads JSON data from assets and populates SQLite tables.
  /// If [forceReload] is true, ignores the seeded flag and re-imports.
  Future<SeedSummary> seedFromAssets({
    bool forceReload = false,
    String? questionsJsonOverride,
    String? flashcardsJsonOverride,
    String? scenariosJsonOverride,
    String? referenceNotesJsonOverride,
  }) async {
    final alreadySeeded = await database.isSeeded();
    final referenceNotesAlreadyPresent = (await database.getAllReferenceNotes()).isNotEmpty;

    if (!forceReload && alreadySeeded && referenceNotesAlreadyPresent) {
      return const SeedSummary(
        questionsCount: 0,
        flashcardsCount: 0,
        scenariosCount: 0,
        referenceNotesCount: 0,
        wasAlreadySeeded: true,
      );
    }

    final skipCoreSources = !forceReload && alreadySeeded;
    int questionsCount = 0;
    int flashcardsCount = 0;
    int scenariosCount = 0;
    int referenceNotesCount = 0;

    if (!skipCoreSources) {
      // 1. Load Questions
      String questionsRaw = questionsJsonOverride ?? '';
      if (questionsRaw.isEmpty) {
        try {
          questionsRaw = await rootBundle.loadString('assets/data/questions.json');
        } catch (_) {
          questionsRaw = '[]';
        }
      }

      final List<dynamic> questionsList = jsonDecode(questionsRaw) as List<dynamic>;
      final List<Question> questions = questionsList
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
      if (questions.isNotEmpty) {
        await database.batchInsertQuestions(questions);
      }
      questionsCount = questions.length;

      // 2. Load Flashcards
      String flashcardsRaw = flashcardsJsonOverride ?? '';
      if (flashcardsRaw.isEmpty) {
        try {
          flashcardsRaw = await rootBundle.loadString('assets/data/flashcards.json');
        } catch (_) {
          flashcardsRaw = '[]';
        }
      }

      final List<dynamic> flashcardsList = jsonDecode(flashcardsRaw) as List<dynamic>;
      final List<Flashcard> flashcards = flashcardsList
          .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList();
      if (flashcards.isNotEmpty) {
        await database.batchInsertFlashcards(flashcards);
      }
      flashcardsCount = flashcards.length;

      // 3. Load Scenarios
      String scenariosRaw = scenariosJsonOverride ?? '';
      if (scenariosRaw.isEmpty) {
        try {
          scenariosRaw = await rootBundle.loadString('assets/data/scenarios.json');
        } catch (_) {
          scenariosRaw = '[]';
        }
      }

      final List<dynamic> scenariosList = jsonDecode(scenariosRaw) as List<dynamic>;
      final List<Scenario> scenarios = scenariosList
          .map((e) => Scenario.fromJson(e as Map<String, dynamic>))
          .toList();
      if (scenarios.isNotEmpty) {
        await database.batchInsertScenarios(scenarios);
      }
      scenariosCount = scenarios.length;
    }

    // 4. Load Reference Notes
    if (forceReload || !referenceNotesAlreadyPresent) {
      String referenceNotesRaw = referenceNotesJsonOverride ?? '';
      if (referenceNotesRaw.isEmpty) {
        try {
          referenceNotesRaw = await rootBundle.loadString('assets/data/reference_notes.json');
        } catch (_) {
          referenceNotesRaw = '[]';
        }
      }

      final List<dynamic> referenceNotesList = jsonDecode(referenceNotesRaw) as List<dynamic>;
      final List<ReferenceNote> referenceNotes = referenceNotesList
          .map((e) => ReferenceNote.fromJson(e as Map<String, dynamic>))
          .toList();
      if (referenceNotes.isNotEmpty) {
        await database.batchInsertReferenceNotes(referenceNotes);
      }
      referenceNotesCount = referenceNotes.length;
    }

    await database.setSeeded(true);

    return SeedSummary(
      questionsCount: questionsCount,
      flashcardsCount: flashcardsCount,
      scenariosCount: scenariosCount,
      referenceNotesCount: referenceNotesCount,
      wasAlreadySeeded: false,
    );
  }
}

class SeedSummary {
  final int questionsCount;
  final int flashcardsCount;
  final int scenariosCount;
  final int referenceNotesCount;
  final bool wasAlreadySeeded;

  const SeedSummary({
    required this.questionsCount,
    required this.flashcardsCount,
    required this.scenariosCount,
    this.referenceNotesCount = 0,
    required this.wasAlreadySeeded,
  });
}
