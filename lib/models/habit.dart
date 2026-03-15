class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.frequency,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  /// `daily` | `weekdays` | `weekly`
  final String frequency;
  final String startDate;
  final String createdAt;
  final String updatedAt;

  Habit copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? frequency,
    String? startDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'frequency': frequency,
        'start_date': startDate,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  static Habit fromMap(Map<String, Object?> m) {
    return Habit(
      id: m['id']! as int,
      title: m['title']! as String,
      description: (m['description'] as String?) ?? '',
      category: (m['category'] as String?) ?? 'General',
      frequency: (m['frequency'] as String?) ?? 'daily',
      startDate: m['start_date']! as String,
      createdAt: m['created_at']! as String,
      updatedAt: m['updated_at']! as String,
    );
  }

  static Map<String, Object?> toInsertMap({
    required String title,
    required String description,
    required String category,
    required String frequency,
    required String startDate,
    required String createdAt,
    required String updatedAt,
  }) =>
      {
        'title': title,
        'description': description,
        'category': category,
        'frequency': frequency,
        'start_date': startDate,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
