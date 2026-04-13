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
    if (!isOnline) return;

    setState(() => _isSyncing = true);
    try {
      final count = await SyncService.instance.syncPendingTasks(user.uid);
      if (count > 0 && mounted) {
        _tasksKey.currentState?.loadTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count tasks synced to cloud'), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MindSpace',
              style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (!_isOnline)
              const Text(
                'No Internet connection',
                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          if (_isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9181F4))),
              ),
            )
          else if (_isOnline)
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: Color(0xFF9181F4)),
              onPressed: () => _syncTasks(),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF9181F4)),
            onPressed: () => AuthService.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (!_isOnline)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                'Working Offline',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF9181F4),
          unselectedItemColor: const Color(0xFF9C9EB9),
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Drafts'),
            BottomNavigationBarItem(icon: Icon(Icons.cloud_outlined), label: 'Cloud'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context),
              backgroundColor: const Color(0xFF9181F4),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
              'New Draft Task',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 20),
            _buildField(_titleController, 'Title', Icons.title_rounded),
            const SizedBox(height: 16),
            _buildField(_descController, 'Description', Icons.description_outlined, maxLines: 3),
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
                  backgroundColor: const Color(0xFF9181F4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _save,
                child: const Text('Save Draft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          prefixIcon: Icon(icon, color: const Color(0xFF9181F4)),
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
            fontSize: 12,
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

    // Save locally first as a "Draft"
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
