import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity_planning_app/providers/plan_provider.dart';
import 'package:productivity_planning_app/widgets/plan_card.dart';
import 'package:productivity_planning_app/widgets/streak_display.dart';
import 'package:productivity_planning_app/screens/create_plan_screen.dart';
import 'package:productivity_planning_app/screens/plan_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Check end of day logic when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEndOfDay();
    });
  }

  void _checkEndOfDay() {
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    planProvider.checkEndOfDay();
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
        title: const Text('Productivity Planner'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Streak Display
          const StreakDisplay(),
          
          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'All Plans'),
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlansList(context, null),
                _buildPlansList(context, false),
                _buildPlansList(context, true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePlanScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Plan'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Progress',
          ),
        ],
      ),
    );
  }



  Widget _buildPlansList(BuildContext context, bool? isCompleted) {
    return Consumer<PlanProvider>(
      builder: (context, planProvider, child) {
        // Show loading state while initializing
        if (!planProvider.isInitialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing...'),
              ],
            ),
          );
        }
        
        List plans = planProvider.plans;
        
        if (isCompleted != null) {
          plans = plans.where((plan) => plan.isCompleted == isCompleted).toList();
        }
        
        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted == null
                      ? Icons.task_alt
                      : isCompleted
                          ? Icons.check_circle
                          : Icons.play_circle,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isCompleted == null
                      ? 'No plans yet'
                      : isCompleted
                          ? 'No completed plans'
                          : 'No active plans',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                if (isCompleted == null) ...[
                  Text(
                    'Create your first plan to get started!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePlanScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PlanCard(
                plan: plan,
                onTap: () {
                  planProvider.selectPlan(plan);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlanDetailScreen(plan: plan),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
