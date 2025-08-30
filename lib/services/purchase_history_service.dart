import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/membership_purchase.dart';
import '../models/payment_transaction.dart';

class PurchaseHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'purchase_history';

  // Save purchase to history
  static Future<void> savePurchaseHistory({
    required MembershipPurchase purchase,
    required PaymentTransaction transaction,
  }) async {
    try {
      final historyData = {
        'id': transaction.id,
        'userId': purchase.userId,
        'membershipCardId': purchase.cardId,
        'membershipPurchaseId': purchase.id,
        'cardName': purchase.cardName,
        'cardType': purchase.cardType.name,
        'duration': purchase.duration,
        'durationType': purchase.durationType.name,
        'amount': transaction.amount,
        'paymentMethod': transaction.paymentMethod.name,
        'paymentStatus': transaction.status.name,
        'purchaseDate': purchase.purchaseDate,
        'startDate': purchase.startDate,
        'endDate': purchase.endDate,
        'status': purchase.status.name,
        'createdAt': transaction.createdAt,
        'completedAt': transaction.completedAt,
        'description': transaction.description,
        'transactionId': transaction.id,
      };

      await _firestore
          .collection(_collection)
          .doc(transaction.id)
          .set(historyData);

      print('✅ Purchase history saved: ${transaction.id}');
    } catch (e) {
      print('❌ Error saving purchase history: $e');
      rethrow;
    }
  }

  // Get user's purchase history
  static Future<List<Map<String, dynamic>>> getUserPurchaseHistory(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error fetching purchase history: $e');
      return [];
    }
  }

  // Get purchase history by transaction ID
  static Future<Map<String, dynamic>?> getPurchaseByTransactionId(
    String transactionId,
  ) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(transactionId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching purchase by transaction ID: $e');
      return null;
    }
  }

  // Update purchase status
  static Future<void> updatePurchaseStatus(
    String transactionId,
    String status,
  ) async {
    try {
      await _firestore.collection(_collection).doc(transactionId).update({
        'paymentStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Purchase status updated: $transactionId -> $status');
    } catch (e) {
      print('❌ Error updating purchase status: $e');
      rethrow;
    }
  }

  // Get all purchases (for admin)
  static Future<List<Map<String, dynamic>>> getAllPurchases() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error fetching all purchases: $e');
      return [];
    }
  }

  // Get purchase statistics
  static Future<Map<String, dynamic>> getPurchaseStats(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final docs = querySnapshot.docs;
      final totalPurchases = docs.length;
      final successfulPurchases = docs
          .where((doc) => doc.data()['paymentStatus'] == 'completed')
          .length;

      double totalAmount = 0;
      for (var doc in docs) {
        final amount = doc.data()['amount'];
        if (amount is num) {
          totalAmount += amount.toDouble();
        }
      }

      return {
        'totalPurchases': totalPurchases,
        'successfulPurchases': successfulPurchases,
        'totalAmount': totalAmount,
        'averageAmount': totalPurchases > 0 ? totalAmount / totalPurchases : 0,
      };
    } catch (e) {
      print('❌ Error fetching purchase stats: $e');
      return {
        'totalPurchases': 0,
        'successfulPurchases': 0,
        'totalAmount': 0.0,
        'averageAmount': 0.0,
      };
    }
  }
}
