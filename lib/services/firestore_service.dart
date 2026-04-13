import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class FirestoreService {
  final CollectionReference _tasksCollection = FirebaseFirestore.instance.collection('task');
  final CollectionReference _logsCollection = FirebaseFirestore.instance.collection('activity_logs');

  /// Adds a task to Firestore
  Future<String> addTask(TaskModel task) async {
    try {
      DocumentReference docRef = await _tasksCollection.add(task.toFirestoreMap());
      await logActivity(
        type: 'task_created',
        details: 'Task "${task.title}" synced to cloud.',
      );
      return docRef.id;
    } catch (e) {
      print('Firestore addTask Error: $e');
      rethrow;
    }
  }

  /// Logs user activity to the 'activity_logs' collection
  Future<void> logActivity({required String type, required String details}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _logsCollection.add({
        'device': 'Mobile App',
        'employee_id': user.uid.substring(0, 8).toUpperCase(),
        'employee_name': user.displayName ?? 'Unknown User',
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        'details': details,
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }

  Future<void> syncTasks(List<TaskModel> tasks, Function(int, String) onSyncSuccess) async {
    for (var task in tasks) {
      String firestoreId = await addTask(task);
      await onSyncSuccess(task.id!, firestoreId);
    }
  }

  Future<void> deleteTask(String firestoreId) async {
    try {
      await _tasksCollection.doc(firestoreId).delete();
      await logActivity(
        type: 'task_deleted',
        details: 'Task with Firestore ID $firestoreId was deleted.',
      );
    } catch (e) {
      print('Firestore deleteTask Error: $e');
      rethrow;
    }
  }

  Stream<List<TaskModel>> streamTasks(String userId) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TaskModel.fromSqliteMap({
          ...data,
          'synced': 1,
          'firestoreId': doc.id,
        });
      }).toList();
    });
  }
}
