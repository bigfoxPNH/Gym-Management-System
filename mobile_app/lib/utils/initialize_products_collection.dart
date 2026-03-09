import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to initialize the products collection in Firestore
/// Run this once to create the collection with a sample product
Future<void> initializeProductsCollection() async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Check if collection exists by trying to get documents
    final snapshot = await firestore.collection('products').limit(1).get();

    if (snapshot.docs.isEmpty) {
      print('Creating products collection...');

      // Create a sample product to initialize the collection
      await firestore.collection('products').add({
        'name': 'Sample Product',
        'category': 'Khác',
        'manufacturer': 'Sample',
        'originalPrice': 100000,
        'sellingPrice': 90000,
        'stockQuantity': 0,
        'description':
            'This is a sample product to initialize the collection. You can delete this.',
        'images': [],
        'status': 'outOfStock',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Products collection created successfully!');
    } else {
      print('✅ Products collection already exists');
    }
  } catch (e) {
    print('❌ Error initializing products collection: $e');
  }
}
