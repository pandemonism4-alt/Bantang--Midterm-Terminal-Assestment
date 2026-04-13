import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'database_helper.dart';
import 'firestore_service.dart';
import 'connectivity_service.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ConnectivityService _connectivity = ConnectivityService.instance;

  Future<int> syncPendingTasks(String userId) async {
    final isOnline = await _connectivity.isConnected;
    if (!isOnline) return 0;

    final unsynced = await _dbHelper.getUnsyncedTasks(userId);
    if (unsynced.isEmpty) return 0;

    int successCount = 0;
    for (final task in unsynced) {
      try {
        final firestoreId = await _firestoreService.addTask(task);
        await _dbHelper.markAsSynced(task.id!, firestoreId);
        successCount++;
      } catch (e) {
        print('Sync error for task ${task.id}: $e');
      }
    }
    return successCount;
  }

  /// Returns a real-time stream of synced tasks from Firestore for [userId].
  Stream<List<TaskModel>> streamCloudTasks(String userId) {
    // Matches your 'task' collection index
    return FirebaseFirestore.instance
        .collection('task')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TaskModel.fromSqliteMap({
          ...data,
          'synced': 1,
          'firestoreId': doc.id,
        });
      }).toList();
    });
  }
}
