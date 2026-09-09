import 'dart:convert';
import 'package:sc300_prep/core/constants/exam_constants.dart';

/// Represents domain breakdown summary inside a mock exam result.
class DomainScore {
  final String domain;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;

  const DomainScore({
    required this.domain,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
  });

  factory DomainScore.fromMap(Map<String, dynamic> map) {
    return DomainScore(
      domain: map['domain'] as String? ?? '',
      totalQuestions: map['total'] as int? ?? map['totalQuestions'] as int? ?? 0,
      correctAnswers: map['correct'] as int? ?? map['correctAnswers'] as int? ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'domain': domain,
      'total': totalQuestions,
      'correct': correctAnswers,
      'percentage': percentage,
    };
  }
}

/// Represents the state and outcome of a Mock Exam session.
class MockExamResult {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int timeLimitSeconds;
  final int timeSpentSeconds;
  final int totalQuestions;
  final int score; // number correct
  final double percentage;
  final bool isPassed;
  final Map<String, DomainScore> domainBreakdown;
  final List<String> questionIds;
  final Map<String, int> userAnswers; // questionId -> selectedIndex

  const MockExamResult({
    required this.id,
    required this.startedAt,
    this.completedAt,
    this.timeLimitSeconds = ExamConstants.mockExamTimeLimitSeconds,
    this.timeSpentSeconds = 0,
    this.totalQuestions = ExamConstants.mockExamQuestionCount,
    this.score = 0,
    this.percentage = 0.0,
    this.isPassed = false,
    required this.domainBreakdown,
    required this.questionIds,
    required this.userAnswers,
  });

  factory MockExamResult.fromMap(Map<String, dynamic> map) {
    Map<String, DomainScore> breakdown = {};
    if (map['domain_breakdown'] != null) {
      final decoded = jsonDecode(map['domain_breakdown'] as String);
      if (decoded is Map) {
        decoded.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            breakdown[key.toString()] = DomainScore.fromMap(val);
          } else if (val is Map) {
            breakdown[key.toString()] = DomainScore.fromMap(Map<String, dynamic>.from(val));
          }
        });
      }
    }

    List<String> qIds = [];
    if (map['question_ids'] != null) {
      final decoded = jsonDecode(map['question_ids'] as String);
      if (decoded is List) {
        qIds = decoded.map((e) => e.toString()).toList();
      }
    }

    Map<String, int> answers = {};
    if (map['user_answers'] != null) {
      final decoded = jsonDecode(map['user_answers'] as String);
      if (decoded is Map) {
        decoded.forEach((key, val) {
          answers[key.toString()] = val as int;
        });
      }
    }

    return MockExamResult(
      id: map['id'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      timeLimitSeconds: map['time_limit_seconds'] as int? ?? ExamConstants.mockExamTimeLimitSeconds,
      timeSpentSeconds: map['time_spent_seconds'] as int? ?? 0,
      totalQuestions: map['total_questions'] as int? ?? ExamConstants.mockExamQuestionCount,
      score: map['score'] as int? ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      isPassed: (map['is_passed'] as int? ?? 0) == 1,
      domainBreakdown: breakdown,
      questionIds: qIds,
      userAnswers: answers,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> serializedBreakdown = {};
    domainBreakdown.forEach((key, val) {
      serializedBreakdown[key] = val.toMap();
    });

    return {
      'id': id,
      'started_at': startedAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'time_limit_seconds': timeLimitSeconds,
      'time_spent_seconds': timeSpentSeconds,
      'total_questions': totalQuestions,
      'score': score,
      'percentage': percentage,
      'is_passed': isPassed ? 1 : 0,
      'domain_breakdown': jsonEncode(serializedBreakdown),
      'question_ids': jsonEncode(questionIds),
      'user_answers': jsonEncode(userAnswers),
    };
  }
}
