class HabitLog {
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
    required this.notes,
  });

  final int id;
  final int habitId;
  final String date;
  /// `completed` | `missed`
  final String status;
  final String notes;

  // map keys align with sqlite log columns.
  Map<String, Object?> toMap() => {
        'id': id,
        'habit_id': habitId,
        'date': date,
        'status': status,
        'notes': notes,
      };

  static HabitLog fromMap(Map<String, Object?> m) {
    // empty string keeps null notes out of ui rendering.
    return HabitLog(
      id: m['id']! as int,
      habitId: m['habit_id']! as int,
      date: m['date']! as String,
      status: m['status']! as String,
      notes: (m['notes'] as String?) ?? '',
    );
  }
}
