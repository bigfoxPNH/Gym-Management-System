import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/membership_card.dart';

class TestCheckoutView extends StatelessWidget {
  const TestCheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Checkout')),
      body: SingleChildScrollView(
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              // Create a test membership card
              final testCard = MembershipCard(
                id: 'test-123',
                cardName: 'Hội viên cơ bản 1',
                description: 'Sử dụng mọi thiết bị trong khu A.',
                cardType: CardType.member,
                durationType: DurationType.days,
                duration: 1,
                price: 10000,
                isActive: true,
                createdBy: 'test-user',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              // Navigate to checkout
              Get.toNamed('/checkout', arguments: testCard);
            },
            child: const Text('Test Checkout'),
          ),
        ),
      ),
    );
  }
}
