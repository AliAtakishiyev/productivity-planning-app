import 'package:flutter/material.dart';
import 'package:productivity_planning_app/models/plan.dart';
import 'package:productivity_planning_app/models/hourly_schedule.dart';
import 'package:productivity_planning_app/providers/plan_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final DailyTask task;
  final WeeklyPlan weeklyPlan;
  final MonthlyPlan monthlyPlan;
  final Plan plan;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.weeklyPlan,
    required this.monthlyPlan,
    required this.plan,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isHourlyView = false;
  final List<HourlySchedule> _timeSlots = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _actualTimeController = TextEditingController();
  List<HourlySchedule> _savedSchedules = [];

  @override
  void initState() {
    super.initState();
    _initializeTimeSlots();
    _loadSavedData();
  }

  void _initializeTimeSlots() {
    _timeSlots.clear();
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final startTime = DateTime(2024, 1, 1, hour, minute);
        final endTime = startTime.add(const Duration(minutes: 30));
        
        _timeSlots.add(HourlySchedule(
          id: '${hour}_${minute}',
          dailyTaskId: widget.task.id,
          startTime: startTime,
          endTime: endTime,
          taskName: '',
        ));
      }
    }
  }

  Future<void> _loadSavedData() async {
    try {
      // Load saved hourly schedules
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      _savedSchedules = await planProvider.getHourlySchedules(widget.task.id);
      
      // Load task notes and actual time
      _notesController.text = widget.task.notes;
      _actualTimeController.text = widget.task.actualMinutes.toString();
      
      // Populate time slots with saved data
      for (final savedSchedule in _savedSchedules) {
        final timeSlotIndex = _timeSlots.indexWhere((slot) => 
          slot.startTime.hour == savedSchedule.startTime.hour && 
          slot.startTime.minute == savedSchedule.startTime.minute
        );
        
        if (timeSlotIndex != -1) {
          _timeSlots[timeSlotIndex] = savedSchedule;
        }
      }
      
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Toggle between task view and hourly view
          IconButton(
            icon: Icon(_isHourlyView ? Icons.task_alt : Icons.schedule),
            onPressed: () {
              setState(() {
                _isHourlyView = !_isHourlyView;
              });
            },
            tooltip: _isHourlyView ? 'Switch to Task View' : 'Switch to Hourly View',
          ),
        ],
      ),
      body: _isHourlyView ? _buildHourlyView() : _buildTaskView(),
    );
  }

  Widget _buildTaskView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Header Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        widget.task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: widget.task.isCompleted ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Description', widget.task.description),
                  _buildDetailRow('Date', DateFormat('EEEE, MMMM dd, yyyy').format(widget.task.date)),
                  _buildDetailRow('Estimated Time', '${widget.task.estimatedMinutes} minutes'),
                  if (widget.task.actualMinutes > 0)
                    _buildDetailRow('Actual Time', '${widget.task.actualMinutes} minutes'),
                  if (widget.task.notes.isNotEmpty)
                    _buildDetailRow('Notes', widget.task.notes),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Time Tracking Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time Tracking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _actualTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Actual time spent (minutes)',
                            border: OutlineInputBorder(),
                            hintText: 'Enter time in minutes',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _saveTaskDetails,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Notes Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add your notes about this task...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveTaskDetails,
                    child: const Text('Save Notes'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyView() {
    return Column(
      children: [
        // Header with date
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMMM dd, yyyy').format(widget.task.date),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Hourly timeline
        Expanded(
          child: ListView.builder(
            itemCount: _timeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = _timeSlots[index];
              return _buildTimeSlot(timeSlot, index);
            },
          ),
        ),
        
        // Save button
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _saveHourlyTasks,
            icon: const Icon(Icons.save),
            label: const Text('Save Hourly Schedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlot(HourlySchedule timeSlot, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Time display
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              DateFormat('HH:mm').format(timeSlot.startTime),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          
          // Task input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: TextEditingController(text: timeSlot.taskName),
                decoration: const InputDecoration(
                  hintText: 'Add task...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _timeSlots[index] = timeSlot.copyWith(taskName: value);
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _saveHourlyTasks() async {
    // Filter out empty time slots
    final filledTimeSlots = _timeSlots.where((slot) => slot.taskName.isNotEmpty).toList();
    
    if (filledTimeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks to save')),
      );
      return;
    }
    
    try {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      await planProvider.saveHourlySchedule(
        widget.plan.id,
        widget.monthlyPlan.id,
        widget.weeklyPlan.id,
        widget.task.id,
        filledTimeSlots,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${filledTimeSlots.length} time slots'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload saved data
      await _loadSavedData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveTaskDetails() async {
    try {
      final planProvider = Provider.of<PlanProvider>(context, listen: false);
      
      // Save notes
      if (_notesController.text != widget.task.notes) {
        await planProvider.updateTaskNotes(
          widget.plan.id,
          widget.monthlyPlan.id,
          widget.weeklyPlan.id,
          widget.task.id,
          _notesController.text,
        );
      }
      
      // Save actual time
      final actualMinutes = int.tryParse(_actualTimeController.text) ?? 0;
      if (actualMinutes != widget.task.actualMinutes) {
        await planProvider.updateTaskActualTime(
          widget.plan.id,
          widget.monthlyPlan.id,
          widget.weeklyPlan.id,
          widget.task.id,
          actualMinutes,
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task details saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _actualTimeController.dispose();
    super.dispose();
  }
}

