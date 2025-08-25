import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/membership_card.dart';

class MembershipCardService {
  static const String collectionName = 'membership_cards';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get collection reference
  CollectionReference get _collection => _firestore.collection(collectionName);

  // Create new membership card
  Future<String> createCard(MembershipCard card) async {
    try {
      final docRef = await _collection.add(card.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo thẻ tập: $e');
    }
  }

  // Update existing membership card
  Future<void> updateCard(MembershipCard card) async {
    try {
      await _collection.doc(card.id).update(card.toMap());
    } catch (e) {
      throw Exception('Không thể cập nhật thẻ tập: $e');
    }
  }

  // Delete membership card
  Future<void> deleteCard(String cardId) async {
    try {
      await _collection.doc(cardId).delete();
    } catch (e) {
      throw Exception('Không thể xóa thẻ tập: $e');
    }
  }

  // Get all membership cards
  Future<List<MembershipCard>> getAllCards() async {
    try {
      final querySnapshot = await _collection
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MembershipCard.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách thẻ tập: $e');
    }
  }

  // Get active membership cards only
  Future<List<MembershipCard>> getActiveCards() async {
    try {
      final querySnapshot = await _collection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MembershipCard.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách thẻ tập hoạt động: $e');
    }
  }

  // Get membership card by ID
  Future<MembershipCard?> getCardById(String cardId) async {
    try {
      final doc = await _collection.doc(cardId).get();
      if (doc.exists) {
        return MembershipCard.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tải thông tin thẻ tập: $e');
    }
  }

  // Get cards by type
  Future<List<MembershipCard>> getCardsByType(CardType cardType) async {
    try {
      final querySnapshot = await _collection
          .where('cardType', isEqualTo: cardType.name)
          .orderBy('price')
          .get();

      return querySnapshot.docs
          .map((doc) => MembershipCard.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải thẻ tập theo loại: $e');
    }
  }

  // Search cards by name
  Future<List<MembershipCard>> searchCards(String query) async {
    try {
      final allCards = await getAllCards();
      return allCards
          .where(
            (card) => card.cardName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Không thể tìm kiếm thẻ tập: $e');
    }
  }

  // Get statistics
  Future<Map<String, dynamic>> getCardStatistics() async {
    try {
      final allCards = await getAllCards();
      final activeCards = allCards.where((card) => card.isActive).toList();

      final memberCount = activeCards
          .where((card) => card.cardType == CardType.member)
          .length;
      final premiumCount = activeCards
          .where((card) => card.cardType == CardType.premium)
          .length;
      final vipCount = activeCards
          .where((card) => card.cardType == CardType.vip)
          .length;

      final totalRevenue = activeCards.fold<double>(
        0,
        (sum, card) => sum + card.price,
      );
      final averagePrice = activeCards.isNotEmpty
          ? totalRevenue / activeCards.length
          : 0.0;

      return {
        'totalCards': allCards.length,
        'activeCards': activeCards.length,
        'inactiveCards': allCards.length - activeCards.length,
        'memberCards': memberCount,
        'premiumCards': premiumCount,
        'vipCards': vipCount,
        'totalRevenue': totalRevenue,
        'averagePrice': averagePrice,
      };
    } catch (e) {
      throw Exception('Không thể tải thống kê thẻ tập: $e');
    }
  }

  // Toggle card status
  Future<void> toggleCardStatus(String cardId, bool isActive) async {
    try {
      await _collection.doc(cardId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Không thể thay đổi trạng thái thẻ tập: $e');
    }
  }

  // Get cards stream for real-time updates
  Stream<List<MembershipCard>> getCardsStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MembershipCard.fromFirestore(doc))
              .toList(),
        );
  }

  // Validate card data
  String? validateCard(MembershipCard card) {
    if (card.cardName.trim().isEmpty) {
      return 'Tên thẻ tập không được để trống';
    }

    if (card.cardName.trim().length < 3) {
      return 'Tên thẻ tập phải có ít nhất 3 ký tự';
    }

    if (card.description.trim().isEmpty) {
      return 'Mô tả thẻ tập không được để trống';
    }

    if (card.price <= 0) {
      return 'Giá tiền phải lớn hơn 0';
    }

    if (card.duration <= 0 && card.durationType != DurationType.custom) {
      return 'Thời gian sử dụng phải lớn hơn 0';
    }

    if (card.durationType == DurationType.custom &&
        card.customEndDate == null) {
      return 'Vui lòng chọn ngày kết thúc cho loại tùy chỉnh';
    }

    if (card.durationType == DurationType.custom &&
        card.customEndDate != null &&
        card.customEndDate!.isBefore(DateTime.now())) {
      return 'Ngày kết thúc phải lớn hơn ngày hiện tại';
    }

    return null; // No validation errors
  }
}
