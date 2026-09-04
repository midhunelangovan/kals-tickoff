class HabitNote {
  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HabitNote({
    required this.id,
    required this.habitId,
    required this.date,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory HabitNote.fromJson(Map<String, dynamic> json) {
    return HabitNote(
      id: (json['id'] as String?) ?? '',
      habitId: (json['habitId'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date,
      'content': content,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
