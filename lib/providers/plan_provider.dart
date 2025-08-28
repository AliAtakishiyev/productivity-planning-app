import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/plan.dart';

class PlanProvider with ChangeNotifier {
  List<Plan> _plans = [];
  Plan? _selectedPlan;
  int _totalStreak = 0;
  int _bestTotalStreak = 0;

  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;
  int get totalStreak => _totalStreak;
  int get bestTotalStreak => _bestTotalStreak;

  PlanProvider() {
    _loadPlans();
    _loadStreaks();
  }

  Future<void> _loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final plansJson = prefs.getStringList('plans') ?? [];
    _plans = plansJson
        .map((planJson) => Plan.fromJson(json.decode(planJson)))
        .toList();
    notifyListeners();
  }

  Future<void> _savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    final plansJson = _plans
        .map((plan) => json.encode(plan.toJson()))
        .toList();
    await prefs.setStringList('plans', plansJson);
  }

  Future<void> _loadStreaks() async {
    final prefs = await SharedPreferences.getInstance();
    _totalStreak = prefs.getInt('totalStreak') ?? 0;
    _bestTotalStreak = prefs.getInt('bestTotalStreak') ?? 0;
    notifyListeners();
  }

  Future<void> _saveStreaks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalStreak', _totalStreak);
    await prefs.setInt('bestTotalStreak', _bestTotalStreak);
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
        for (int day = 0; day < 7; day++) {
          final taskDate = weekStartDate.add(Duration(days: day));
          final shouldAddTask = taskDate.isBefore(monthEndDate.add(const Duration(days: 1)));
          if (shouldAddTask) {
            dailyTasks.add(DailyTask(
              id: '${monthDate.millisecondsSinceEpoch}_${week}_$day',
              title: 'Task ${day + 1}',
              description: 'Complete this task to progress',
              date: taskDate,
            ));
          }
        }
        
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
    await _savePlans();
    notifyListeners();
  }

  Future<void> updatePlan(Plan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _plans[index] = plan;
      await _savePlans();
      notifyListeners();
    }
  }

  Future<void> deletePlan(String planId) async {
    _plans.removeWhere((plan) => plan.id == planId);
    if (_selectedPlan?.id == planId) {
      _selectedPlan = null;
    }
    await _savePlans();
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
    await _savePlans();
    notifyListeners();
  }

  Future<void> _updateStreak(Plan plan) async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (plan.lastCompletedDate.isAtSameMomentAs(yesterday)) {
      // Continue streak
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
      
      _totalStreak = newStreak;
      if (newStreak > _bestTotalStreak) {
        _bestTotalStreak = newStreak;
      }
      
      await _saveStreaks();
    } else if (plan.lastCompletedDate.isBefore(yesterday)) {
      // Break streak
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
      
      _totalStreak = 1;
      await _saveStreaks();
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
      
      _totalStreak = 0;
      _saveStreaks();
      notifyListeners();
    }
  }
}
