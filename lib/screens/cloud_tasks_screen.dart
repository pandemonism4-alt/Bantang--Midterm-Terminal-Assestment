import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/sync_service.dart';
import '../services/firestore_service.dart';

class CloudTasksScreen extends StatelessWidget {
  final String userId;
  const CloudTasksScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: SyncService.instance.streamCloudTasks(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return _buildNoCloudContent(
            icon: Icons.error_outline_rounded,
            title: 'Connection Error',
            subtitle: 'Check your internet connection to view cloud tasks.',
          );
        }

        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return _buildNoCloudContent(
            icon: Icons.cloud_off_rounded,
            title: 'Cloud is empty',
            subtitle: 'Synced tasks will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: tasks.length,
          itemBuilder: (_, i) => _CloudTaskCard(task: tasks[i]),
        );
      },
    );
  }

  Widget _buildNoCloudContent({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudTaskCard extends StatelessWidget {
  final TaskModel task;
  const _CloudTaskCard({required this.task});

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _getPriorityColor(task.priority),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
            ),
            const Icon(Icons.cloud_done_rounded, size: 16, color: Colors.green),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF9C9EB9), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${task.firestoreId ?? "N/A"}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400], fontFamily: 'monospace'),
                ),
                GestureDetector(
                  onTap: () async {
                    if (task.firestoreId != null) {
                      await FirestoreService().deleteTask(task.firestoreId!);
                    }
                  },
                  child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
