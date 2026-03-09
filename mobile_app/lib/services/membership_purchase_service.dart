import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/membership_purchase.dart';
import '../models/membership_card.dart';

/// Service for managing membership purchase operations
class MembershipPurchaseService {
  static final _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'membership_purchases';

  /// Test Firebase connection
  static Future<bool> testConnection() async {
    try {
      await _firestore.collection(collectionName).limit(1).get();
      print('Firebase connection successful');
      return true;
    } catch (e) {
      print('Firebase connection failed: $e');
      return false;
    }
  }

  /// Create a new membership purchase from template
  static Future<MembershipPurchase?> createPurchaseFromTemplate({
    required String userId,
    required MembershipCard template,
    DateTime? startDate,
    DateTime? purchaseDate,
    PurchaseStatus? status,
  }) async {
    try {
      print('Creating purchase for userId: $userId, template: ${template.id}');
      final docRef = _firestore.collection(collectionName).doc();

      final purchase = MembershipPurchase.fromTemplate(
        id: docRef.id,
        userId: userId,
        template: template,
        purchaseDate: purchaseDate,
        startDate: startDate,
        status: status, // Pass status to factory
      );

      print('Purchase object created: ${purchase.toMap()}');
      await docRef.set(purchase.toMap());
      print('Purchase saved to Firestore with ID: ${docRef.id}');
      return purchase;
    } catch (e) {
      print('Error creating purchase: $e');
      return null;
    }
  }

  /// Get purchase by ID
  static Future<MembershipPurchase?> getPurchaseById(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();

      if (doc.exists) {
        return MembershipPurchase.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting purchase: $e');
      return null;
    }
  }

  /// Get all purchases for a specific user
  static Future<List<MembershipPurchase>> getUserPurchases(
    String userId,
  ) async {
    try {
      print('Getting purchases for userId: $userId');
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      print('Found ${querySnapshot.docs.length} purchase documents');

      final purchases = querySnapshot.docs.map((doc) {
        print('Processing purchase doc: ${doc.id}, data: ${doc.data()}');
        return MembershipPurchase.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by purchaseDate in memory
      purchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      print('Returning ${purchases.length} purchases');
      return purchases;
    } catch (e) {
      print('Error getting user purchases: $e');
      return [];
    }
  }

  /// Get active purchases for a user
  static Future<List<MembershipPurchase>> getUserActivePurchases(
    String userId,
  ) async {
    try {
      final now = DateTime.now();

      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: PurchaseStatus.active.name)
          .get();

      final purchases = querySnapshot.docs
          .map((doc) => MembershipPurchase.fromMap(doc.data(), doc.id))
          .where(
            (purchase) => purchase.endDate.isAfter(now),
          ) // Filter in memory
          .toList();

      // Sort by endDate in memory
      purchases.sort((a, b) => a.endDate.compareTo(b.endDate));

      return purchases;
    } catch (e) {
      print('Error getting active purchases: $e');
      return [];
    }
  }

  /// Update purchase
  static Future<bool> updatePurchase(MembershipPurchase purchase) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(purchase.id)
          .update(purchase.toMap());

      return true;
    } catch (e) {
      print('Error updating purchase: $e');
      return false;
    }
  }

  /// Update purchase status
  static Future<bool> updatePurchaseStatus(
    String purchaseId,
    PurchaseStatus status,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(purchaseId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating purchase status: $e');
      return false;
    }
  }

  /// Delete purchase
  static Future<bool> deletePurchase(String purchaseId) async {
    try {
      await _firestore.collection(collectionName).doc(purchaseId).delete();

      return true;
    } catch (e) {
      print('Error deleting purchase: $e');
      return false;
    }
  }

  /// Get all purchases (for admin)
  static Future<List<MembershipPurchase>> getAllPurchases() async {
    try {
      final querySnapshot = await _firestore.collection(collectionName).get();

      final purchases = querySnapshot.docs.map((doc) {
        return MembershipPurchase.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by purchaseDate in memory
      purchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      return purchases;
    } catch (e) {
      print('Error getting all purchases: $e');
      return [];
    }
  }

  /// Get purchases by status
  static Future<List<MembershipPurchase>> getPurchasesByStatus(
    PurchaseStatus status,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('status', isEqualTo: status.name)
          .get();

      final purchases = querySnapshot.docs.map((doc) {
        return MembershipPurchase.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by purchaseDate in memory
      purchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      return purchases;
    } catch (e) {
      print('Error getting purchases by status: $e');
      return [];
    }
  }

  /// Get purchases by card template
  static Future<List<MembershipPurchase>> getPurchasesByTemplate(
    String templateId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('cardId', isEqualTo: templateId)
          .get();

      final purchases = querySnapshot.docs.map((doc) {
        return MembershipPurchase.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by purchaseDate in memory
      purchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      return purchases;
    } catch (e) {
      print('Error getting purchases by template: $e');
      return [];
    }
  }

  /// Get purchase statistics
  static Future<Map<String, dynamic>> getPurchaseStatistics() async {
    try {
      final allPurchases = await getAllPurchases();

      final stats = <String, dynamic>{
        'totalPurchases': allPurchases.length,
        'activePurchases': 0,
        'expiredPurchases': 0,
        'pendingPurchases': 0,
        'cancelledPurchases': 0,
        'totalRevenue': 0.0,
        'monthlyRevenue': 0.0,
      };

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      for (final purchase in allPurchases) {
        // Count by status
        switch (purchase.status) {
          case PurchaseStatus.active:
            if (purchase.endDate.isAfter(now)) {
              stats['activePurchases'] = (stats['activePurchases'] as int) + 1;
            } else {
              stats['expiredPurchases'] =
                  (stats['expiredPurchases'] as int) + 1;
            }
            break;
          case PurchaseStatus.pending:
            stats['pendingPurchases'] = (stats['pendingPurchases'] as int) + 1;
            break;
          case PurchaseStatus.cancelled:
            stats['cancelledPurchases'] =
                (stats['cancelledPurchases'] as int) + 1;
            break;
          case PurchaseStatus.expired:
            stats['expiredPurchases'] = (stats['expiredPurchases'] as int) + 1;
            break;
        }

        // Calculate revenue
        final amount = purchase.price;
        stats['totalRevenue'] = (stats['totalRevenue'] as double) + amount;

        if (purchase.purchaseDate.isAfter(thisMonth)) {
          stats['monthlyRevenue'] =
              (stats['monthlyRevenue'] as double) + amount;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting purchase statistics: $e');
      return <String, dynamic>{
        'totalPurchases': 0,
        'activePurchases': 0,
        'expiredPurchases': 0,
        'pendingPurchases': 0,
        'cancelledPurchases': 0,
        'totalRevenue': 0.0,
        'monthlyRevenue': 0.0,
      };
    }
  }

  /// Stream user purchases
  static Stream<List<MembershipPurchase>> streamUserPurchases(String userId) {
    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MembershipPurchase.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Stream all purchases (for admin)
  static Stream<List<MembershipPurchase>> streamAllPurchases() {
    return _firestore
        .collection(collectionName)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MembershipPurchase.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
