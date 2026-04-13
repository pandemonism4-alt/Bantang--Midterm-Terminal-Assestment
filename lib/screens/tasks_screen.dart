import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_helper.dart';

class TasksScreen extends StatefulWidget {
  final String userId;
  const TasksScreen({super.key, required this.userId});
  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await DatabaseHelper.instance.getTasksByUser(widget.userId);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9181F4)));
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_document, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No drafts available',
              style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Tasks created offline will appear here.',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _tasks.length,
      itemBuilder: (_, i) => _TaskCard(task: _tasks[i], reload: loadTasks),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback reload;
  const _TaskCard({required this.task, required this.reload});

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orangeAccent;
      default: return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: _getPriorityColor(task.priority),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: task.synced ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.synced ? 'SYNCED' : 'DRAFT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: task.synced ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF9C9EB9), height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(task.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                          const Spacer(),
                          if (!task.synced)
                            const Icon(Icons.cloud_off_rounded, size: 18, color: Colors.orangeAccent),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await DatabaseHelper.instance.deleteTask(task.id!);
                              reload();
                            },
                            child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
