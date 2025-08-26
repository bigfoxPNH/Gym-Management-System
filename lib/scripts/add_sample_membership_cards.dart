import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to add sample membership cards for testing
Future<void> addSampleMembershipCards() async {
  final firestore = FirebaseFirestore.instance;

  final sampleCards = [
    {
      'cardName': 'Thẻ Tập Basic',
      'description':
          'Thẻ tập cơ bản cho người mới bắt đầu. Bao gồm quyền truy cập tất cả thiết bị tập gym.',
      'cardType': 'member',
      'durationType': 'months',
      'duration': 1,
      'customEndDate': null,
      'price': 500000.0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'createdBy': 'admin',
      'isActive': true,
    },
    {
      'cardName': 'Thẻ Tập Premium',
      'description':
          'Thẻ tập cao cấp với các tiện ích bổ sung như phòng xông hơi, massage.',
      'cardType': 'premium',
      'durationType': 'months',
      'duration': 3,
      'customEndDate': null,
      'price': 1300000.0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'createdBy': 'admin',
      'isActive': true,
    },
    {
      'cardName': 'Thẻ Tập VIP',
      'description':
          'Thẻ tập VIP với tất cả dịch vụ cao cấp, huấn luyện viên cá nhân.',
      'cardType': 'vip',
      'durationType': 'years',
      'duration': 1,
      'customEndDate': null,
      'price': 5000000.0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'createdBy': 'admin',
      'isActive': true,
    },
  ];

  for (final cardData in sampleCards) {
    try {
      await firestore.collection('membership_cards').add(cardData);
      print('Added card: ${cardData['cardName']}');
    } catch (e) {
      print('Error adding card ${cardData['cardName']}: $e');
    }
  }

  print('Sample membership cards added successfully!');
}

/// Main function to run the script
void main() async {
  print('Adding sample membership cards...');
  await addSampleMembershipCards();
}
