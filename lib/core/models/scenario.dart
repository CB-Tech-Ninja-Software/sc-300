import 'dart:convert';

/// Represents a practical sequence / decision troubleshooting scenario.
class Scenario {
  final String id;
  final String domain;
  final String title;
  final String scenarioText;
  final List<String>? steps;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const Scenario({
    required this.id,
    required this.domain,
    required this.title,
    required this.scenarioText,
    this.steps,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Factory constructor from SQLite database map.
  factory Scenario.fromMap(Map<String, dynamic> map) {
    List<String>? parsedSteps;
    if (map['steps'] != null && map['steps'] is String) {
      final decoded = jsonDecode(map['steps'] as String);
      if (decoded is List) {
        parsedSteps = decoded.map((e) => e.toString()).toList();
      }
    }

    List<String> parsedOptions = [];
    if (map['options'] is String) {
      final decoded = jsonDecode(map['options'] as String);
      if (decoded is List) {
        parsedOptions = decoded.map((e) => e.toString()).toList();
      }
    } else if (map['options'] is List) {
      parsedOptions = (map['options'] as List).map((e) => e.toString()).toList();
    }

    return Scenario(
      id: map['id'] as String,
      domain: map['domain'] as String,
      title: map['title'] as String,
      scenarioText: map['scenario_text'] as String? ?? map['scenarioText'] as String? ?? '',
      steps: parsedSteps,
      question: map['question'] as String,
      options: parsedOptions,
      correctIndex: map['correct_index'] as int? ?? map['correctIndex'] as int? ?? 0,
      explanation: map['explanation'] as String,
    );
  }

  /// Factory constructor from JSON seed asset.
  factory Scenario.fromJson(Map<String, dynamic> json) {
    List<String>? parsedSteps;
    if (json['steps'] is List) {
      parsedSteps = (json['steps'] as List).map((e) => e.toString()).toList();
    }

    List<String> parsedOptions = [];
    if (json['options'] is List) {
      parsedOptions = (json['options'] as List).map((e) => e.toString()).toList();
    }

    return Scenario(
      id: json['id'] as String,
      domain: json['domain'] as String,
      title: json['title'] as String,
      scenarioText: json['scenarioText'] as String? ?? json['scenario_text'] as String? ?? '',
      steps: parsedSteps,
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
      'title': title,
      'scenario_text': scenarioText,
      'steps': steps != null ? jsonEncode(steps) : null,
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
      'title': title,
      'scenarioText': scenarioText,
      'steps': steps,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}
