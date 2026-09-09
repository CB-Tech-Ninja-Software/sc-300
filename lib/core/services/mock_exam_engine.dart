import 'dart:math';
import 'package:sc300_prep/core/constants/exam_constants.dart';
import 'package:sc300_prep/core/database/app_database.dart';
import 'package:sc300_prep/core/models/mock_exam.dart';
import 'package:sc300_prep/core/models/question.dart';
import 'package:sc300_prep/core/models/question_attempt.dart';
import 'package:sc300_prep/core/services/gamification_service.dart';

/// Active Mock Exam session tracking questions, responses, timer, and locking rules.
class MockExamSession {
  final String id;
  final DateTime startedAt;
  final int timeLimitSeconds;
  final List<Question> questions;
  int currentQuestionIndex;
  final Map<String, int> answers; // questionId -> selectedIndex
  bool isFinished;

  MockExamSession({
    required this.id,
    required this.startedAt,
    this.timeLimitSeconds = ExamConstants.mockExamTimeLimitSeconds,
    required this.questions,
    this.currentQuestionIndex = 0,
    Map<String, int>? initialAnswers,
    this.isFinished = false,
  }) : answers = initialAnswers ?? {};

  Question? get currentQuestion {
    if (currentQuestionIndex < 0 || currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  int get totalQuestions => questions.length;
  bool get hasAnsweredCurrent => currentQuestion != null && answers.containsKey(currentQuestion!.id);
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;
}

/// Engine managing Mock Exam generation, strict no-going-back flow, and rubric scoring.
class MockExamEngine {
  final AppDatabase database;
  final GamificationService gamificationService;
  final Random _random;

  MockExamEngine({
    AppDatabase? db,
    GamificationService? gamification,
    Random? random,
  })  : database = db ?? AppDatabase.instance,
        gamificationService = gamification ?? GamificationService(db: db ?? AppDatabase.instance),
        _random = random ?? Random();

  /// Starts a new Mock Exam session with 60 questions weighted equally (15 per domain = 25%).
  Future<MockExamSession> startExam({
    List<Question>? questionsPool,
  }) async {
    final pool = questionsPool ?? await database.getAllQuestions();
    final selectedQuestions = _selectMockQuestions(pool);

    final session = MockExamSession(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      startedAt: DateTime.now(),
      timeLimitSeconds: ExamConstants.mockExamTimeLimitSeconds,
      questions: selectedQuestions,
    );

    return session;
  }

  /// Locks in the user's answer for the current question and advances to the next.
  Future<bool> submitAnswer(
    MockExamSession session, {
    required int selectedIndex,
    int timeSpentOnQuestionSeconds = 0,
  }) async {
    if (session.isFinished) return false;
    final currentQ = session.currentQuestion;
    if (currentQ == null) return false;

    session.answers[currentQ.id] = selectedIndex;

    final attempt = QuestionAttempt(
      questionId: currentQ.id,
      selectedIndex: selectedIndex,
      isCorrect: currentQ.isCorrect(selectedIndex),
      attemptedAt: DateTime.now(),
      timeSpentSeconds: timeSpentOnQuestionSeconds,
      mode: 'mock_exam',
    );
    await database.recordAttempt(attempt);

    session.currentQuestionIndex += 1;
    if (session.currentQuestionIndex >= session.totalQuestions) {
      session.isFinished = true;
    }

    return true;
  }

  /// Finalizes the mock exam and computes full domain breakdown and pass/fail status.
  Future<MockExamResult> completeExam(
    MockExamSession session, {
    int? elapsedSecondsOverride,
  }) async {
    session.isFinished = true;
    final completedAt = DateTime.now();

    final int timeSpentSeconds = elapsedSecondsOverride ??
        min(
          session.timeLimitSeconds,
          completedAt.difference(session.startedAt).inSeconds,
        );

    int totalScore = 0;
    final Map<String, int> domainTotal = {};
    final Map<String, int> domainCorrect = {};

    for (final q in session.questions) {
      domainTotal[q.domain] = (domainTotal[q.domain] ?? 0) + 1;

      final selected = session.answers[q.id];
      if (selected != null && q.isCorrect(selected)) {
        totalScore += 1;
        domainCorrect[q.domain] = (domainCorrect[q.domain] ?? 0) + 1;
      }
    }

    final double percentage = session.totalQuestions > 0
        ? (totalScore / session.totalQuestions) * 100.0
        : 0.0;

    final bool isPassed = percentage >= ExamConstants.mockExamPassingScorePercentage;

    final Map<String, DomainScore> domainBreakdown = {};
    domainTotal.forEach((domain, total) {
      final correct = domainCorrect[domain] ?? 0;
      final pct = total > 0 ? (correct / total) * 100.0 : 0.0;
      domainBreakdown[domain] = DomainScore(
        domain: domain,
        totalQuestions: total,
        correctAnswers: correct,
        percentage: pct,
      );
    });

    final result = MockExamResult(
      id: session.id,
      startedAt: session.startedAt,
      completedAt: completedAt,
      timeLimitSeconds: session.timeLimitSeconds,
      timeSpentSeconds: timeSpentSeconds,
      totalQuestions: session.totalQuestions,
      score: totalScore,
      percentage: percentage,
      isPassed: isPassed,
      domainBreakdown: domainBreakdown,
      questionIds: session.questions.map((q) => q.id).toList(),
      userAnswers: session.answers,
    );

    await database.recordMockExam(result);
    await gamificationService.recordMockExamOutcome(isPassed: isPassed, score: totalScore);

    return result;
  }

  /// Selects domain-weighted questions matching 60 total questions across 4 domains (15 each).
  List<Question> _selectMockQuestions(List<Question> pool) {
    const targetCount = ExamConstants.mockExamQuestionCount;
    if (pool.isEmpty) return [];
    if (pool.length <= targetCount) {
      return List<Question>.from(pool)..shuffle(_random);
    }

    final weights = ExamConstants.domainWeights;

    final Map<String, List<Question>> byDomain = {};
    for (final q in pool) {
      byDomain.putIfAbsent(q.domain, () => []).add(q);
    }
    byDomain.forEach((key, list) => list.shuffle(_random));

    final List<Question> selected = [];
    final Set<String> selectedIds = {};

    // 1. First pass: Allocate integer targets based on domain weights
    int remainingCount = targetCount;
    final Map<String, int> targetCounts = {};

    weights.forEach((domain, weight) {
      int domainTarget = (targetCount * weight).round();
      if (domainTarget > remainingCount) domainTarget = remainingCount;
      targetCounts[domain] = domainTarget;
    });

    int sumTargets = targetCounts.values.fold(0, (a, b) => a + b);
    while (sumTargets > targetCount) {
      final largestKey = targetCounts.keys.reduce((a, b) => targetCounts[a]! > targetCounts[b]! ? a : b);
      targetCounts[largestKey] = targetCounts[largestKey]! - 1;
      sumTargets--;
    }

    targetCounts.forEach((domain, target) {
      final available = byDomain[domain] ?? [];
      final toTake = min(target, available.length);
      for (int i = 0; i < toTake; i++) {
        final q = available[i];
        selected.add(q);
        selectedIds.add(q.id);
      }
    });

    // 2. Second pass: Sample remaining from pool
    final remainingPool = pool.where((q) => !selectedIds.contains(q.id)).toList()..shuffle(_random);
    final totalWeight = weights.values.fold(0.0, (a, b) => a + b);

    while (selected.length < targetCount && remainingPool.isNotEmpty) {
      final roll = _random.nextDouble() * totalWeight;
      double cumulative = 0.0;
      String rolledDomain = weights.keys.first;
      for (final entry in weights.entries) {
        cumulative += entry.value;
        if (roll <= cumulative) {
          rolledDomain = entry.key;
          break;
        }
      }

      final matchIndex = remainingPool.indexWhere((q) => q.domain == rolledDomain);
      if (matchIndex != -1) {
        final q = remainingPool.removeAt(matchIndex);
        selected.add(q);
        selectedIds.add(q.id);
      } else {
        final q = remainingPool.removeAt(0);
        selected.add(q);
        selectedIds.add(q.id);
      }
    }

    selected.shuffle(_random);
    return selected;
  }

  Future<List<MockExamResult>> getExamHistory() async {
    return await database.getAllMockExams();
  }
}
