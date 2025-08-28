import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity_planning_app/providers/plan_provider.dart';
import 'package:productivity_planning_app/models/plan.dart';
import 'package:productivity_planning_app/widgets/monthly_plan_card.dart';
import 'package:intl/intl.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;

  const PlanDetailScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              } else if (value == 'reset') {
                _showResetStreakDialog();
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
                  widget.plan.description,
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
                      DateFormat('MMM dd').format(widget.plan.startDate),
                      Icons.calendar_today,
                    ),
                    const SizedBox(width: 20),
                    _buildOverviewItem(
                      'End',
                      DateFormat('MMM dd').format(widget.plan.endDate),
                      Icons.calendar_month,
                    ),
                    const SizedBox(width: 20),
                    _buildOverviewItem(
                      'Duration',
                      '${widget.plan.monthlyPlans.length} months',
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
                            '${widget.plan.currentStreak} day streak',
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
                      'Best: ${widget.plan.bestStreak} days',
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
                        '${_calculateOverallProgress()}%',
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
                        '${widget.plan.monthlyPlans.where((mp) => mp.isCompleted).length}/${widget.plan.monthlyPlans.length}',
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
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                _buildMonthlyView(),
                _buildWeeklyView(),
                _buildDailyView(),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildMonthlyView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.plan.monthlyPlans.length,
      itemBuilder: (context, index) {
        final monthlyPlan = widget.plan.monthlyPlans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MonthlyPlanCard(
            monthlyPlan: monthlyPlan,
            planId: widget.plan.id,
          ),
        );
      },
    );
  }

  Widget _buildWeeklyView() {
    final allWeeklyPlans = <Widget>[];
    
    for (final monthlyPlan in widget.plan.monthlyPlans) {
      for (final weeklyPlan in monthlyPlan.weeklyPlans) {
        allWeeklyPlans.add(
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
                ),
              ),
              title: Text(weeklyPlan.title),
              subtitle: Text(
                '${DateFormat('MMM dd').format(weeklyPlan.startDate)} - ${DateFormat('MMM dd').format(weeklyPlan.endDate)}',
              ),
              trailing: Text(
                '${weeklyPlan.dailyTasks.where((task) => task.isCompleted).length}/${weeklyPlan.dailyTasks.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: weeklyPlan.isCompleted
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return ListView(children: allWeeklyPlans);
  }

  Widget _buildDailyView() {
    final today = DateTime.now();
    final allDailyTasks = <Widget>[];
    
    for (final monthlyPlan in widget.plan.monthlyPlans) {
      for (final weeklyPlan in monthlyPlan.weeklyPlans) {
        for (final dailyTask in weeklyPlan.dailyTasks) {
          final isRecentTask = dailyTask.date.isAfter(today.subtract(const Duration(days: 7)));
          if (isRecentTask) {
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
                          widget.plan.id,
                          monthlyPlan.id,
                          weeklyPlan.id,
                          dailyTask.id,
                        );
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
                ),
              ),
            );
          }
        }
      }
    }
    
    if (allDailyTasks.isEmpty) {
      return const Center(
        child: Text('No recent daily tasks'),
      );
    }
    
    return ListView(children: allDailyTasks);
  }

  int _calculateOverallProgress() {
    if (widget.plan.monthlyPlans.isEmpty) return 0;
    
    final completedMonths = widget.plan.monthlyPlans.where((mp) => mp.isCompleted).length;
    return ((completedMonths / widget.plan.monthlyPlans.length) * 100).round();
  }

  void _showDeleteDialog() {
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
                  .deletePlan(widget.plan.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetStreakDialog() {
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
                  .resetStreak(widget.plan.id);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
