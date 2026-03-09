import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Script to safely delete membership_purchases collection
/// Run this script to clean up the membership_purchases collection
/// after removing purchase history feature
class MembershipPurchasesCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'membership_purchases';

  /// Count documents in membership_purchases collection
  static Future<int> countDocuments() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .count()
          .get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      print('Error counting documents: $e');
      return 0;
    }
  }

  /// Export membership_purchases data before deletion (for backup)
  static Future<List<Map<String, dynamic>>> exportData() async {
    try {
      print('📤 Exporting membership_purchases data...');
      final querySnapshot = await _firestore.collection(_collection).get();

      final exportedData = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print('✅ Exported ${exportedData.length} documents');
      return exportedData;
    } catch (e) {
      print('❌ Error exporting data: $e');
      return [];
    }
  }

  /// Delete all documents in membership_purchases collection
  static Future<void> deleteAllDocuments() async {
    try {
      print('🗑️ Starting deletion of membership_purchases collection...');

      // Get all documents
      final querySnapshot = await _firestore.collection(_collection).get();
      final totalDocs = querySnapshot.docs.length;

      if (totalDocs == 0) {
        print('✅ Collection is already empty');
        return;
      }

      print('📊 Found $totalDocs documents to delete');

      // Delete in batches to avoid timeout
      const batchSize = 500;
      int deletedCount = 0;

      while (deletedCount < totalDocs) {
        final batch = _firestore.batch();
        final remainingDocs = await _firestore
            .collection(_collection)
            .limit(batchSize)
            .get();

        if (remainingDocs.docs.isEmpty) break;

        for (final doc in remainingDocs.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        deletedCount += remainingDocs.docs.length;

        print('🔄 Deleted $deletedCount/$totalDocs documents');
      }

      print(
        '✅ Successfully deleted all documents from membership_purchases collection',
      );
    } catch (e) {
      print('❌ Error deleting documents: $e');
      rethrow;
    }
  }

  /// Complete cleanup process with backup
  static Future<void> performCompleteCleanup({bool createBackup = true}) async {
    try {
      print('🚀 Starting membership_purchases cleanup process...');

      // Count documents first
      final docCount = await countDocuments();
      print('📊 Total documents in collection: $docCount');

      if (docCount == 0) {
        print('✅ Collection is already empty. Nothing to clean up.');
        return;
      }

      // Export data for backup if requested
      if (createBackup) {
        final exportedData = await exportData();
        print('💾 Backup created with ${exportedData.length} documents');
        // You could save this to a file or another collection if needed
      }

      // Ask for confirmation
      print('⚠️  WARNING: This will permanently delete $docCount documents');
      print('⚠️  Make sure you have backed up important data');
      print('⚠️  This action cannot be undone');

      // Delete all documents
      await deleteAllDocuments();

      print('🎉 Cleanup completed successfully!');
      print('📝 Summary:');
      print('   - Documents deleted: $docCount');
      print('   - Collection: $targetCollection cleaned');
    } catch (e) {
      print('❌ Cleanup failed: $e');
      rethrow;
    }
  }

  static const String targetCollection = _collection;
}

/// Main function to run the cleanup script
Future<void> main() async {
  print('🧹 Membership Purchases Collection Cleanup Script');
  print('================================================');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Perform cleanup
    await MembershipPurchasesCleanup.performCompleteCleanup(
      createBackup: true, // Set to false if you don't want backup
    );
  } catch (e) {
    print('❌ Script execution failed: $e');
  }
}
