import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_schedule.dart';
import '../models/user_schedule.dart';

class WorkoutScheduleService {
  static const String _collectionName = 'workout_schedules';
  static const String _userSchedulesCollection = 'user_schedules';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CRUD cho Workout Schedules (Admin)
  Future<String> createSchedule(WorkoutSchedule schedule) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(schedule.toMap());

      // Update với ID thực tế
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi tạo lịch trình: $e');
    }
  }

  Future<List<WorkoutSchedule>> getAllSchedules() async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();

      final schedules = querySnapshot.docs
          .map((doc) => WorkoutSchedule.fromMap(doc.data()))
          .toList();

      // Sort in code to avoid index requirements
      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schedules;
    } catch (e) {
      throw Exception('Lỗi lấy danh sách lịch trình: $e');
    }
  }

  Future<List<WorkoutSchedule>> getActiveSchedules() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      final schedules = querySnapshot.docs
          .map((doc) => WorkoutSchedule.fromMap(doc.data()))
          .toList();

      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schedules;
    } catch (e) {
      throw Exception('Lỗi lấy danh sách lịch trình: $e');
    }
  }

  Future<List<WorkoutSchedule>> getSchedulesByCategory(
    ScheduleCategory category,
  ) async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();

      final schedules = querySnapshot.docs
          .map((doc) => WorkoutSchedule.fromMap(doc.data()))
          .where(
            (schedule) => schedule.category == category && schedule.isActive,
          )
          .toList();

      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schedules;
    } catch (e) {
      throw Exception('Lỗi lấy lịch trình theo danh mục: $e');
    }
  }

  Future<List<WorkoutSchedule>> getSchedulesByDifficulty(
    DifficultyLevel difficulty,
  ) async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();

      final schedules = querySnapshot.docs
          .map((doc) => WorkoutSchedule.fromMap(doc.data()))
          .where(
            (schedule) =>
                schedule.difficulty == difficulty && schedule.isActive,
          )
          .toList();

      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schedules;
    } catch (e) {
      throw Exception('Lỗi lấy lịch trình theo độ khó: $e');
    }
  }

  Future<List<WorkoutSchedule>> getPresetSchedules() async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();

      final schedules = querySnapshot.docs
          .map((doc) => WorkoutSchedule.fromMap(doc.data()))
          .where(
            (schedule) =>
                schedule.type == ScheduleType.preset && schedule.isActive,
          )
          .toList();

      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schedules;
    } catch (e) {
      throw Exception('Lỗi lấy lịch trình preset: $e');
    }
  }

  Future<WorkoutSchedule?> getScheduleById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists) {
        return WorkoutSchedule.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy lịch trình: $e');
    }
  }

  Future<void> updateSchedule(WorkoutSchedule schedule) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(schedule.id)
          .update(schedule.toMap());
    } catch (e) {
      throw Exception('Lỗi cập nhật lịch trình: $e');
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi xóa lịch trình: $e');
    }
  }

  Future<void> toggleScheduleStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái lịch trình: $e');
    }
  }

  // CRUD cho User Schedules
  Future<String> assignScheduleToUser(String userId, String scheduleId) async {
    try {
      // Kiểm tra xem user đã có schedule này chưa
      final existingQuery = await _firestore
          .collection(_userSchedulesCollection)
          .where('userId', isEqualTo: userId)
          .where('scheduleId', isEqualTo: scheduleId)
          .where(
            'status',
            whereIn: [
              UserScheduleStatus.active.name,
              UserScheduleStatus.paused.name,
            ],
          )
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Bạn đã có lịch trình này trong danh sách!');
      }

      final schedule = await getScheduleById(scheduleId);
      if (schedule == null) {
        throw Exception('Không tìm thấy lịch trình!');
      }

      final userSchedule = UserSchedule(
        id: '', // Will be set by Firestore
        userId: userId,
        scheduleId: scheduleId,
        startDate: DateTime.now(),
        status: UserScheduleStatus.active,
        currentWeek: 1,
        currentSession: 1,
        completedExerciseIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_userSchedulesCollection)
          .add(userSchedule.toMap());

      // Update với ID thực tế
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi assign lịch trình: $e');
    }
  }

  Future<List<UserSchedule>> getUserSchedules(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_userSchedulesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final schedules = querySnapshot.docs
          .map((doc) => UserSchedule.fromMap(doc.data()))
          .toList();

      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schedules;
    } catch (e) {
      throw Exception('Lỗi lấy lịch trình user: $e');
    }
  }

  Future<List<UserSchedule>> getActiveUserSchedules(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_userSchedulesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final schedules = querySnapshot.docs
          .map((doc) => UserSchedule.fromMap(doc.data()))
          .where((schedule) => schedule.status == UserScheduleStatus.active)
          .toList();

      schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return schedules;
    } catch (e) {
      throw Exception('Lỗi lấy lịch trình active: $e');
    }
  }

  Future<void> updateUserSchedule(UserSchedule userSchedule) async {
    try {
      await _firestore
          .collection(_userSchedulesCollection)
          .doc(userSchedule.id)
          .update(userSchedule.toMap());
    } catch (e) {
      throw Exception('Lỗi cập nhật user schedule: $e');
    }
  }

  Future<void> updateUserScheduleProgress(
    String userScheduleId,
    int currentWeek,
    int currentSession,
    List<String> completedExerciseIds,
  ) async {
    try {
      await _firestore
          .collection(_userSchedulesCollection)
          .doc(userScheduleId)
          .update({
            'currentWeek': currentWeek,
            'currentSession': currentSession,
            'completedExerciseIds': completedExerciseIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Lỗi cập nhật progress: $e');
    }
  }

  Future<void> changeUserScheduleStatus(
    String userScheduleId,
    UserScheduleStatus status,
  ) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == UserScheduleStatus.completed) {
        updateData['completedDate'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(_userSchedulesCollection)
          .doc(userScheduleId)
          .update(updateData);
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái: $e');
    }
  }

  // Statistics methods
  Future<int> getTotalSchedulesCount() async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Lỗi đếm tổng lịch trình: $e');
    }
  }

  Future<int> getActiveUserSchedulesCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(_userSchedulesCollection)
          .get();

      final activeCount = querySnapshot.docs
          .map((doc) => UserSchedule.fromMap(doc.data()))
          .where((schedule) => schedule.status == UserScheduleStatus.active)
          .length;

      return activeCount;
    } catch (e) {
      throw Exception('Lỗi đếm user schedule active: $e');
    }
  }

  Future<Map<String, int>> getScheduleStatsByCategory() async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();
      final Map<String, int> stats = {};

      for (var doc in querySnapshot.docs) {
        final schedule = WorkoutSchedule.fromMap(doc.data());
        final categoryName = schedule.category.name;
        stats[categoryName] = (stats[categoryName] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Lỗi thống kê theo danh mục: $e');
    }
  }

  // Real-time streams
  Stream<List<WorkoutSchedule>> watchSchedules() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => WorkoutSchedule.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Stream<List<UserSchedule>> watchUserSchedules(String userId) {
    return _firestore
        .collection(_userSchedulesCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserSchedule.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }
}
