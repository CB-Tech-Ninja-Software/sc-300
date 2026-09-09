import 'dart:convert';

/// Represents a multiple-choice question for quiz or mock exam mode.
class Question {
  final String id;
  final String domain;
  final String? subtopic;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const Question({
    required this.id,
    required this.domain,
    this.subtopic,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Factory constructor to deserialize from SQLite database map.
  factory Question.fromMap(Map<String, dynamic> map) {
    List<String> parsedOptions = [];
    if (map['options'] is String) {
      final decoded = jsonDecode(map['options'] as String);
      if (decoded is List) {
        parsedOptions = decoded.map((e) => e.toString()).toList();
      }
    } else if (map['options'] is List) {
      parsedOptions = (map['options'] as List).map((e) => e.toString()).toList();
    }

    return Question(
      id: map['id'] as String,
      domain: map['domain'] as String,
      subtopic: map['subtopic'] as String?,
      question: map['question'] as String,
      options: parsedOptions,
      correctIndex: map['correct_index'] as int? ?? map['correctIndex'] as int? ?? 0,
      explanation: map['explanation'] as String,
    );
  }

  /// Factory constructor to deserialize from JSON asset.
  factory Question.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    if (json['options'] is List) {
      parsedOptions = (json['options'] as List).map((e) => e.toString()).toList();
    }

    return Question(
      id: json['id'] as String,
      domain: json['domain'] as String,
      subtopic: json['subtopic'] as String?,
      question: json['question'] as String,
      options: parsedOptions,
      correctIndex: json['correctIndex'] as int? ?? json['correct_index'] as int? ?? 0,
      explanation: json['explanation'] as String,
    );
  }

  /// Serialize to SQLite database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'domain': domain,
      'subtopic': subtopic,
      'question': question,
      'options': jsonEncode(options),
      'correct_index': correctIndex,
      'explanation': explanation,
    };
  }

  /// Serialize to standard JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'subtopic': subtopic,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;
}
