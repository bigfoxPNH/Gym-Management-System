import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to add sample membership cards for testing
class SampleDataUtil {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> addSampleMembershipCards() async {
    try {
      // Check if any cards already exist
      final existing = await _firestore
          .collection('membership_cards')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        print('Sample cards already exist');
        return;
      }

      final sampleCards = [
        {
          'cardName': 'Thẻ Tập Basic',
          'description':
              'Thẻ tập cơ bản cho người mới bắt đầu. Bao gồm quyền truy cập tất cả thiết bị tập gym cơ bản.',
          'cardType': 'member',
          'durationType': 'months',
          'duration': 1,
          'customEndDate': null,
          'price': 500000.0,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'createdBy': 'system',
          'isActive': true,
        },
        {
          'cardName': 'Thẻ Tập Premium 3 Tháng',
          'description':
              'Thẻ tập cao cấp 3 tháng với các tiện ích bổ sung như phòng xông hơi, massage.',
          'cardType': 'premium',
          'durationType': 'months',
          'duration': 3,
          'customEndDate': null,
          'price': 1300000.0,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'createdBy': 'system',
          'isActive': true,
        },
        {
          'cardName': 'Thẻ Tập VIP 1 Năm',
          'description':
              'Thẻ tập VIP với tất cả dịch vụ cao cấp, huấn luyện viên cá nhân, không giới hạn thời gian.',
          'cardType': 'vip',
          'durationType': 'years',
          'duration': 1,
          'customEndDate': null,
          'price': 5000000.0,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'createdBy': 'system',
          'isActive': true,
        },
      ];

      for (final cardData in sampleCards) {
        await _firestore.collection('membership_cards').add(cardData);
        print('Added sample card: ${cardData['cardName']}');
      }

      print('All sample membership cards added successfully!');
    } catch (e) {
      print('Error adding sample cards: $e');
    }
  }
}
