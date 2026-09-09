/// Represents a flashcard with Leitner-box spaced repetition tracking.
class Flashcard {
  final String id;
  final String domain;
  final String? subtopic;
  final String front;
  final String back;
  final int bucket; // 1 = Still Shaky, 2 = Reviewing, 3 = Mastered
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final int correctCount;

  const Flashcard({
    required this.id,
    required this.domain,
    this.subtopic,
    required this.front,
    required this.back,
    this.bucket = 1,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.correctCount = 0,
  });

  /// Factory constructor to deserialize from SQLite database map.
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as String,
      domain: map['domain'] as String,
      subtopic: map['subtopic'] as String?,
      front: map['front'] as String,
      back: map['back'] as String,
      bucket: map['bucket'] as int? ?? 1,
      lastReviewedAt: map['last_reviewed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_reviewed_at'] as int)
          : null,
      reviewCount: map['review_count'] as int? ?? 0,
      correctCount: map['correct_count'] as int? ?? 0,
    );
  }

  /// Factory constructor to deserialize from JSON seed asset.
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      domain: json['domain'] as String,
      subtopic: json['subtopic'] as String?,
      front: json['front'] as String,
      back: json['back'] as String,
      bucket: json['bucket'] as int? ?? 1,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.tryParse(json['lastReviewedAt'] as String)
          : null,
      reviewCount: json['reviewCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
    );
  }

  /// Serialize to SQLite database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'domain': domain,
      'subtopic': subtopic,
      'front': front,
      'back': back,
      'bucket': bucket,
      'last_reviewed_at': lastReviewedAt?.millisecondsSinceEpoch,
      'review_count': reviewCount,
      'correct_count': correctCount,
    };
  }

  /// Serialize to standard JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'subtopic': subtopic,
      'front': front,
      'back': back,
      'bucket': bucket,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'reviewCount': reviewCount,
      'correctCount': correctCount,
    };
  }

  /// Returns a new instance updated with a review result.
  Flashcard copyWithReview({required bool isCorrect}) {
    int newBucket = bucket;
    if (isCorrect) {
      newBucket = (bucket < 3) ? bucket + 1 : 3;
    } else {
      newBucket = 1; // Drop back to 'Still Shaky'
    }

    return Flashcard(
      id: id,
      domain: domain,
      subtopic: subtopic,
      front: front,
      back: back,
      bucket: newBucket,
      lastReviewedAt: DateTime.now(),
      reviewCount: reviewCount + 1,
      correctCount: correctCount + (isCorrect ? 1 : 0),
    );
  }
}
