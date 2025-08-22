import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🚀 Script xóa field username từ Firestore');
  print('=====================================');

  try {
    // Khởi tạo Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;

    // Lấy tất cả users
    final snapshot = await firestore.collection('users').get();

    print('Tìm thấy ${snapshot.docs.length} users');

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (data.containsKey('username')) {
        final username = data['username'];
        final fullName = data['fullName'] ?? 'Unknown';

        print('Xóa username "$username" từ user "$fullName"...');

        await doc.reference.update({
          'username': FieldValue.delete(),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });

        print('✅ Thành công!');
      }
    }

    print('🎉 Hoàn tất! Đã xóa field username từ tất cả users.');
  } catch (e) {
    print('❌ Lỗi: $e');
    exit(1);
  }

  exit(0);
}
