class Plan {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<MonthlyPlan> monthlyPlans;
  final int currentStreak;
  final int bestStreak;
  final DateTime lastCompletedDate;
  final bool isCompleted;

  Plan({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.monthlyPlans,
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.lastCompletedDate,
    this.isCompleted = false,
  });

  Plan copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<MonthlyPlan>? monthlyPlans,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCompletedDate,
    bool? isCompleted,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyPlans: monthlyPlans ?? this.monthlyPlans,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'monthlyPlans': monthlyPlans.map((plan) => plan.toJson()).toList(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletedDate': lastCompletedDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      monthlyPlans: (json['monthlyPlans'] as List)
          .map((plan) => MonthlyPlan.fromJson(plan))
          .toList(),
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      lastCompletedDate: DateTime.parse(json['lastCompletedDate']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class MonthlyPlan {
  final String id;
  final String title;
  final String description;
  final int month;
  final int year;
  final List<WeeklyPlan> weeklyPlans;
  final bool isCompleted;

  MonthlyPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.month,
    required this.year,
    required this.weeklyPlans,
    this.isCompleted = false,
  });

  MonthlyPlan copyWith({
    String? id,
    String? title,
    String? description,
    int? month,
    int? year,
    List<WeeklyPlan>? weeklyPlans,
    bool? isCompleted,
  }) {
    return MonthlyPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      month: month ?? this.month,
      year: year ?? this.year,
      weeklyPlans: weeklyPlans ?? this.weeklyPlans,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'month': month,
      'year': year,
      'weeklyPlans': weeklyPlans.map((plan) => plan.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }

  factory MonthlyPlan.fromJson(Map<String, dynamic> json) {
    return MonthlyPlan(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      month: json['month'],
      year: json['year'],
      weeklyPlans: (json['weeklyPlans'] as List)
          .map((plan) => WeeklyPlan.fromJson(plan))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class WeeklyPlan {
  final String id;
  final String title;
  final String description;
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyTask> dailyTasks;
  final bool isCompleted;

  WeeklyPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.dailyTasks,
    this.isCompleted = false,
  });

  WeeklyPlan copyWith({
    String? id,
    String? title,
    String? description,
    int? weekNumber,
    DateTime? startDate,
    DateTime? endDate,
    List<DailyTask>? dailyTasks,
    bool? isCompleted,
  }) {
    return WeeklyPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      weekNumber: weekNumber ?? this.weekNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'weekNumber': weekNumber,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dailyTasks': dailyTasks.map((task) => task.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      weekNumber: json['weekNumber'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      dailyTasks: (json['dailyTasks'] as List)
          .map((task) => DailyTask.fromJson(task))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final bool isCompleted;
  final int estimatedMinutes;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isCompleted = false,
    this.estimatedMinutes = 30,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
    int? estimatedMinutes,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      isCompleted: json['isCompleted'] ?? false,
      estimatedMinutes: json['estimatedMinutes'] ?? 30,
    );
  }
}
