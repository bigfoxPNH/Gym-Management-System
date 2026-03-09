import 'package:cloud_firestore/cloud_firestore.dart';

/// Script tạo dữ liệu mẫu cho products collection
/// Chạy script này để thêm sản phẩm mẫu vào Firestore
class ProductSampleData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addSampleProducts() async {
    final sampleProducts = [
      {
        'name': 'Whey Protein Gold Standard',
        'category': 'Whey Protein',
        'manufacturer': 'Optimum Nutrition',
        'originalPrice': 1500000,
        'sellingPrice': 1350000,
        'stockQuantity': 25,
        'description':
            'Whey protein cô đặc cao cấp, hỗ trợ tăng cơ nhanh chóng. Hương vị socola ngon, dễ uống.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_whey.jpg?alt=media',
        ],
        'status': 'in_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Serious Mass Gainer',
        'category': 'Mass',
        'manufacturer': 'Optimum Nutrition',
        'originalPrice': 1800000,
        'sellingPrice': 1700000,
        'stockQuantity': 15,
        'description':
            'Sữa tăng cân nặng cao cấp với 1250 calories và 50g protein mỗi serving. Phù hợp cho người khó tăng cân.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_mass.jpg?alt=media',
        ],
        'status': 'in_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Creatine Monohydrate',
        'category': 'Creatine',
        'manufacturer': 'MuscleTech',
        'originalPrice': 450000,
        'sellingPrice': 400000,
        'stockQuantity': 8,
        'description':
            'Creatine tinh khiết 100%, tăng sức mạnh và sức bền trong tập luyện.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_creatine.jpg?alt=media',
        ],
        'status': 'low_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'C4 Original Pre-Workout',
        'category': 'Pre-workout',
        'manufacturer': 'Cellucor',
        'originalPrice': 850000,
        'sellingPrice': 800000,
        'stockQuantity': 20,
        'description':
            'Pre-workout hỗ trợ tập luyện với caffeine, beta-alanine và creatine. Tăng năng lượng và tập trung.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_preworkout.jpg?alt=media',
        ],
        'status': 'in_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'BCAA 2:1:1',
        'category': 'BCAAs',
        'manufacturer': 'Scivation',
        'originalPrice': 550000,
        'sellingPrice': 500000,
        'stockQuantity': 12,
        'description':
            'BCAA tỷ lệ 2:1:1 hỗ trợ phục hồi cơ và giảm mệt mỏi. Hương chanh tươi mát.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_bcaa.jpg?alt=media',
        ],
        'status': 'in_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Vitamin C 1000mg',
        'category': 'Vitamin - Khoáng chất',
        'manufacturer': 'Nature Made',
        'originalPrice': 250000,
        'sellingPrice': 220000,
        'stockQuantity': 30,
        'description':
            'Viên uống Vitamin C 1000mg tăng cường hệ miễn dịch, chống oxy hóa.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_vitamin.jpg?alt=media',
        ],
        'status': 'in_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Protein Bar Chocolate',
        'category': 'Đồ ăn liền',
        'manufacturer': 'Quest Nutrition',
        'originalPrice': 50000,
        'sellingPrice': 45000,
        'stockQuantity': 50,
        'description':
            'Thanh protein 20g, ít đường, hương socola. Snack lý tưởng cho người tập gym.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_bar.jpg?alt=media',
        ],
        'status': 'in_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Găng Tay Tập Gym',
        'category': 'Dụng cụ tập',
        'manufacturer': 'Harbinger',
        'originalPrice': 350000,
        'sellingPrice': 320000,
        'stockQuantity': 18,
        'description':
            'Găng tay tập gym chất liệu da cao cấp, chống trượt, bảo vệ tay khi tập luyện.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_gloves.jpg?alt=media',
        ],
        'status': 'in_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Dây Kháng Lực Set 5 Mức',
        'category': 'Dụng cụ tập',
        'manufacturer': 'TRX',
        'originalPrice': 450000,
        'sellingPrice': 400000,
        'stockQuantity': 10,
        'description':
            'Bộ 5 dây kháng lực với các mức độ khác nhau. Phù hợp tập tại nhà hoặc phòng gym.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_bands.jpg?alt=media',
        ],
        'status': 'low_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Bình Lắc Shaker 700ml',
        'category': 'Khác',
        'manufacturer': 'BlenderBottle',
        'originalPrice': 150000,
        'sellingPrice': 130000,
        'stockQuantity': 0,
        'description':
            'Bình lắc protein cao cấp với bi lò xo inox, không BPA. Dung tích 700ml.',
        'images': [
          'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/sample_shaker.jpg?alt=media',
        ],
        'status': 'out_of_stock',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];

    try {
      print('Đang thêm ${sampleProducts.length} sản phẩm mẫu...');

      for (var product in sampleProducts) {
        await _firestore.collection('products').add(product);
        print('✓ Đã thêm: ${product['name']}');
      }

      print('\n✅ Hoàn thành! Đã thêm ${sampleProducts.length} sản phẩm mẫu.');
    } catch (e) {
      print('❌ Lỗi khi thêm sản phẩm mẫu: $e');
    }
  }

  /// Xóa tất cả sản phẩm (dùng để test)
  static Future<void> clearAllProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      print('Đang xóa ${snapshot.docs.length} sản phẩm...');

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print('✓ Đã xóa: ${doc.data()['name']}');
      }

      print('\n✅ Đã xóa tất cả sản phẩm.');
    } catch (e) {
      print('❌ Lỗi khi xóa sản phẩm: $e');
    }
  }
}

// Uncomment để chạy trong app
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   
//   // Thêm sản phẩm mẫu
//   await ProductSampleData.addSampleProducts();
//   
//   // Hoặc xóa tất cả sản phẩm
//   // await ProductSampleData.clearAllProducts();
// }
