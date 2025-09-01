import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plan.dart';
import '../models/global_streak.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'productivity_planner.db');

    if (kDebugMode) {
      print('Initializing database at: $path');
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      print('Creating database tables...');
    }
    
    // Plans table
    await db.execute('''
      CREATE TABLE plans (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        currentStreak INTEGER DEFAULT 0,
        bestStreak INTEGER DEFAULT 0,
        lastCompletedDate TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0
      )
    ''');

    // Global streak table
    await db.execute('''
      CREATE TABLE global_streak (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currentStreak INTEGER DEFAULT 0,
        bestStreak INTEGER DEFAULT 0,
        lastCompletedDate TEXT NOT NULL,
        skipDaysUsedThisMonth INTEGER DEFAULT 0,
        lastSkipDate TEXT NOT NULL,
        currentMonth INTEGER NOT NULL,
        currentYear INTEGER NOT NULL
      )
    ''');

    // Monthly plans table
    await db.execute('''
      CREATE TABLE monthly_plans (
        id TEXT PRIMARY KEY,
        planId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        FOREIGN KEY (planId) REFERENCES plans (id) ON DELETE CASCADE
      )
    ''');

    // Weekly plans table
    await db.execute('''
      CREATE TABLE weekly_plans (
        id TEXT PRIMARY KEY,
        monthlyPlanId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        weekNumber INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        FOREIGN KEY (monthlyPlanId) REFERENCES monthly_plans (id) ON DELETE CASCADE
      )
    ''');

    // Daily tasks table
    await db.execute('''
      CREATE TABLE daily_tasks (
        id TEXT PRIMARY KEY,
        weeklyPlanId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        estimatedMinutes INTEGER DEFAULT 30,
        actualMinutes INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (weeklyPlanId) REFERENCES weekly_plans (id) ON DELETE CASCADE
      )
    ''');

    // Hourly schedules table
    await db.execute('''
      CREATE TABLE hourly_schedules (
        id TEXT PRIMARY KEY,
        dailyTaskId TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        taskName TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (dailyTaskId) REFERENCES daily_tasks (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_plans_start_date ON plans (startDate)');
    await db.execute('CREATE INDEX idx_monthly_plans_plan_id ON monthly_plans (planId)');
    await db.execute('CREATE INDEX idx_weekly_plans_monthly_id ON weekly_plans (monthlyPlanId)');
    await db.execute('CREATE INDEX idx_daily_tasks_weekly_id ON daily_tasks (weeklyPlanId)');
    await db.execute('CREATE INDEX idx_daily_tasks_date ON daily_tasks (date)');
    await db.execute('CREATE INDEX idx_hourly_schedules_task_id ON hourly_schedules (dailyTaskId)');
    
    if (kDebugMode) {
      print('Database tables created successfully');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }
    
    if (oldVersion < 2) {
      // Add global streak table
      await db.execute('''
        CREATE TABLE global_streak (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          currentStreak INTEGER DEFAULT 0,
          bestStreak INTEGER DEFAULT 0,
          lastCompletedDate TEXT NOT NULL,
          skipDaysUsedThisMonth INTEGER DEFAULT 0,
          lastSkipDate TEXT NOT NULL,
          currentMonth INTEGER NOT NULL,
          currentYear INTEGER NOT NULL
        )
      ''');
      
      if (kDebugMode) {
        print('Added global_streak table');
      }
    }
    
    if (oldVersion < 3) {
      // Remove default tasks (tasks with titles like "Task 1", "Task 2", etc.)
      await db.execute('''
        DELETE FROM daily_tasks 
        WHERE title LIKE 'Task %' OR title LIKE 'Complete this task to progress'
      ''');
      
      if (kDebugMode) {
        print('Removed default tasks from database');
      }
    }
  }

  // Plans CRUD operations
  Future<void> insertPlan(Plan plan) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert plan
      await txn.insert('plans', {
        'id': plan.id,
        'title': plan.title,
        'description': plan.description,
        'startDate': plan.startDate.toIso8601String(),
        'endDate': plan.endDate.toIso8601String(),
        'currentStreak': plan.currentStreak,
        'bestStreak': plan.bestStreak,
        'lastCompletedDate': plan.lastCompletedDate.toIso8601String(),
        'isCompleted': plan.isCompleted ? 1 : 0,
      });

      // Insert monthly plans
      for (final monthlyPlan in plan.monthlyPlans) {
        await txn.insert('monthly_plans', {
          'id': monthlyPlan.id,
          'planId': plan.id,
          'title': monthlyPlan.title,
          'description': monthlyPlan.description,
          'month': monthlyPlan.month,
          'year': monthlyPlan.year,
          'isCompleted': monthlyPlan.isCompleted ? 1 : 0,
        });

        // Insert weekly plans
        for (final weeklyPlan in monthlyPlan.weeklyPlans) {
          await txn.insert('weekly_plans', {
            'id': weeklyPlan.id,
            'monthlyPlanId': monthlyPlan.id,
            'title': weeklyPlan.title,
            'description': weeklyPlan.description,
            'weekNumber': weeklyPlan.weekNumber,
            'startDate': weeklyPlan.startDate.toIso8601String(),
            'endDate': weeklyPlan.endDate.toIso8601String(),
            'isCompleted': weeklyPlan.isCompleted ? 1 : 0,
          });

          // Insert daily tasks
          for (final dailyTask in weeklyPlan.dailyTasks) {
            await txn.insert('daily_tasks', {
              'id': dailyTask.id,
              'weeklyPlanId': weeklyPlan.id,
              'title': dailyTask.title,
              'description': dailyTask.description,
              'date': dailyTask.date.toIso8601String(),
              'isCompleted': dailyTask.isCompleted ? 1 : 0,
              'estimatedMinutes': dailyTask.estimatedMinutes,
              'actualMinutes': 0,
              'notes': '',
            });
          }
        }
      }
    });
  }

  Future<List<Plan>> getAllPlans() async {
    final db = await database;
    final plans = await db.query('plans', orderBy: 'startDate DESC');
    
    final List<Plan> result = [];
    for (final planData in plans) {
      final plan = await _buildPlanFromData(planData);
      if (plan != null) {
        result.add(plan);
      }
    }
    
    return result;
  }

  Future<Plan?> getPlanById(String planId) async {
    final db = await database;
    final plans = await db.query('plans', where: 'id = ?', whereArgs: [planId]);
    
    if (plans.isEmpty) return null;
    return await _buildPlanFromData(plans.first);
  }

  Future<void> updatePlan(Plan plan) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update plan
      await txn.update('plans', {
        'title': plan.title,
        'description': plan.description,
        'startDate': plan.startDate.toIso8601String(),
        'endDate': plan.endDate.toIso8601String(),
        'currentStreak': plan.currentStreak,
        'bestStreak': plan.bestStreak,
        'lastCompletedDate': plan.lastCompletedDate.toIso8601String(),
        'isCompleted': plan.isCompleted ? 1 : 0,
      }, where: 'id = ?', whereArgs: [plan.id]);

      // Update monthly plans
      for (final monthlyPlan in plan.monthlyPlans) {
        await txn.update('monthly_plans', {
          'title': monthlyPlan.title,
          'description': monthlyPlan.description,
          'month': monthlyPlan.month,
          'year': monthlyPlan.year,
          'isCompleted': monthlyPlan.isCompleted ? 1 : 0,
        }, where: 'id = ?', whereArgs: [monthlyPlan.id]);

        // Update weekly plans
        for (final weeklyPlan in monthlyPlan.weeklyPlans) {
          await txn.update('weekly_plans', {
            'title': weeklyPlan.title,
            'description': weeklyPlan.description,
            'weekNumber': weeklyPlan.weekNumber,
            'startDate': weeklyPlan.startDate.toIso8601String(),
            'endDate': weeklyPlan.endDate.toIso8601String(),
            'isCompleted': weeklyPlan.isCompleted ? 1 : 0,
          }, where: 'id = ?', whereArgs: [weeklyPlan.id]);

          // Update daily tasks
          for (final dailyTask in weeklyPlan.dailyTasks) {
            await txn.update('daily_tasks', {
              'title': dailyTask.title,
              'description': dailyTask.description,
              'date': dailyTask.date.toIso8601String(),
              'isCompleted': dailyTask.isCompleted ? 1 : 0,
              'estimatedMinutes': dailyTask.estimatedMinutes,
            }, where: 'id = ?', whereArgs: [dailyTask.id]);
          }
        }
      }
    });
  }

  Future<void> deletePlan(String planId) async {
    final db = await database;
    await db.delete('plans', where: 'id = ?', whereArgs: [planId]);
  }

  // Daily tasks CRUD operations
  Future<void> insertDailyTask(DailyTask task, String weeklyPlanId) async {
    final db = await database;
    await db.insert('daily_tasks', {
      'id': task.id,
      'weeklyPlanId': weeklyPlanId,
      'title': task.title,
      'description': task.description,
      'date': task.date.toIso8601String(),
      'isCompleted': task.isCompleted ? 1 : 0,
      'estimatedMinutes': task.estimatedMinutes,
      'actualMinutes': 0,
      'notes': '',
    });
  }

  Future<void> updateDailyTask(DailyTask task) async {
    final db = await database;
    await db.update('daily_tasks', {
      'title': task.title,
      'description': task.description,
      'date': task.date.toIso8601String(),
      'isCompleted': task.isCompleted ? 1 : 0,
      'estimatedMinutes': task.estimatedMinutes,
    }, where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteDailyTask(String taskId) async {
    final db = await database;
    await db.delete('daily_tasks', where: 'id = ?', whereArgs: [taskId]);
    // Also delete associated hourly schedules
    await db.delete('hourly_schedules', where: 'dailyTaskId = ?', whereArgs: [taskId]);
  }

  // Hourly schedules CRUD operations
  Future<void> insertHourlySchedule(String dailyTaskId, String startTime, String endTime, String taskName, {String? notes}) async {
    final db = await database;
    await db.insert('hourly_schedules', {
      'id': '${dailyTaskId}_${startTime}_${endTime}',
      'dailyTaskId': dailyTaskId,
      'startTime': startTime,
      'endTime': endTime,
      'taskName': taskName,
      'notes': notes ?? '',
    });
  }

  Future<void> updateHourlySchedule(String scheduleId, String taskName, {String? notes}) async {
    final db = await database;
    await db.update('hourly_schedules', {
      'taskName': taskName,
      'notes': notes ?? '',
    }, where: 'id = ?', whereArgs: [scheduleId]);
  }

  Future<void> deleteHourlySchedule(String scheduleId) async {
    final db = await database;
    await db.delete('hourly_schedules', where: 'id = ?', whereArgs: [scheduleId]);
  }

  Future<List<Map<String, dynamic>>> getHourlySchedulesForTask(String dailyTaskId) async {
    final db = await database;
    return await db.query(
      'hourly_schedules',
      where: 'dailyTaskId = ?',
      whereArgs: [dailyTaskId],
      orderBy: 'startTime ASC',
    );
  }

  // Helper method to build Plan object from database data
  Future<Plan?> _buildPlanFromData(Map<String, dynamic> planData) async {
    final db = await database;
    
    // Get monthly plans for this plan
    final monthlyPlansData = await db.query(
      'monthly_plans',
      where: 'planId = ?',
      whereArgs: [planData['id']],
      orderBy: 'year ASC, month ASC',
    );

    final List<MonthlyPlan> monthlyPlans = [];
    for (final monthlyPlanData in monthlyPlansData) {
      // Get weekly plans for this monthly plan
      final weeklyPlansData = await db.query(
        'weekly_plans',
        where: 'monthlyPlanId = ?',
        whereArgs: [monthlyPlanData['id']],
        orderBy: 'weekNumber ASC',
      );

      final List<WeeklyPlan> weeklyPlans = [];
      for (final weeklyPlanData in weeklyPlansData) {
        // Get daily tasks for this weekly plan
        final dailyTasksData = await db.query(
          'daily_tasks',
          where: 'weeklyPlanId = ?',
          whereArgs: [weeklyPlanData['id']],
          orderBy: 'date ASC',
        );

        final List<DailyTask> dailyTasks = dailyTasksData.map((taskData) => DailyTask(
          id: taskData['id'] as String,
          title: taskData['title'] as String,
          description: taskData['description'] as String,
          date: DateTime.parse(taskData['date'] as String),
          isCompleted: (taskData['isCompleted'] as int) == 1,
          estimatedMinutes: (taskData['estimatedMinutes'] as int?) ?? 30,
          actualMinutes: (taskData['actualMinutes'] as int?) ?? 0,
          notes: (taskData['notes'] as String?) ?? '',
        )).toList();

        weeklyPlans.add(WeeklyPlan(
          id: weeklyPlanData['id'] as String,
          title: weeklyPlanData['title'] as String,
          description: weeklyPlanData['description'] as String,
          weekNumber: weeklyPlanData['weekNumber'] as int,
          startDate: DateTime.parse(weeklyPlanData['startDate'] as String),
          endDate: DateTime.parse(weeklyPlanData['endDate'] as String),
          dailyTasks: dailyTasks,
          isCompleted: (weeklyPlanData['isCompleted'] as int) == 1,
        ));
      }

      monthlyPlans.add(MonthlyPlan(
        id: monthlyPlanData['id'] as String,
        title: monthlyPlanData['title'] as String,
        description: monthlyPlanData['description'] as String,
        month: monthlyPlanData['month'] as int,
        year: monthlyPlanData['year'] as int,
        weeklyPlans: weeklyPlans,
        isCompleted: (monthlyPlanData['isCompleted'] as int) == 1,
      ));
    }

    return Plan(
      id: planData['id'] as String,
      title: planData['title'] as String,
      description: planData['description'] as String,
      startDate: DateTime.parse(planData['startDate'] as String),
      endDate: DateTime.parse(planData['endDate'] as String),
      monthlyPlans: monthlyPlans,
      currentStreak: (planData['currentStreak'] as int?) ?? 0,
      bestStreak: (planData['bestStreak'] as int?) ?? 0,
      lastCompletedDate: DateTime.parse(planData['lastCompletedDate'] as String),
      isCompleted: (planData['isCompleted'] as int) == 1,
    );
  }

  // Global Streak CRUD operations
  Future<void> insertGlobalStreak(GlobalStreak globalStreak) async {
    final db = await database;
    await db.insert('global_streak', {
      'currentStreak': globalStreak.currentStreak,
      'bestStreak': globalStreak.bestStreak,
      'lastCompletedDate': globalStreak.lastCompletedDate.toIso8601String(),
      'skipDaysUsedThisMonth': globalStreak.skipDaysUsedThisMonth,
      'lastSkipDate': globalStreak.lastSkipDate.toIso8601String(),
      'currentMonth': globalStreak.currentMonth,
      'currentYear': globalStreak.currentYear,
    });
  }

  Future<GlobalStreak?> getGlobalStreak() async {
    final db = await database;
    final result = await db.query('global_streak', limit: 1);
    
    if (result.isEmpty) {
      return null;
    }
    
    final data = result.first;
    return GlobalStreak(
      currentStreak: data['currentStreak'] as int? ?? 0,
      bestStreak: data['bestStreak'] as int? ?? 0,
      lastCompletedDate: DateTime.parse(data['lastCompletedDate'] as String),
      skipDaysUsedThisMonth: data['skipDaysUsedThisMonth'] as int? ?? 0,
      lastSkipDate: DateTime.parse(data['lastSkipDate'] as String),
      currentMonth: data['currentMonth'] as int? ?? DateTime.now().month,
      currentYear: data['currentYear'] as int? ?? DateTime.now().year,
    );
  }

  Future<void> updateGlobalStreak(GlobalStreak globalStreak) async {
    final db = await database;
    await db.update('global_streak', {
      'currentStreak': globalStreak.currentStreak,
      'bestStreak': globalStreak.bestStreak,
      'lastCompletedDate': globalStreak.lastCompletedDate.toIso8601String(),
      'skipDaysUsedThisMonth': globalStreak.skipDaysUsedThisMonth,
      'lastSkipDate': globalStreak.lastSkipDate.toIso8601String(),
      'currentMonth': globalStreak.currentMonth,
      'currentYear': globalStreak.currentYear,
    }, where: 'id = 1');
  }

  Future<void> initializeGlobalStreak() async {
    final existingStreak = await getGlobalStreak();
    if (existingStreak == null) {
      final now = DateTime.now();
      final initialStreak = GlobalStreak(
        currentStreak: 0,
        bestStreak: 0,
        lastCompletedDate: now.subtract(const Duration(days: 1)),
        lastSkipDate: now.subtract(const Duration(days: 1)),
        currentMonth: now.month,
        currentYear: now.year,
      );
      await insertGlobalStreak(initialStreak);
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
