/// Records an individual attempt on a question or scenario.
class QuestionAttempt {
  final int? id;
  final String questionId;
  final int selectedIndex;
  final bool isCorrect;
  final DateTime attemptedAt;
  final int timeSpentSeconds;
  final String mode; // 'quiz', 'mock_exam', 'scenario'

  const QuestionAttempt({
    this.id,
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.attemptedAt,
    this.timeSpentSeconds = 0,
    required this.mode,
  });

  factory QuestionAttempt.fromMap(Map<String, dynamic> map) {
    return QuestionAttempt(
      id: map['id'] as int?,
      questionId: map['question_id'] as String,
      selectedIndex: map['selected_index'] as int,
      isCorrect: (map['is_correct'] as int) == 1,
      attemptedAt: DateTime.fromMillisecondsSinceEpoch(map['attempted_at'] as int),
      timeSpentSeconds: map['time_spent_seconds'] as int? ?? 0,
      mode: map['mode'] as String? ?? 'quiz',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'question_id': questionId,
      'selected_index': selectedIndex,
      'is_correct': isCorrect ? 1 : 0,
      'attempted_at': attemptedAt.millisecondsSinceEpoch,
      'time_spent_seconds': timeSpentSeconds,
      'mode': mode,
    };
  }
}
