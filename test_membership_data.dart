import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await Firebase.initializeApp();
  await createSampleMembershipData();
}

Future<void> createSampleMembershipData() async {
  final firestore = FirebaseFirestore.instance;

  print('Creating sample membership data...');

  // Sample membership cards
  final membershipCards = [
    {
      'id': 'basic_monthly',
      'name': 'Gói Cơ Bản - Tháng',
      'price': 300000,
      'duration': 30,
      'description': 'Gói tập cơ bản 1 tháng',
      'planType': 'basic',
    },
    {
      'id': 'premium_monthly',
      'name': 'Gói Premium - Tháng',
      'price': 500000,
      'duration': 30,
      'description': 'Gói tập premium 1 tháng',
      'planType': 'premium',
    },
    {
      'id': 'vip_monthly',
      'name': 'Gói VIP - Tháng',
      'price': 800000,
      'duration': 30,
      'description': 'Gói tập VIP 1 tháng',
      'planType': 'vip',
    },
  ];

  // Add membership cards
  for (final card in membershipCards) {
    await firestore
        .collection('membership_cards')
        .doc(card['id'] as String)
        .set(card);
    print('Added membership card: ${card['name']}');
  }

  // Sample user memberships (purchases)
  final userMemberships = [
    {
      'userId': 'sRA3eTxzd9OJJmVH5na6M55tq9V2',
      'membershipCardId': 'basic_monthly',
      'planName': 'Gói Cơ Bản - Tháng',
      'price': 300000,
      'status': 'active',
      'startDate': DateTime.now().subtract(Duration(days: 15)),
      'endDate': DateTime.now().add(Duration(days: 15)),
      'purchaseDate': DateTime.now().subtract(Duration(days: 15)),
    },
    {
      'userId': 'PxD9orP0BrXZrQ5AsLsX5iaHsnL2',
      'membershipCardId': 'premium_monthly',
      'planName': 'Gói Premium - Tháng',
      'price': 500000,
      'status': 'active',
      'startDate': DateTime.now().subtract(Duration(days: 10)),
      'endDate': DateTime.now().add(Duration(days: 20)),
      'purchaseDate': DateTime.now().subtract(Duration(days: 10)),
    },
    {
      'userId': 'igWd1hqSK3NoPLYpE64RIZiOvpn1',
      'membershipCardId': 'vip_monthly',
      'planName': 'Gói VIP - Tháng',
      'price': 800000,
      'status': 'active',
      'startDate': DateTime.now().subtract(Duration(days: 5)),
      'endDate': DateTime.now().add(Duration(days: 25)),
      'purchaseDate': DateTime.now().subtract(Duration(days: 5)),
    },
    {
      'userId': 'lBPuzNkWmLc34u3hb9uEwDYQ9Vn1',
      'membershipCardId': 'basic_monthly',
      'planName': 'Gói Cơ Bản - Tháng',
      'price': 300000,
      'status': 'expired',
      'startDate': DateTime.now().subtract(Duration(days: 45)),
      'endDate': DateTime.now().subtract(Duration(days: 15)),
      'purchaseDate': DateTime.now().subtract(Duration(days: 45)),
    },
  ];

  // Add user memberships
  for (final membership in userMemberships) {
    await firestore.collection('user_memberships').add(membership);
    print(
      'Added user membership: ${membership['planName']} for user ${membership['userId']}',
    );
  }

  print('Sample data created successfully!');
}
