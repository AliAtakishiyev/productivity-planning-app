class GlobalStreak {
  final int currentStreak;
  final int bestStreak;
  final DateTime lastCompletedDate;
  final int skipDaysUsedThisMonth;
  final DateTime lastSkipDate;
  final int currentMonth;
  final int currentYear;

  GlobalStreak({
    required this.currentStreak,
    required this.bestStreak,
    required this.lastCompletedDate,
    this.skipDaysUsedThisMonth = 0,
    required this.lastSkipDate,
    required this.currentMonth,
    required this.currentYear,
  });

  GlobalStreak copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCompletedDate,
    int? skipDaysUsedThisMonth,
    DateTime? lastSkipDate,
    int? currentMonth,
    int? currentYear,
  }) {
    return GlobalStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      skipDaysUsedThisMonth: skipDaysUsedThisMonth ?? this.skipDaysUsedThisMonth,
      lastSkipDate: lastSkipDate ?? this.lastSkipDate,
      currentMonth: currentMonth ?? this.currentMonth,
      currentYear: currentYear ?? this.currentYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletedDate': lastCompletedDate.toIso8601String(),
      'skipDaysUsedThisMonth': skipDaysUsedThisMonth,
      'lastSkipDate': lastSkipDate.toIso8601String(),
      'currentMonth': currentMonth,
      'currentYear': currentYear,
    };
  }

  factory GlobalStreak.fromJson(Map<String, dynamic> json) {
    return GlobalStreak(
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      lastCompletedDate: DateTime.parse(json['lastCompletedDate']),
      skipDaysUsedThisMonth: json['skipDaysUsedThisMonth'] ?? 0,
      lastSkipDate: DateTime.parse(json['lastSkipDate']),
      currentMonth: json['currentMonth'] ?? DateTime.now().month,
      currentYear: json['currentYear'] ?? DateTime.now().year,
    );
  }

  // Check if streak is at risk (all tasks not completed today)
  bool get isAtRisk {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    // If last completed was before yesterday, streak is at risk
    return lastCompletedDate.isBefore(yesterday);
  }

  // Check if we can use a skip day
  bool get canUseSkipDay {
    final today = DateTime.now();
    
    // Reset skip count if it's a new month
    if (today.month != currentMonth || today.year != currentYear) {
      return true; // New month, can use skip
    }
    
    return skipDaysUsedThisMonth < 3;
  }

  // Get remaining skip days for current month
  int get remainingSkipDays {
    final today = DateTime.now();
    
    // Reset if it's a new month
    if (today.month != currentMonth || today.year != currentYear) {
      return 3;
    }
    
    return 3 - skipDaysUsedThisMonth;
  }

  // Check if streak should be reset due to too many skips
  bool get shouldResetStreak {
    final today = DateTime.now();
    
    // Reset skip count if it's a new month
    if (today.month != currentMonth || today.year != currentYear) {
      return false;
    }
    
    return skipDaysUsedThisMonth >= 3 && isAtRisk;
  }
}
