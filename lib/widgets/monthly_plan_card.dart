import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity_planning_app/providers/plan_provider.dart';
import 'package:productivity_planning_app/models/plan.dart';
import 'package:intl/intl.dart';

class MonthlyPlanCard extends StatelessWidget {
  final MonthlyPlan monthlyPlan;
  final String planId;

  const MonthlyPlanCard({
    super.key,
    required this.monthlyPlan,
    required this.planId,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final isCurrentMonth = _isCurrentMonth();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: monthlyPlan.isCompleted
              ? Colors.green
              : isCurrentMonth
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
          child: Icon(
            monthlyPlan.isCompleted
                ? Icons.check
                : isCurrentMonth
                    ? Icons.play_arrow
                    : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(
          monthlyPlan.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: monthlyPlan.isCompleted
                ? Colors.green
                : isCurrentMonth
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('MMMM yyyy').format(DateTime(monthlyPlan.year, monthlyPlan.month))}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${monthlyPlan.weeklyPlans.where((wp) => wp.isCompleted).length}/${monthlyPlan.weeklyPlans.length} weeks completed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: monthlyPlan.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    monthlyPlan.isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                
                // Weekly Plans
                ...monthlyPlan.weeklyPlans.map((weeklyPlan) => _buildWeeklyPlanTile(
                  context,
                  weeklyPlan,
                )),
                
                // Action Buttons
                if (!monthlyPlan.isCompleted && isCurrentMonth)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showWeeklyPlanDetails(context, monthlyPlan.weeklyPlans.first),
                            icon: const Icon(Icons.visibility),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _completeAllWeeklyPlans(context),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlanTile(BuildContext context, WeeklyPlan weeklyPlan) {
    final weeklyProgress = weeklyPlan.dailyTasks.where((task) => task.isCompleted).length /
        weeklyPlan.dailyTasks.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: weeklyPlan.isCompleted
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
          child: Icon(
            weeklyPlan.isCompleted ? Icons.check : Icons.schedule,
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          weeklyPlan.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd').format(weeklyPlan.startDate)} - ${DateFormat('MMM dd').format(weeklyPlan.endDate)}',
          style: TextStyle(fontSize: 12),
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
            Text(
              '${(weeklyProgress * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () => _showWeeklyPlanDetails(context, weeklyPlan),
      ),
    );
  }

  void _showWeeklyPlanDetails(BuildContext context, WeeklyPlan weeklyPlan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    weeklyPlan.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                weeklyPlan.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Daily Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: weeklyPlan.dailyTasks.length,
                  itemBuilder: (context, index) {
                    final task = weeklyPlan.dailyTasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (value) {
                            if (value == true) {
                              Provider.of<PlanProvider>(context, listen: false)
                                  .completeDailyTask(
                                planId,
                                monthlyPlan.id,
                                weeklyPlan.id,
                                task.id,
                              );
                              Navigator.pop(context);
                            }
                          },
                        ),
                        title: Text(task.title),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy').format(task.date),
                        ),
                        trailing: Text(
                          '${task.estimatedMinutes} min',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeAllWeeklyPlans(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete All Weekly Plans'),
        content: const Text('Are you sure you want to mark all weekly plans in this month as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // This would need to be implemented in the provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Complete All'),
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    if (monthlyPlan.weeklyPlans.isEmpty) return 0.0;
    
    final completedWeeks = monthlyPlan.weeklyPlans.where((wp) => wp.isCompleted).length;
    return completedWeeks / monthlyPlan.weeklyPlans.length;
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return monthlyPlan.month == now.month && monthlyPlan.year == now.year;
  }
}
