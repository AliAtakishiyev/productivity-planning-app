import 'package:flutter/foundation.dart';
import '../models/plan.dart';
import '../models/hourly_schedule.dart';
import '../models/global_streak.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class PlanProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  List<Plan> _plans = [];
  Plan? _selectedPlan;
  GlobalStreak? _globalStreak;
  bool _isInitialized = false;

  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;
  GlobalStreak? get globalStreak => _globalStreak;
  int get totalStreak => _globalStreak?.currentStreak ?? 0;
  int get bestTotalStreak => _globalStreak?.bestStreak ?? 0;
  bool get isInitialized => _isInitialized;

  PlanProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    try {
      if (kDebugMode) {
        print('PlanProvider: Starting initialization...');
      }
      
      // Initialize notification service
      await _notificationService.initialize();
      
      await _loadPlans();
      await _loadGlobalStreak();
      await _setupNotifications();
      
      _isInitialized = true;
      if (kDebugMode) {
        print('PlanProvider: Initialization completed successfully');
        print('PlanProvider: Loaded ${_plans.length} plans');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing PlanProvider: $e');
      }
    }
  }

  Future<void> _loadPlans() async {
    try {
      if (kDebugMode) {
        print('PlanProvider: Loading plans from database...');
      }
      _plans = await _databaseService.getAllPlans();
      if (kDebugMode) {
        print('PlanProvider: Successfully loaded ${_plans.length} plans');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading plans: $e');
      }
    }
  }

  Future<void> _loadGlobalStreak() async {
    _globalStreak = await _databaseService.getGlobalStreak();
    if (_globalStreak == null) {
      await _databaseService.initializeGlobalStreak();
      _globalStreak = await _databaseService.getGlobalStreak();
    }
    notifyListeners();
  }

  Future<void> _setupNotifications() async {
    // Schedule daily reminder
    await _notificationService.scheduleDailyReminder();
    
    // Schedule plan-specific reminders for each active plan
    for (final plan in _plans.where((p) => !p.isCompleted)) {
      await _notificationService.schedulePlanReminder(plan.title, plan.hashCode);
    }
    
    // Schedule end of day warning
    await _notificationService.showEndOfDayWarning();
  }

  void selectPlan(Plan plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  Future<void> createPlan({
    required String title,
    required String description,
    required DateTime startDate,
    required int durationMonths,
  }) async {
    final endDate = DateTime(
      startDate.year,
      startDate.month + durationMonths,
      startDate.day,
    );

    final monthlyPlans = <MonthlyPlan>[];
    
    for (int i = 0; i < durationMonths; i++) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);
      final monthEndDate = DateTime(startDate.year, startDate.month + i + 1, 0);
      
      final weeklyPlans = <WeeklyPlan>[];
      final weeksInMonth = ((monthEndDate.difference(monthDate).inDays + 1) / 7).ceil();
      
      for (int week = 0; week < weeksInMonth; week++) {
        final weekStartDate = monthDate.add(Duration(days: week * 7));
        final weekEndDate = weekStartDate.add(const Duration(days: 6));
        
        final dailyTasks = <DailyTask>[];
        // No default tasks - users will add their own tasks
        
        weeklyPlans.add(WeeklyPlan(
          id: '${monthDate.millisecondsSinceEpoch}_$week',
          title: 'Week ${week + 1}',
          description: 'Complete all daily tasks for this week',
          weekNumber: week + 1,
          startDate: weekStartDate,
          endDate: weekEndDate,
          dailyTasks: dailyTasks,
        ));
      }
      
      monthlyPlans.add(MonthlyPlan(
        id: '${monthDate.millisecondsSinceEpoch}',
        title: 'Month ${i + 1}',
        description: 'Complete all weekly plans for this month',
        month: monthDate.month,
        year: monthDate.year,
        weeklyPlans: weeklyPlans,
      ));
    }

    final plan = Plan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      monthlyPlans: monthlyPlans,
      lastCompletedDate: startDate.subtract(const Duration(days: 1)),
    );

    _plans.add(plan);
    await _databaseService.insertPlan(plan);
    notifyListeners();
  }

  Future<void> updatePlan(Plan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _plans[index] = plan;
      await _databaseService.updatePlan(plan);
      notifyListeners();
    }
  }

  Future<void> deletePlan(String planId) async {
    _plans.removeWhere((plan) => plan.id == planId);
    if (_selectedPlan?.id == planId) {
      _selectedPlan = null;
    }
    await _databaseService.deletePlan(planId);
    notifyListeners();
  }

  Future<void> completeDailyTask(String planId, String monthlyPlanId, String weeklyPlanId, String taskId) async {
    final planIndex = _plans.indexWhere((p) => p.id == planId);
    if (planIndex == -1) return;

    final plan = _plans[planIndex];
    final monthlyPlanIndex = plan.monthlyPlans.indexWhere((mp) => mp.id == monthlyPlanId);
    if (monthlyPlanIndex == -1) return;

    final monthlyPlan = plan.monthlyPlans[monthlyPlanIndex];
    final weeklyPlanIndex = monthlyPlan.weeklyPlans.indexWhere((wp) => wp.id == weeklyPlanId);
    if (weeklyPlanIndex == -1) return;

    final weeklyPlan = monthlyPlan.weeklyPlans[weeklyPlanIndex];
    final taskIndex = weeklyPlan.dailyTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    // Complete the task
    final updatedTask = weeklyPlan.dailyTasks[taskIndex].copyWith(isCompleted: true);
    final updatedWeeklyPlan = weeklyPlan.copyWith(
      dailyTasks: [
        ...weeklyPlan.dailyTasks.take(taskIndex),
        updatedTask,
        ...weeklyPlan.dailyTasks.skip(taskIndex + 1),
      ],
    );

    // Check if weekly plan is completed
    final isWeeklyCompleted = updatedWeeklyPlan.dailyTasks.every((task) => task.isCompleted);
    final updatedWeeklyPlanFinal = updatedWeeklyPlan.copyWith(isCompleted: isWeeklyCompleted);

    // Update weekly plans
    final updatedMonthlyPlan = monthlyPlan.copyWith(
      weeklyPlans: [
        ...monthlyPlan.weeklyPlans.take(weeklyPlanIndex),
        updatedWeeklyPlanFinal,
        ...monthlyPlan.weeklyPlans.skip(weeklyPlanIndex + 1),
      ],
    );

    // Check if monthly plan is completed
    final isMonthlyCompleted = updatedMonthlyPlan.weeklyPlans.every((wp) => wp.isCompleted);
    final updatedMonthlyPlanFinal = updatedMonthlyPlan.copyWith(isCompleted: isMonthlyCompleted);

    // Update monthly plans
    final updatedPlan = plan.copyWith(
      monthlyPlans: [
        ...plan.monthlyPlans.take(monthlyPlanIndex),
        updatedMonthlyPlanFinal,
        ...plan.monthlyPlans.skip(monthlyPlanIndex + 1),
      ],
    );

    // Check if entire plan is completed
    final isPlanCompleted = updatedPlan.monthlyPlans.every((mp) => mp.isCompleted);
    final finalPlan = updatedPlan.copyWith(isCompleted: isPlanCompleted);

    // Update streak
    await _updateStreak(plan);

    _plans[planIndex] = finalPlan;
    if (_selectedPlan?.id == planId) {
      _selectedPlan = finalPlan;
    }
    await _databaseService.updatePlan(finalPlan);
    notifyListeners();
  }

  Future<void> _updateStreak(Plan plan) async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (plan.lastCompletedDate.isAtSameMomentAs(yesterday)) {
      // Continue per-task streak
      final newStreak = plan.currentStreak + 1;
      final newBestStreak = newStreak > plan.bestStreak ? newStreak : plan.bestStreak;
      
      final updatedPlan = plan.copyWith(
        currentStreak: newStreak,
        bestStreak: newBestStreak,
        lastCompletedDate: today,
      );
      
      final planIndex = _plans.indexWhere((p) => p.id == plan.id);
      if (planIndex != -1) {
        _plans[planIndex] = updatedPlan;
      }
      
      if (_selectedPlan?.id == plan.id) {
        _selectedPlan = updatedPlan;
      }
      
      await _databaseService.updatePlan(updatedPlan);
      
      // Check if all active plans are completed for today
      await _checkGlobalStreakUpdate();
      
    } else if (plan.lastCompletedDate.isBefore(yesterday)) {
      // Break per-task streak
      final updatedPlan = plan.copyWith(
        currentStreak: 1,
        lastCompletedDate: today,
      );
      
      final planIndex = _plans.indexWhere((p) => p.id == plan.id);
      if (planIndex != -1) {
        _plans[planIndex] = updatedPlan;
      }
      
      if (_selectedPlan?.id == plan.id) {
        _selectedPlan = updatedPlan;
      }
      
      await _databaseService.updatePlan(updatedPlan);
    }
  }

  Future<void> _checkGlobalStreakUpdate() async {
    if (_globalStreak == null) return;
    
    final today = DateTime.now();
    final activePlans = _plans.where((p) => !p.isCompleted).toList();
    
    // Filter plans that have tasks for today
    final plansWithTasksToday = activePlans.where((plan) {
      // Check if any weekly plan in any monthly plan has tasks for today
      for (final monthlyPlan in plan.monthlyPlans) {
        for (final weeklyPlan in monthlyPlan.weeklyPlans) {
          final todayNormalized = DateTime(today.year, today.month, today.day);
          final hasTasksForToday = weeklyPlan.dailyTasks.any((task) {
            final taskDateNormalized = DateTime(task.date.year, task.date.month, task.date.day);
            return taskDateNormalized.isAtSameMomentAs(todayNormalized);
          });
          if (hasTasksForToday) return true;
        }
      }
      return false;
    }).toList();
    
    // If no plans have tasks for today, don't update streak
    if (plansWithTasksToday.isEmpty) return;
    
    // Check if all plans with tasks today have been completed today
    final allPlansCompletedToday = plansWithTasksToday.every((plan) {
      return plan.lastCompletedDate.year == today.year &&
             plan.lastCompletedDate.month == today.month &&
             plan.lastCompletedDate.day == today.day;
    });
    
    if (allPlansCompletedToday) {
      // All plans with tasks completed today - update global streak
      await _updateGlobalStreak(true);
    }
  }

  Future<void> _updateGlobalStreak(bool completedToday) async {
    if (_globalStreak == null) return;
    
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (completedToday) {
      // User completed all tasks today
      if (_globalStreak!.lastCompletedDate.year == yesterday.year &&
          _globalStreak!.lastCompletedDate.month == yesterday.month &&
          _globalStreak!.lastCompletedDate.day == yesterday.day) {
        // Continue global streak
        final newStreak = _globalStreak!.currentStreak + 1;
        final newBestStreak = newStreak > _globalStreak!.bestStreak ? newStreak : _globalStreak!.bestStreak;
        
        _globalStreak = _globalStreak!.copyWith(
          currentStreak: newStreak,
          bestStreak: newBestStreak,
          lastCompletedDate: today,
        );
        
        // Check for milestone notifications
        if (newStreak == 7 || newStreak == 30 || newStreak == 100) {
          await _notificationService.showStreakMilestoneNotification(newStreak);
        }
        
      } else if (_globalStreak!.lastCompletedDate.isBefore(yesterday)) {
        // Start new streak
        _globalStreak = _globalStreak!.copyWith(
          currentStreak: 1,
          lastCompletedDate: today,
        );
      }
    } else {
      // User didn't complete all tasks today
      // Skip day logic is now handled automatically in checkEndOfDay()
      // This method only handles immediate streak updates when tasks are completed
    }
    
    await _databaseService.updateGlobalStreak(_globalStreak!);
    notifyListeners();
  }

  // Method to automatically use a skip day after 24 hours
  Future<void> _autoUseSkipDay() async {
    if (_globalStreak == null) return;
    
    final today = DateTime.now();
    
    if (_globalStreak!.canUseSkipDay) {
      final newSkipCount = _globalStreak!.skipDaysUsedThisMonth + 1;
      
      _globalStreak = _globalStreak!.copyWith(
        skipDaysUsedThisMonth: newSkipCount,
        lastSkipDate: today,
        currentMonth: today.month,
        currentYear: today.year,
      );
      
      await _databaseService.updateGlobalStreak(_globalStreak!);
      
      // Show skip day notification
      await _notificationService.showSkipDayNotification(
        newSkipCount,
        _globalStreak!.remainingSkipDays,
      );
      
      notifyListeners();
    } else {
      // No more skip days - reset streak
      _globalStreak = _globalStreak!.copyWith(
        currentStreak: 0,
        lastCompletedDate: today,
      );
      
      await _databaseService.updateGlobalStreak(_globalStreak!);
      
      // Show streak lost notification
      await _notificationService.showStreakLostNotification();
      
      notifyListeners();
    }
  }

  // Method to check end of day and handle streak logic
  Future<void> checkEndOfDay() async {
    if (_globalStreak == null) return;
    
    final today = DateTime.now();
    final activePlans = _plans.where((p) => !p.isCompleted).toList();
    
    // Filter plans that have tasks for today
    final plansWithTasksToday = activePlans.where((plan) {
      // Check if any weekly plan in any monthly plan has tasks for today
      for (final monthlyPlan in plan.monthlyPlans) {
        for (final weeklyPlan in monthlyPlan.weeklyPlans) {
          final todayNormalized = DateTime(today.year, today.month, today.day);
          final hasTasksForToday = weeklyPlan.dailyTasks.any((task) {
            final taskDateNormalized = DateTime(task.date.year, task.date.month, task.date.day);
            return taskDateNormalized.isAtSameMomentAs(todayNormalized);
          });
          if (hasTasksForToday) return true;
        }
      }
      return false;
    }).toList();
    
    // If no plans have tasks for today, don't check streak
    if (plansWithTasksToday.isEmpty) return;
    
    // Check if all plans with tasks today have been completed today
    final allPlansCompletedToday = plansWithTasksToday.every((plan) {
      return plan.lastCompletedDate.year == today.year &&
             plan.lastCompletedDate.month == today.month &&
             plan.lastCompletedDate.day == today.day;
    });
    
    if (!allPlansCompletedToday) {
      // Check if 24 hours have passed since last completion
      final lastCompleted = _globalStreak!.lastCompletedDate;
      final hoursSinceLastCompletion = today.difference(lastCompleted).inHours;
      
      if (hoursSinceLastCompletion >= 24) {
        // 24 hours have passed, automatically use skip day or reset streak
        await _autoUseSkipDay();
      }
    }
  }

  void resetStreak(String planId) {
    final planIndex = _plans.indexWhere((p) => p.id == planId);
    if (planIndex != -1) {
      final plan = _plans[planIndex];
      final updatedPlan = plan.copyWith(
        currentStreak: 0,
        lastCompletedDate: plan.startDate.subtract(const Duration(days: 1)),
      );
      _plans[planIndex] = updatedPlan;
      
      if (_selectedPlan?.id == planId) {
        _selectedPlan = updatedPlan;
      }
      
      _databaseService.updatePlan(updatedPlan);
      notifyListeners();
    }
  }

  // Reset global streak
  void resetGlobalStreak() {
    if (_globalStreak == null) return;
    
    final today = DateTime.now();
    _globalStreak = _globalStreak!.copyWith(
      currentStreak: 0,
      lastCompletedDate: today,
      skipDaysUsedThisMonth: 0,
      lastSkipDate: today,
      currentMonth: today.month,
      currentYear: today.year,
    );
    
    _databaseService.updateGlobalStreak(_globalStreak!);
    notifyListeners();
  }

  Future<void> addDailyTask(
    String planId,
    String monthlyPlanId,
    String weeklyPlanId,
    String taskTitle,
    DateTime taskDate,
    int estimatedMinutes,
  ) async {
    final planIndex = _plans.indexWhere((p) => p.id == planId);
    if (planIndex == -1) return;

    final plan = _plans[planIndex];
    final monthlyPlanIndex = plan.monthlyPlans.indexWhere((mp) => mp.id == monthlyPlanId);
    if (monthlyPlanIndex == -1) return;

    final monthlyPlan = plan.monthlyPlans[monthlyPlanIndex];
    final weeklyPlanIndex = monthlyPlan.weeklyPlans.indexWhere((wp) => wp.id == weeklyPlanId);
    if (weeklyPlanIndex == -1) return;

    final weeklyPlan = monthlyPlan.weeklyPlans[weeklyPlanIndex];
    
    // Create new daily task
    final newTask = DailyTask(
      id: '${taskDate.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}',
      title: taskTitle,
      description: 'Task added on ${taskDate.toString().split(' ')[0]}',
      date: DateTime(taskDate.year, taskDate.month, taskDate.day), // Ensure same date format
      estimatedMinutes: estimatedMinutes,
    );

    // Update weekly plan with new task
    final updatedWeeklyPlan = weeklyPlan.copyWith(
      dailyTasks: [...weeklyPlan.dailyTasks, newTask],
    );

    // Update monthly plan
    final updatedMonthlyPlan = monthlyPlan.copyWith(
      weeklyPlans: [
        ...monthlyPlan.weeklyPlans.take(weeklyPlanIndex),
        updatedWeeklyPlan,
        ...monthlyPlan.weeklyPlans.skip(weeklyPlanIndex + 1),
      ],
    );

    // Update plan
    final updatedPlan = plan.copyWith(
      monthlyPlans: [
        ...plan.monthlyPlans.take(monthlyPlanIndex),
        updatedMonthlyPlan,
        ...plan.monthlyPlans.skip(monthlyPlanIndex + 1),
      ],
    );

    _plans[planIndex] = updatedPlan;
    if (_selectedPlan?.id == planId) {
      _selectedPlan = updatedPlan;
    }
    await _databaseService.updatePlan(updatedPlan);
    notifyListeners();
  }

  Future<void> deleteDailyTask(
    String planId,
    String monthlyPlanId,
    String weeklyPlanId,
    String taskId,
  ) async {
    final planIndex = _plans.indexWhere((p) => p.id == planId);
    if (planIndex == -1) return;

    final plan = _plans[planIndex];
    final monthlyPlanIndex = plan.monthlyPlans.indexWhere((mp) => mp.id == monthlyPlanId);
    if (monthlyPlanIndex == -1) return;

    final monthlyPlan = plan.monthlyPlans[monthlyPlanIndex];
    final weeklyPlanIndex = monthlyPlan.weeklyPlans.indexWhere((wp) => wp.id == weeklyPlanId);
    if (weeklyPlanIndex == -1) return;

    final weeklyPlan = monthlyPlan.weeklyPlans[weeklyPlanIndex];
    
    // Remove task
    final updatedDailyTasks = weeklyPlan.dailyTasks.where((task) => task.id != taskId).toList();

    // Update weekly plan
    final updatedWeeklyPlan = weeklyPlan.copyWith(
      dailyTasks: updatedDailyTasks,
    );

    // Update monthly plan
    final updatedMonthlyPlan = monthlyPlan.copyWith(
      weeklyPlans: [
        ...monthlyPlan.weeklyPlans.take(weeklyPlanIndex),
        updatedWeeklyPlan,
        ...monthlyPlan.weeklyPlans.skip(weeklyPlanIndex + 1),
      ],
    );

    // Update plan
    final updatedPlan = plan.copyWith(
      monthlyPlans: [
        ...plan.monthlyPlans.take(monthlyPlanIndex),
        updatedMonthlyPlan,
        ...plan.monthlyPlans.skip(monthlyPlanIndex + 1),
      ],
    );

    _plans[planIndex] = updatedPlan;
    if (_selectedPlan?.id == planId) {
      _selectedPlan = updatedPlan;
    }
    
    // Delete from database
    await _databaseService.deleteDailyTask(taskId);
    await _databaseService.updatePlan(updatedPlan);
    notifyListeners();
  }

  // New methods for comprehensive task management
  Future<void> updateTaskNotes(
    String planId,
    String monthlyPlanId,
    String weeklyPlanId,
    String taskId,
    String notes,
  ) async {
    final planIndex = _plans.indexWhere((p) => p.id == planId);
    if (planIndex == -1) return;

    final plan = _plans[planIndex];
    final monthlyPlanIndex = plan.monthlyPlans.indexWhere((mp) => mp.id == monthlyPlanId);
    if (monthlyPlanIndex == -1) return;

    final monthlyPlan = plan.monthlyPlans[monthlyPlanIndex];
    final weeklyPlanIndex = monthlyPlan.weeklyPlans.indexWhere((wp) => wp.id == weeklyPlanId);
    if (weeklyPlanIndex == -1) return;

    final weeklyPlan = monthlyPlan.weeklyPlans[weeklyPlanIndex];
    final taskIndex = weeklyPlan.dailyTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    // Update task notes
    final updatedTask = weeklyPlan.dailyTasks[taskIndex].copyWith(notes: notes);
    final updatedDailyTasks = [
      ...weeklyPlan.dailyTasks.take(taskIndex),
      updatedTask,
      ...weeklyPlan.dailyTasks.skip(taskIndex + 1),
    ];

    // Update weekly plan
    final updatedWeeklyPlan = weeklyPlan.copyWith(
      dailyTasks: updatedDailyTasks,
    );

    // Update monthly plan
    final updatedMonthlyPlan = monthlyPlan.copyWith(
      weeklyPlans: [
        ...monthlyPlan.weeklyPlans.take(weeklyPlanIndex),
        updatedWeeklyPlan,
        ...monthlyPlan.weeklyPlans.skip(weeklyPlanIndex + 1),
      ],
    );

    // Update plan
    final updatedPlan = plan.copyWith(
      monthlyPlans: [
        ...plan.monthlyPlans.take(monthlyPlanIndex),
        updatedMonthlyPlan,
        ...plan.monthlyPlans.skip(monthlyPlanIndex + 1),
      ],
    );

    _plans[planIndex] = updatedPlan;
    if (_selectedPlan?.id == planId) {
      _selectedPlan = updatedPlan;
    }
    
    // Update in database
    await _databaseService.updateDailyTask(updatedTask);
    await _databaseService.updatePlan(updatedPlan);
    notifyListeners();
  }

  Future<void> updateTaskActualTime(
    String planId,
    String monthlyPlanId,
    String weeklyPlanId,
    String taskId,
    int actualMinutes,
  ) async {
    final planIndex = _plans.indexWhere((p) => p.id == planId);
    if (planIndex == -1) return;

    final plan = _plans[planIndex];
    final monthlyPlanIndex = plan.monthlyPlans.indexWhere((mp) => mp.id == monthlyPlanId);
    if (monthlyPlanIndex == -1) return;

    final monthlyPlan = plan.monthlyPlans[monthlyPlanIndex];
    final weeklyPlanIndex = monthlyPlan.weeklyPlans.indexWhere((wp) => wp.id == weeklyPlanId);
    if (weeklyPlanIndex == -1) return;

    final weeklyPlan = monthlyPlan.weeklyPlans[weeklyPlanIndex];
    final taskIndex = weeklyPlan.dailyTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    // Update task actual time
    final updatedTask = weeklyPlan.dailyTasks[taskIndex].copyWith(actualMinutes: actualMinutes);
    final updatedDailyTasks = [
      ...weeklyPlan.dailyTasks.take(taskIndex),
      updatedTask,
      ...weeklyPlan.dailyTasks.skip(taskIndex + 1),
    ];

    // Update weekly plan
    final updatedWeeklyPlan = weeklyPlan.copyWith(
      dailyTasks: updatedDailyTasks,
    );

    // Update monthly plan
    final updatedMonthlyPlan = monthlyPlan.copyWith(
      weeklyPlans: [
        ...monthlyPlan.weeklyPlans.take(weeklyPlanIndex),
        updatedWeeklyPlan,
        ...monthlyPlan.weeklyPlans.skip(weeklyPlanIndex + 1),
      ],
    );

    // Update plan
    final updatedPlan = plan.copyWith(
      monthlyPlans: [
        ...plan.monthlyPlans.take(monthlyPlanIndex),
        updatedMonthlyPlan,
        ...plan.monthlyPlans.skip(monthlyPlanIndex + 1),
      ],
    );

    _plans[planIndex] = updatedPlan;
    if (_selectedPlan?.id == planId) {
      _selectedPlan = updatedPlan;
    }
    
    // Update in database
    await _databaseService.updateDailyTask(updatedTask);
    await _databaseService.updatePlan(updatedPlan);
    notifyListeners();
  }

  // Hourly schedule management
  Future<void> saveHourlySchedule(
    String planId,
    String monthlyPlanId,
    String weeklyPlanId,
    String taskId,
    List<HourlySchedule> schedules,
  ) async {
    // Clear existing schedules for this task
    await _databaseService.deleteHourlySchedule(taskId);
    
    // Insert new schedules
    for (final schedule in schedules) {
      if (schedule.taskName.isNotEmpty) {
        await _databaseService.insertHourlySchedule(
          taskId,
          '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')}',
          '${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}',
          schedule.taskName,
          notes: schedule.notes,
        );
      }
    }
    
    notifyListeners();
  }

  Future<List<HourlySchedule>> getHourlySchedules(String taskId) async {
    try {
      final schedulesData = await _databaseService.getHourlySchedulesForTask(taskId);
      return schedulesData.map((data) => HourlySchedule.fromDatabase(data)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading hourly schedules: $e');
      }
      return [];
    }
  }

  // Data migration from SharedPreferences (if needed)
  Future<void> migrateFromSharedPreferences() async {
    // This method can be used to migrate existing data from SharedPreferences
    // Implementation depends on existing data structure
  }
}
