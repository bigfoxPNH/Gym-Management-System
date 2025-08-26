import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to clean up test data from Firebase
class CleanupTestDataUtil {
  static final _firestore = FirebaseFirestore.instance;

  /// Delete all membership cards with cardName "Thẻ Tập Test"
  static Future<void> deleteTestCards() async {
    try {
      print('🧹 Starting cleanup of test cards...');

      // Query for all cards with cardName "Thẻ Tập Test"
      final query = await _firestore
          .collection('membership_cards')
          .where('cardName', isEqualTo: 'Thẻ Tập Test')
          .get();

      if (query.docs.isEmpty) {
        print('✅ No test cards found to delete.');
        return;
      }

      print('🔍 Found ${query.docs.length} test cards to delete:');

      // Delete each card
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        print('  - Deleting card: ${doc.id} (${doc.data()['cardName']})');
        batch.delete(doc.reference);
      }

      // Commit the batch delete
      await batch.commit();

      print('🎉 Successfully deleted ${query.docs.length} test cards!');
    } catch (e) {
      print('❌ Error deleting test cards: $e');
      throw Exception('Failed to delete test cards: $e');
    }
  }

  /// Delete all membership purchases related to test cards
  static Future<void> deleteTestPurchases() async {
    try {
      print('🧹 Starting cleanup of test purchases...');

      // First, get all test card IDs
      final testCardsQuery = await _firestore
          .collection('membership_cards')
          .where('cardName', isEqualTo: 'Thẻ Tập Test')
          .get();

      if (testCardsQuery.docs.isEmpty) {
        print('✅ No test cards found, skipping purchase cleanup.');
        return;
      }

      final testCardIds = testCardsQuery.docs.map((doc) => doc.id).toList();
      print('🔍 Looking for purchases related to test cards: $testCardIds');

      // Query for purchases related to these test cards
      final purchasesQuery = await _firestore
          .collection('membership_purchases')
          .where('cardId', whereIn: testCardIds)
          .get();

      if (purchasesQuery.docs.isEmpty) {
        print('✅ No test purchases found to delete.');
        return;
      }

      print('🔍 Found ${purchasesQuery.docs.length} test purchases to delete:');

      // Delete each purchase
      final batch = _firestore.batch();
      for (final doc in purchasesQuery.docs) {
        print('  - Deleting purchase: ${doc.id}');
        batch.delete(doc.reference);
      }

      // Commit the batch delete
      await batch.commit();

      print(
        '🎉 Successfully deleted ${purchasesQuery.docs.length} test purchases!',
      );
    } catch (e) {
      print('❌ Error deleting test purchases: $e');
      throw Exception('Failed to delete test purchases: $e');
    }
  }

  /// Complete cleanup of all test data
  static Future<void> cleanupAllTestData() async {
    try {
      print('🚀 Starting complete test data cleanup...');

      // First delete purchases (to avoid reference issues)
      await deleteTestPurchases();

      // Then delete the test cards
      await deleteTestCards();

      print('✨ Complete test data cleanup finished successfully!');
    } catch (e) {
      print('💥 Error during complete cleanup: $e');
      throw Exception('Failed to cleanup test data: $e');
    }
  }

  /// List all cards for verification
  static Future<void> listAllCards() async {
    try {
      print('📋 Listing all membership cards:');

      final query = await _firestore
          .collection('membership_cards')
          .orderBy('createdAt', descending: true)
          .get();

      if (query.docs.isEmpty) {
        print('📭 No cards found.');
        return;
      }

      print('🔍 Found ${query.docs.length} cards:');
      for (final doc in query.docs) {
        final data = doc.data();
        print('  - ID: ${doc.id}');
        print('    Name: ${data['cardName'] ?? 'N/A'}');
        print('    Type: ${data['cardType'] ?? 'N/A'}');
        print('    Price: ${data['price'] ?? 'N/A'} VND');
        print('    Active: ${data['isActive'] ?? 'N/A'}');
        print(
          '    Created: ${data['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']).toString() : 'N/A'}',
        );
        print('');
      }
    } catch (e) {
      print('❌ Error listing cards: $e');
      throw Exception('Failed to list cards: $e');
    }
  }
}
