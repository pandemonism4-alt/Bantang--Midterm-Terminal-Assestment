import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/database_helper.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import 'tasks_screen.dart';
import 'cloud_tasks_screen.dart';
import 'resources_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSyncing = false;
  bool _isOnline = true;
  final GlobalKey<TasksScreenState> _tasksKey = GlobalKey<TasksScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser!;
    _screens = [
      TasksScreen(key: _tasksKey, userId: user.uid),
      CloudTasksScreen(userId: user.uid),
      const ResourcesScreen(),
    ];

    _checkInitialConnectivity();
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online) _syncTasks(silent: true);
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final online = await ConnectivityService.instance.isConnected;
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _syncTasks({bool silent = false}) async {
    if (_isSyncing) return;
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final isOnline = await ConnectivityService.instance.isConnected;
    if (!isOnline) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final count = await SyncService.instance.syncPendingTasks(user.uid);
      if (mounted) {
        if (count > 0) {
          _tasksKey.currentState?.loadTasks();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count tasks synced to cloud'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Everything is already synced!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Text(
              'MindSpace',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5),
            ),
          ],
        ),
        actions: [
          if (_isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: Colors.white),
              onPressed: () => _syncTasks(),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => AuthService.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/images/carti.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.75)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isOnline)
                  Container(
                    width: double.infinity,
                    color: Colors.redAccent.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'OFFLINE MODE',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $userName',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Here\'s Your Tasks',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                _buildTaskStatusScroll(),
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFFFF3B5C),
          unselectedItemColor: const Color(0xFF757575),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Drafts'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud_outlined), label: 'Cloud'),
            BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Resources'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTaskDialog(context),
              backgroundColor: const Color(0xFFFF3B5C),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text('Create New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTaskStatusScroll() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildStatusCard('Plan', Icons.edit_note_rounded, const Color(0xFFFF3B5C)),
          _buildStatusCard('On Going', Icons.timer_outlined, const Color(0xFF9181F4)),
          _buildStatusCard('Finish', Icons.check_circle_outline_rounded, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        userId: AuthService.instance.currentUser!.uid,
        onTaskAdded: () => _tasksKey.currentState?.loadTasks(),
      ),
    );
  }
}

class AddTaskSheet extends StatefulWidget {
  final String userId;
  final VoidCallback onTaskAdded;
  const AddTaskSheet({super.key, required this.userId, required this.onTaskAdded});
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String _priority = 'medium';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NEW TASK ENTRY',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF3B5C), letterSpacing: 1),
            ),
            const SizedBox(height: 20),
            _buildField(_titleController, 'Task Subject', Icons.subject_rounded),
            const SizedBox(height: 16),
            _buildField(_descController, 'Detailed Description', Icons.notes_rounded, maxLines: 3),
            const SizedBox(height: 24),
            Row(
              children: [
                _priorityChip('low', Colors.green),
                const SizedBox(width: 8),
                _priorityChip('medium', Colors.orange),
                const SizedBox(width: 8),
                _priorityChip('high', Colors.red),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B5C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _save,
                child: const Text('SUBMIT DRAFT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFFF3B5C)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _priorityChip(String p, Color color) {
    final isSelected = _priority == p;
    return GestureDetector(
      onTap: () => setState(() => _priority = p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          p.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) return;

    final isOnline = await ConnectivityService.instance.isConnected;

    final taskToInitial = TaskModel(
      title: _titleController.text,
      description: _descController.text,
      priority: _priority,
      synced: false,
      userId: widget.userId,
      createdAt: DateTime.now(),
    );

    final localId = await DatabaseHelper.instance.insertTask(taskToInitial);

    if (isOnline) {
      try {
        final firestoreId = await _firestoreService.addTask(taskToInitial);
        await DatabaseHelper.instance.markAsSynced(localId, firestoreId);
      } catch (e) {
        debugPrint('Sync failed: $e');
      }
    }

    widget.onTaskAdded();
    if (mounted) Navigator.pop(context);
  }
}
