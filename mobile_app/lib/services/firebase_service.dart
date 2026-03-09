import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_account.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get usersCollection => _firestore.collection('users');

  // User operations
  static Future<void> createUserDocument(
    User firebaseUser, {
    String? fullName,
  }) async {
    try {
      final userAccount = UserAccount(
        id: firebaseUser.uid,
        fullName: fullName ?? firebaseUser.displayName ?? '',
        avatarUrl: firebaseUser.photoURL,
        email: firebaseUser.email ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userAccount.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  Future<void> createUser(UserAccount userAccount) async {
    try {
      await usersCollection.doc(userAccount.id).set(userAccount.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserAccount?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserAccount.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await usersCollection.doc(userId).update({
        ...data,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Alias for updateUser - for profile updates
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final service = FirebaseService();
    await service.updateUser(userId, data);
  }

  Future<void> deleteUser(String userId) async {
    try {
      await usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  static Future<void> deleteUserAccount(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user account: $e');
    }
  }

  // Stream for real-time user data
  Stream<UserAccount?> userStream(String userId) {
    return usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserAccount.fromDocument(doc);
      }
      return null;
    });
  }
}
