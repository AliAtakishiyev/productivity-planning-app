import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity_planning_app/providers/plan_provider.dart';
import 'package:productivity_planning_app/models/plan.dart';
import 'package:productivity_planning_app/widgets/monthly_plan_card.dart';
import 'package:productivity_planning_app/screens/task_detail_screen.dart';
import 'package:intl/intl.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  final WeeklyPlan? selectedWeekPlan;
  final MonthlyPlan? selectedMonthPlan;

  const PlanDetailScreen({
    super.key,
    required this.plan,
    this.selectedWeekPlan,
    this.selectedMonthPlan,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // State variables for week switching
  WeeklyPlan? _selectedWeekPlan;
  MonthlyPlan? _selectedMonthPlan;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Set selected week and month if provided
    if (widget.selectedWeekPlan != null) {
      _selectedWeekPlan = widget.selectedWeekPlan;
    }
    if (widget.selectedMonthPlan != null) {
      _selectedMonthPlan = widget.selectedMonthPlan;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlanProvider>(
      builder: (context, planProvider, child) {
        // Get the updated plan from the provider
        final updatedPlan = planProvider.plans.firstWhere(
          (plan) => plan.id == widget.plan.id,
          orElse: () => widget.plan,
        );
        
        return Scaffold(
          appBar: AppBar(
            title: Text(updatedPlan.title),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(updatedPlan);
                  } else if (value == 'reset') {
                    _showResetStreakDialog(updatedPlan);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Reset Streak'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Plan', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Plan Overview Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      updatedPlan.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildOverviewItem(
                          'Start',
                          DateFormat('MMM dd').format(updatedPlan.startDate),
                          Icons.calendar_today,
                        ),
                        const SizedBox(width: 20),
                        _buildOverviewItem(
                          'End',
                          DateFormat('MMM dd').format(updatedPlan.endDate),
                          Icons.schedule,
                        ),
                        const SizedBox(width: 20),
                        _buildOverviewItem(
                          'Duration',
                          '${updatedPlan.monthlyPlans.length} months',
                          Icons.schedule,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${updatedPlan.currentStreak} day streak',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Best: ${updatedPlan.bestStreak} days',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Progress Overview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Progress',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_calculateOverallProgress(updatedPlan)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completed Months',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${updatedPlan.monthlyPlans.where((mp) => mp.isCompleted).length}/${updatedPlan.monthlyPlans.length}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey[600],
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 2.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  tabs: const [
                    Tab(text: 'Monthly'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Daily'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMonthlyView(updatedPlan),
                    _buildWeeklyView(updatedPlan),
                    _buildDailyView(updatedPlan),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(Plan plan) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: plan.monthlyPlans.length,
      itemBuilder: (context, index) {
        final monthlyPlan = plan.monthlyPlans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MonthlyPlanCard(
            monthlyPlan: monthlyPlan,
            planId: plan.id,
          ),
        );
      },
    );
  }

  Widget _buildDailyView(Plan plan) {
    final today = DateTime.now();
    final allDailyTasks = <Widget>[];
    
    // Use selected week if available, otherwise find the current week's plan
    WeeklyPlan? currentWeekPlan;
    MonthlyPlan? currentMonthPlan;
    
    if (_selectedWeekPlan != null && _selectedMonthPlan != null) {
      currentWeekPlan = _selectedWeekPlan;
      currentMonthPlan = _selectedMonthPlan;
    } else {
      for (final monthlyPlan in plan.monthlyPlans) {
        for (final weeklyPlan in monthlyPlan.weeklyPlans) {
          // Check if this week contains today
          final startDate = weeklyPlan.startDate.subtract(const Duration(days: 1));
          final endDate = weeklyPlan.endDate.add(const Duration(days: 1));
          
          if (today.isAfter(startDate) && today.isBefore(endDate)) {
            currentWeekPlan = weeklyPlan;
            currentMonthPlan = monthlyPlan;
            break;
          }
        }
        if (currentWeekPlan != null) break;
      }
    }
    
    if (currentWeekPlan == null || currentMonthPlan == null) {
      return const Center(
        child: Text('No tasks for current week'),
      );
    }

    // Get all weeks from the current month for week switching
    final currentMonthWeeks = currentMonthPlan.weeklyPlans;
    final currentWeekIndex = currentMonthWeeks.indexOf(currentWeekPlan);
    
    // Show week selector
    allDailyTasks.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: currentWeekIndex > 0 
                ? () => _switchWeek(currentMonthPlan!, currentMonthWeeks[currentWeekIndex - 1])
                : null,
              icon: const Icon(Icons.chevron_left),
              color: currentWeekIndex > 0 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey,
            ),
            Expanded(
              child: Text(
                '${DateFormat('MMM dd').format(currentWeekPlan.startDate)} - ${DateFormat('MMM dd').format(currentWeekPlan.endDate)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: currentWeekIndex < currentMonthWeeks.length - 1 
                ? () => _switchWeek(currentMonthPlan!, currentMonthWeeks[currentWeekIndex + 1])
                : null,
              icon: const Icon(Icons.chevron_right),
              color: currentWeekIndex < currentMonthWeeks.length - 1 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey,
            ),
          ],
        ),
      ),
    );

    // Show today's tasks only
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final todayTasks = currentWeekPlan.dailyTasks.where((task) {
      final taskDateNormalized = DateTime(task.date.year, task.date.month, task.date.day);
      return taskDateNormalized.isAtSameMomentAs(todayNormalized);
    }).toList();

    if (todayTasks.isEmpty) {
      allDailyTasks.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: const Center(
            child: Text(
              'No tasks for today. Add some tasks to get started!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    } else {
      for (final dailyTask in todayTasks) {
        allDailyTasks.add(
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Checkbox(
                value: dailyTask.isCompleted,
                              onChanged: (value) {
                if (value == true) {
                  Provider.of<PlanProvider>(context, listen: false)
                      .completeDailyTask(
                    plan.id,
                    currentMonthPlan!.id,
                    currentWeekPlan!.id,
                    dailyTask.id,
                  );
                }
              },
              ),
              title: Text(dailyTask.title),
              subtitle: Text(
                DateFormat('MMM dd, yyyy').format(dailyTask.date),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${dailyTask.estimatedMinutes} min',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTask(dailyTask, currentMonthPlan!, currentWeekPlan!),
                  ),
                ],
              ),
                          onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(
                    task: dailyTask,
                    weeklyPlan: currentWeekPlan!,
                    monthlyPlan: currentMonthPlan!,
                    plan: plan,
                  ),
                ),
              );
            },
            ),
          ),
        );
      }
    }

    // Add task button
    allDailyTasks.add(
      Container(
        margin: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _addTask(currentMonthPlan!, currentWeekPlan!),
          icon: const Icon(Icons.add),
          label: const Text('Add Task for Today'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
    
    return ListView(children: allDailyTasks);
  }

  Widget _buildWeeklyView(Plan plan) {
    final today = DateTime.now();
    final currentMonthWeeks = <Widget>[];
    
    // Find current month's plan
    MonthlyPlan? currentMonthPlan;
    for (final monthlyPlan in plan.monthlyPlans) {
      if (monthlyPlan.month == today.month && monthlyPlan.year == today.year) {
        currentMonthPlan = monthlyPlan;
        break;
      }
    }
    
    if (currentMonthPlan == null) {
      return const Center(
        child: Text('No weekly plans for current month'),
      );
    }
    
    // Show only current month's weekly plans
    for (final weeklyPlan in currentMonthPlan.weeklyPlans) {
      currentMonthWeeks.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: weeklyPlan.isCompleted
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
              child: Icon(
                weeklyPlan.isCompleted ? Icons.check : Icons.schedule,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(weeklyPlan.title),
            subtitle: Text(
              '${DateFormat('MMM dd').format(weeklyPlan.startDate)} - ${DateFormat('MMM dd').format(weeklyPlan.endDate)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${weeklyPlan.dailyTasks.where((task) => task.isCompleted).length}/${weeklyPlan.dailyTasks.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: weeklyPlan.isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (weeklyPlan.dailyTasks.isEmpty)
                  Text(
                    'No tasks',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            onTap: () {
              _showWeeklyTasksDialog(weeklyPlan, currentMonthPlan!);
            },
          ),
        ),
      );
    }
    
    if (currentMonthWeeks.isEmpty) {
      return const Center(
        child: Text('No weekly plans for this month'),
      );
    }
    
    return ListView(children: currentMonthWeeks);
  }
  
  

  int _calculateOverallProgress(Plan plan) {
    if (plan.monthlyPlans.isEmpty) return 0;
    
    final completedMonths = plan.monthlyPlans.where((mp) => mp.isCompleted).length;
    return ((completedMonths / plan.monthlyPlans.length) * 100).round();
  }

  void _showDeleteDialog(Plan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text('Are you sure you want to delete this plan? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<PlanProvider>(context, listen: false)
                  .deletePlan(plan.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showWeeklyTasksDialog(WeeklyPlan weeklyPlan, MonthlyPlan monthlyPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${weeklyPlan.title} - Daily Tasks'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: weeklyPlan.dailyTasks.length,
            itemBuilder: (context, index) {
              final dailyTask = weeklyPlan.dailyTasks[index];
              return ListTile(
                leading: Checkbox(
                  value: dailyTask.isCompleted,
                  onChanged: (value) {
                    if (value == true) {
                      Provider.of<PlanProvider>(context, listen: false)
                          .completeDailyTask(
                        widget.plan.id,
                        monthlyPlan.id,
                        weeklyPlan.id,
                        dailyTask.id,
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
                title: Text(dailyTask.title),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(dailyTask.date),
                ),
                trailing: Text(
                  '${dailyTask.estimatedMinutes} min',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(
                        task: dailyTask,
                        weeklyPlan: weeklyPlan,
                        monthlyPlan: monthlyPlan,
                        plan: widget.plan,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetStreakDialog(Plan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Streak'),
        content: const Text('Are you sure you want to reset your streak? This will set your current streak to 0.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<PlanProvider>(context, listen: false)
                  .resetStreak(plan.id);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _switchWeek(MonthlyPlan monthlyPlan, WeeklyPlan weeklyPlan) {
    setState(() {
      // This will trigger a rebuild and show the selected week's today's tasks
      // We need to store the selected week in the state
      _selectedWeekPlan = weeklyPlan;
      _selectedMonthPlan = monthlyPlan;
    });
  }

  void _addTask(MonthlyPlan monthlyPlan, WeeklyPlan weeklyPlan) {
    final today = DateTime.now();
    final taskNameController = TextEditingController();
    final estimatedMinutesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task for Today'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: taskNameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: estimatedMinutesController,
              decoration: const InputDecoration(
                labelText: 'Estimated Minutes',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (taskNameController.text.isNotEmpty && 
                  estimatedMinutesController.text.isNotEmpty) {
                final estimatedMinutes = int.tryParse(estimatedMinutesController.text) ?? 30;
                
                Provider.of<PlanProvider>(context, listen: false)
                    .addDailyTask(
                  widget.plan.id,
                  monthlyPlan.id,
                  weeklyPlan.id,
                  taskNameController.text,
                  today,
                  estimatedMinutes,
                );
                
                Navigator.pop(context);
                // No need for setState - Consumer will automatically rebuild
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(DailyTask task, MonthlyPlan monthlyPlan, WeeklyPlan weeklyPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<PlanProvider>(context, listen: false)
                  .deleteDailyTask(
                widget.plan.id,
                monthlyPlan.id,
                weeklyPlan.id,
                task.id,
              );
              
              Navigator.pop(context);
              // No need for setState - Consumer will automatically rebuild
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
