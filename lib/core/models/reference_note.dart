/// Represents a topic summary note in the Reference Library for deep study.
class ReferenceNote {
  final String id;
  final String domain;
  final String topic;
  final String title;
  final String body;
  final String? sourceUrl;
  final bool bookmarked;
  final DateTime? lastReadAt;

  const ReferenceNote({
    required this.id,
    required this.domain,
    required this.topic,
    required this.title,
    required this.body,
    this.sourceUrl,
    this.bookmarked = false,
    this.lastReadAt,
  });

  /// Factory constructor to deserialize from SQLite database map.
  factory ReferenceNote.fromMap(Map<String, dynamic> map) {
    return ReferenceNote(
      id: map['id'] as String,
      domain: map['domain'] as String,
      topic: map['topic'] as String? ?? '',
      title: map['title'] as String,
      body: map['body'] as String,
      sourceUrl: map['source_url'] as String?,
      bookmarked: (map['bookmarked'] as int? ?? 0) == 1,
      lastReadAt: map['last_read_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_read_at'] as int)
          : null,
    );
  }

  /// Factory constructor to deserialize from JSON seed asset.
  factory ReferenceNote.fromJson(Map<String, dynamic> json) {
    return ReferenceNote(
      id: json['id'] as String,
      domain: json['domain'] as String,
      topic: json['topic'] as String? ?? '',
      title: json['title'] as String,
      body: json['body'] as String,
      sourceUrl: json['sourceUrl'] as String? ?? json['source_url'] as String?,
      bookmarked: json['bookmarked'] as bool? ?? false,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.tryParse(json['lastReadAt'] as String)
          : null,
    );
  }

  /// Serialize to SQLite database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'domain': domain,
      'topic': topic,
      'title': title,
      'body': body,
      'source_url': sourceUrl,
      'bookmarked': bookmarked ? 1 : 0,
      'last_read_at': lastReadAt?.millisecondsSinceEpoch,
    };
  }

  /// Serialize to standard JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'topic': topic,
      'title': title,
      'body': body,
      'sourceUrl': sourceUrl,
      'bookmarked': bookmarked,
      'lastReadAt': lastReadAt?.toIso8601String(),
    };
  }

  ReferenceNote copyWith({
    String? id,
    String? domain,
    String? topic,
    String? title,
    String? body,
    String? sourceUrl,
    bool? bookmarked,
    DateTime? lastReadAt,
  }) {
    return ReferenceNote(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      topic: topic ?? this.topic,
      title: title ?? this.title,
      body: body ?? this.body,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      bookmarked: bookmarked ?? this.bookmarked,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}
