class HourlySchedule {
  final String id;
  final String dailyTaskId;
  final DateTime startTime;
  final DateTime endTime;
  final String taskName;
  final String notes;

  HourlySchedule({
    required this.id,
    required this.dailyTaskId,
    required this.startTime,
    required this.endTime,
    required this.taskName,
    this.notes = '',
  });

  HourlySchedule copyWith({
    String? id,
    String? dailyTaskId,
    DateTime? startTime,
    DateTime? endTime,
    String? taskName,
    String? notes,
  }) {
    return HourlySchedule(
      id: id ?? this.id,
      dailyTaskId: dailyTaskId ?? this.dailyTaskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      taskName: taskName ?? this.taskName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dailyTaskId': dailyTaskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'taskName': taskName,
      'notes': notes,
    };
  }

  factory HourlySchedule.fromJson(Map<String, dynamic> json) {
    return HourlySchedule(
      id: json['id'],
      dailyTaskId: json['dailyTaskId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      taskName: json['taskName'],
      notes: json['notes'] ?? '',
    );
  }

  factory HourlySchedule.fromDatabase(Map<String, dynamic> dbData) {
    // Parse time strings like "08:00" to DateTime objects
    final startTimeStr = dbData['startTime'] as String;
    final endTimeStr = dbData['endTime'] as String;
    
    final startTime = _parseTimeString(startTimeStr);
    final endTime = _parseTimeString(endTimeStr);
    
    return HourlySchedule(
      id: dbData['id'],
      dailyTaskId: dbData['dailyTaskId'],
      startTime: startTime,
      endTime: endTime,
      taskName: dbData['taskName'],
      notes: dbData['notes'] ?? '',
    );
  }

  static DateTime _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(2024, 1, 1, hour, minute);
  }

  String get timeRange {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}
