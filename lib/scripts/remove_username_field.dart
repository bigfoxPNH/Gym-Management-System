import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Script để xóa field 'username' từ tất cả documents trong collection 'users'
/// Chạy script này một lần để dọn dẹp database sau khi đã xóa username khỏi code
void main() async {
  print('Đang khởi tạo Firebase...');

  try {
    // Khởi tạo Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('Firebase đã được khởi tạo thành công');

    final firestore = FirebaseFirestore.instance;
    final usersCollection = firestore.collection('users');

    print('Đang lấy danh sách tất cả users...');

    // Lấy tất cả documents trong collection users
    final querySnapshot = await usersCollection.get();

    print('Tìm thấy ${querySnapshot.docs.length} users');

    int updatedCount = 0;
    int totalCount = querySnapshot.docs.length;

    // Xóa field username từ mỗi document
    for (var doc in querySnapshot.docs) {
      try {
        final data = doc.data();

        // Kiểm tra xem document có field username không
        if (data.containsKey('username')) {
          print(
            'Đang xóa username từ user: ${doc.id} (${data['fullName'] ?? 'Unknown'})',
          );

          // Xóa field username
          await doc.reference.update({
            'username': FieldValue.delete(),
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });

          updatedCount++;
          print('✅ Đã xóa username từ user ${doc.id}');
        } else {
          print('ℹ️  User ${doc.id} không có field username');
        }
      } catch (e) {
        print('❌ Lỗi khi xóa username từ user ${doc.id}: $e');
      }
    }

    print('\n🎉 Hoàn tất!');
    print('📊 Thống kê:');
    print('   - Tổng số users: $totalCount');
    print('   - Users đã cập nhật: $updatedCount');
    print('   - Users không có username: ${totalCount - updatedCount}');
  } catch (e) {
    print('❌ Lỗi: $e');
  }
}
