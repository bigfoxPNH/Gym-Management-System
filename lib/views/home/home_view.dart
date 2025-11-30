import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/loading_overlay.dart';
import '../../features/ai_chat/widgets/draggable_ai_chat_button.dart';
import '../../features/ai_chat/views/ai_chat_view.dart';
import '../../models/news.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _latestNews = [];
  List<Map<String, dynamic>> _popularExercises = [];
  List<Map<String, dynamic>> _popularMembershipCards = [];

  @override
  void initState() {
    super.initState();
    // Load data immediately without blocking UI
    _loadDataAsync();
  }

  Future<void> _loadDataAsync() async {
    // Load data asynchronously in background
    _loadNews();
    _loadExercises();
    _loadMembershipCards();
  }

  Future<void> _loadNews() async {
    try {
      final newsSnapshot = await _firestore
          .collection('news')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      if (mounted) {
        setState(() {
          _latestNews = newsSnapshot.docs.map((doc) {
            final news = News.fromFirestore(doc);
            // Serialize to a plain Map without Timestamp objects
            return {
              'id': news.id,
              'title': news.title,
              'type': news.type.name,
              'images': news.images,
              'description': news.description,
              'detailImages': news.detailImages,
              'videoUrl': news.videoUrl,
              'interaction': {
                'likes': news.interaction.likes,
                'shares': news.interaction.shares,
                'comments': news.interaction.comments,
                'reports': news.interaction.reports,
              },
              'createdAt': news.createdAt.millisecondsSinceEpoch,
              'updatedAt': news.updatedAt?.millisecondsSinceEpoch,
              'authorId': news.authorId,
              'authorName': news.authorName,
              'isPublished': news.isPublished,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading news: $e');
    }
  }

  Future<void> _loadExercises() async {
    try {
      final exercisesSnapshot = await _firestore
          .collection('exercises')
          .limit(6)
          .get();

      if (mounted) {
        setState(() {
          _popularExercises = exercisesSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
      }
    } catch (e) {
      print('Error loading exercises: $e');
    }
  }

  Future<void> _loadMembershipCards() async {
    try {
      final cardsSnapshot = await _firestore
          .collection('membership_cards')
          .orderBy('price')
          .limit(4)
          .get();

      if (mounted) {
        setState(() {
          _popularMembershipCards = cardsSnapshot.docs.map((doc) {
            final data = doc.data();
            final result = {
              ...data,
              'id': doc.id, // Put id AFTER data to ensure it's not overridden
            };
            print(
              'Loading card - Doc ID: ${doc.id}, Result ID: ${result['id']}',
            );
            return result;
          }).toList();
          print('Loaded ${_popularMembershipCards.length} membership cards');
          for (var card in _popularMembershipCards) {
            print(
              'Card: ${card['cardName'] ?? card['name']} - ID in list: ${card['id']}',
            );
          }
        });
      }
    } catch (e) {
      print('Error loading membership cards: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.userAccount;

      // Redirect PT users to PT Dashboard (nếu vào nhầm trang này)
      // Note: Login flow đã xử lý redirect rồi, chỉ cần check để phòng trường hợp vào trực tiếp
      if (user != null && user.isTrainer) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(AppRoutes.ptDashboard);
        });
        return const CenterLoading(message: 'Đang chuyển hướng...');
      }

      return _buildMoMoStyleHome(context, authController);
    });
  }

  Widget _buildMoMoStyleHome(
    BuildContext context,
    AuthController authController,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Obx(() {
          final user = authController.userAccount;
          return Row(
            children: [
              const Text('Gym Pro'),
              if (user != null && user.isAdmin) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.profile),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(
            () => authController.userAccount != null
                ? _buildHomeContent(context, authController)
                : const CenterLoading(message: 'Đang tải...'),
          ),
          // AI Chat Button (draggable)
          const DraggableAIChatButton(),
          // AI Chat View
          const AIChatView(),
        ],
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    AuthController authController,
  ) {
    final user = authController.userAccount!;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadDataAsync();
      },
      color: const Color(0xFFB31E51),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFB31E51),
                    const Color(0xFFD91A5B),
                    const Color(0xFFFF6B9D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB31E51).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Tìm kiếm bài tập, gói tập...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) {
                              // Tự động tìm kiếm khi gõ (debounce)
                              if (value.length >= 2) {
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    if (_searchController.text == value &&
                                        value.isNotEmpty) {
                                      Get.toNamed(
                                        '/exercises',
                                        arguments: {'search': value},
                                      );
                                    }
                                  },
                                );
                              }
                            },
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                Get.toNamed(
                                  '/exercises',
                                  arguments: {'search': value},
                                );
                              }
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Features (chỉ hiển thị cho admin)
                  if (user.isAdmin) ...[
                    _buildSectionHeader('Quản Trị Viên', Colors.red),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                        children: [
                          _buildImageIconButton(
                            imagePath: 'assets/images/admin/exercise.png',
                            label: 'Quản Lý Bài Tập',
                            onTap: () =>
                                Get.toNamed('/admin/exercise-management'),
                            index: 0,
                          ),
                          _buildImageIconButton(
                            imagePath:
                                'assets/images/admin/membership_card.png',
                            label: 'Quản Lý Thẻ Tập',
                            onTap: () => Get.toNamed(
                              '/admin/membership-card-management',
                            ),
                            index: 1,
                          ),
                          _buildImageIconButton(
                            imagePath: 'assets/images/admin/manager_member.png',
                            label: 'Quản Lý Thành Viên',
                            onTap: () =>
                                Get.toNamed(AppRoutes.memberManagement),
                            index: 2,
                          ),
                          _buildImageIconButton(
                            imagePath: 'assets/images/admin/user_schedule.png',
                            label: 'Quản Lý Lịch Trình',
                            onTap: () =>
                                Get.toNamed(AppRoutes.scheduleManagement),
                            index: 3,
                          ),
                          _buildImageIconButton(
                            imagePath:
                                'assets/images/admin/checkin_checkout.png',
                            label: 'Check In/Out',
                            onTap: () => Get.toNamed(AppRoutes.checkinCheckout),
                            index: 4,
                          ),
                          _buildImageIconButton(
                            imagePath: 'assets/images/admin/baocaothongke.png',
                            label: 'Thống Kê',
                            onTap: () => Get.toNamed(AppRoutes.adminStatistics),
                            index: 5,
                          ),
                          _buildImageIconButton(
                            imagePath: 'assets/images/admin/news.png',
                            label: 'Quản Lý Bản Tin',
                            onTap: () => Get.toNamed('/admin/news-management'),
                            index: 6,
                          ),
                          _buildImageIconButton(
                            imagePath: 'assets/images/admin/manager_pt.png',
                            label: 'Quản Lý PT',
                            onTap: () =>
                                Get.toNamed(AppRoutes.trainerManagement),
                            index: 7,
                          ),
                          _buildImageIconButton(
                            imagePath: 'assets/images/admin/manager_goods.png',
                            label: 'Quản Lý Sản Phẩm',
                            onTap: () =>
                                Get.toNamed(AppRoutes.productManagement),
                            index: 8,
                          ),
                          _buildImageIconButton(
                            imagePath: 'assets/images/admin/purchase_order.png',
                            label: 'Quản lý Đơn Mua',
                            onTap: () => Get.toNamed(AppRoutes.orderManagement),
                            index: 9,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quick Actions (cho tất cả users)
                  _buildSectionHeader('Dịch Vụ', const Color(0xFF2196F3)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                      children: [
                        _buildImageIconButton(
                          imagePath: 'assets/images/user/khobaitap.png',
                          label: 'Kho Bài Tập',
                          onTap: () => Get.toNamed('/exercises'),
                          index: 0,
                        ),
                        _buildImageIconButton(
                          imagePath: 'assets/images/user/thecuatoi.png',
                          label: 'Thẻ Của Tôi',
                          onTap: () => Get.toNamed(AppRoutes.myMembershipCards),
                          index: 1,
                        ),
                        _buildImageIconButton(
                          imagePath: 'assets/images/user/xuatthe.png',
                          label: 'Xuất Thẻ',
                          onTap: () =>
                              Get.toNamed(AppRoutes.membershipCardExport),
                          index: 2,
                        ),
                        _buildImageIconButton(
                          imagePath: 'assets/images/user/lichtap.png',
                          label: 'Lịch Tập',
                          onTap: () =>
                              Get.toNamed(AppRoutes.userScheduleSelection),
                          index: 3,
                        ),
                        _buildImageIconButton(
                          imagePath: 'assets/images/user/muathetap.png',
                          label: 'Mua Thẻ Tập',
                          onTap: () =>
                              Get.toNamed(AppRoutes.membershipPurchase),
                          index: 4,
                        ),
                        _buildImageIconButton(
                          imagePath: 'assets/images/user/bangtin.png',
                          label: 'Bảng Tin',
                          onTap: () => Get.toNamed(AppRoutes.newsFeed),
                          index: 5,
                        ),
                        _buildImageIconButton(
                          imagePath: 'assets/images/user/thuept.png',
                          label: 'Thuê PT',
                          onTap: () => Get.toNamed(AppRoutes.trainerRental),
                          index: 6,
                        ),
                        _buildImageIconButton(
                          imagePath: 'assets/images/user/muasanpham.png',
                          label: 'Mua Sản Phẩm',
                          onTap: () => Get.toNamed(AppRoutes.userProducts),
                          index: 7,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Latest News Section
                  _buildSectionHeader(
                    'Tin Tức & Sự Kiện',
                    const Color(0xFFFF6B9D),
                  ),
                  const SizedBox(height: 12),
                  _buildNewsSection(),
                  const SizedBox(height: 24),

                  // Popular Exercises
                  _buildSectionHeader('Bài Tập Phổ Biến', Colors.orange),
                  const SizedBox(height: 12),
                  _buildPopularExercisesSection(),
                  const SizedBox(height: 24),

                  // Popular Membership Cards
                  _buildSectionHeader('Gói Tập Phổ Biến', Colors.green),
                  const SizedBox(height: 12),
                  _buildPopularCardsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionHeader(String title, Color color) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(-20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ).createShader(bounds),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoMoIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int index = 0,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 80)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageIconButton({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
    int index = 0,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 60)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                          size: 32,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    if (_latestNews.isEmpty) {
      // Skeleton loading
      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) {
            return _buildNewsCardSkeleton();
          },
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _latestNews.length,
        itemBuilder: (context, index) {
          final news = _latestNews[index];
          return _buildNewsCard(news);
        },
      ),
    );
  }

  Widget _buildNewsCardSkeleton() {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  strokeWidth: 2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 150,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (news['id'] != null) {
              Get.toNamed('${AppRoutes.newsDetailUser}/${news['id']}');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 300,
            height: 220, // Fixed height
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section with gradient overlay
                  Stack(
                    children: [
                      if (news['detailImages'] != null &&
                          (news['detailImages'] as List).isNotEmpty)
                        Image.network(
                          news['detailImages'][0],
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pink[100]!,
                                    Colors.purple[100]!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.pink[100]!, Colors.purple[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.article_outlined,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              news['description'] ?? 'Không có mô tả',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.pink[50]!,
                                      Colors.purple[50]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  news['authorName'] ?? 'Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.pink[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularExercisesSection() {
    if (_popularExercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Chưa có bài tập')),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _popularExercises.length > 6 ? 6 : _popularExercises.length,
      itemBuilder: (context, index) {
        final exercise = _popularExercises[index];
        return _buildExerciseCard(exercise, index);
      },
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    final imageUrl =
        (exercise['anhMinhHoa'] != null &&
            (exercise['anhMinhHoa'] as List).isNotEmpty)
        ? exercise['anhMinhHoa'][0]
        : '';
    final name = exercise['tenBaiTap'] ?? 'Bài tập';
    final muscleGroup = exercise['nhomCo'] ?? 'Chung';

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              if (exercise['id'] != null) {
                Get.toNamed(
                  AppRoutes.exercises,
                  arguments: {'exerciseId': exercise['id']},
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section with gradient overlay
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return TweenAnimationBuilder(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          tween: Tween<double>(
                                            begin: 0,
                                            end: 1,
                                          ),
                                          builder: (context, double value, _) {
                                            return Opacity(
                                              opacity: value,
                                              child: child,
                                            );
                                          },
                                        );
                                      }
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange[100]!,
                                              Colors.orange[50]!,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.orange,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange[100]!,
                                          Colors.orange[50]!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center,
                                      size: 48,
                                      color: Colors.orange,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange[100]!,
                                      Colors.orange[50]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  size: 48,
                                  color: Colors.orange,
                                ),
                              ),
                        // Gradient overlay at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content section
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (muscleGroup.isNotEmpty &&
                          muscleGroup.toLowerCase() != 'chung') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 11,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  muscleGroup,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularCardsSection() {
    if (_popularMembershipCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Chưa có gói tập')),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _popularMembershipCards.length,
        itemBuilder: (context, index) {
          final card = _popularMembershipCards[index];
          return _buildMembershipCard(card);
        },
      ),
    );
  }

  String _getCardDurationText(Map<String, dynamic> card) {
    final duration = card['duration'] ?? 0;
    final durationType = card['durationType'] ?? 'months';

    switch (durationType) {
      case 'days':
        return '$duration ngày';
      case 'months':
        return '$duration tháng';
      case 'years':
        return '$duration năm';
      case 'custom':
        if (card['customEndDate'] != null) {
          final endDate = DateTime.fromMillisecondsSinceEpoch(
            card['customEndDate'],
          );
          return 'Đến ${DateFormat('dd/MM/yyyy').format(endDate)}';
        }
        return '$duration ngày';
      default:
        return '$duration ngày';
    }
  }

  Widget _buildMembershipCard(Map<String, dynamic> card) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('Card clicked: ${card['cardName']} - ID: ${card['id']}');
          if (card['id'] != null && card['id'].toString().isNotEmpty) {
            print('Navigating with ID: ${card['id']}');
            Get.toNamed(
              AppRoutes.membershipPurchase,
              arguments: {'selectedCardId': card['id']},
            );
          } else {
            print('Card ID is null or empty!');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 180,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green[400]!,
                Colors.green[500]!,
                Colors.green[600]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card['cardName'] ?? card['name'] ?? 'Gói tập',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCardDurationText(card),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: '₫',
                    ).format(card['price'] ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
