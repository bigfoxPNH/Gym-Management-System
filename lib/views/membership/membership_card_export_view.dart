import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../services/qr_checkin_service.dart';

class MembershipCardExportView extends StatefulWidget {
  const MembershipCardExportView({super.key});

  @override
  State<MembershipCardExportView> createState() =>
      _MembershipCardExportViewState();
}

class _MembershipCardExportViewState extends State<MembershipCardExportView> {
  final authController = Get.find<AuthController>();
  String? qrData;
  List<Map<String, dynamic>> activeMemberships = [];
  bool isLoadingMemberships = true;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
    _loadActiveMemberships();
  }

  void _generateQRCode() async {
    final user = authController.userAccount;
    if (user != null) {
      final qr = await QRCheckinService.generateUserQRData(user.id, user.email);
      setState(() {
        qrData = qr;
      });
    }
  }

  void _loadActiveMemberships() async {
    final user = authController.userAccount;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final firestore = FirebaseFirestore.instance;

      // Query user_memberships collection
      final userMembershipsQuery = await firestore
          .collection('user_memberships')
          .where('userId', isEqualTo: user.id)
          .get();

      List<Map<String, dynamic>> memberships = [];

      for (final doc in userMembershipsQuery.docs) {
        final data = doc.data();
        final isActive = data['isActive'] ?? false;
        final paymentStatus = data['paymentStatus'] ?? '';
        final endDate = (data['endDate'] as Timestamp?)?.toDate();

        if (isActive &&
            paymentStatus == 'completed' &&
            endDate != null &&
            endDate.isAfter(now)) {
          final startDate = (data['startDate'] as Timestamp?)?.toDate() ?? now;
          memberships.add({
            'id': doc.id,
            'cardName':
                data['membershipCardName'] ?? data['cardName'] ?? 'Thẻ tập',
            'endDate': endDate,
            'startDate': startDate,
            'price': data['price'] ?? 0,
            'paymentMethod': data['paymentMethod'] ?? 'Trực tiếp',
          });
        }
      }

      // Fallback: check membership_purchases collection
      if (memberships.isEmpty) {
        final purchasesQuery = await firestore
            .collection('membership_purchases')
            .where('userId', isEqualTo: user.id)
            .get();

        for (final doc in purchasesQuery.docs) {
          final data = doc.data();
          final paymentStatus = data['paymentStatus'] ?? '';
          final status = data['status'] ?? '';
          final endDate = (data['endDate'] as Timestamp?)?.toDate();

          if ((paymentStatus == 'completed' || status == 'active') &&
              endDate != null &&
              endDate.isAfter(now)) {
            final startDate =
                (data['startDate'] as Timestamp?)?.toDate() ?? now;
            memberships.add({
              'id': doc.id,
              'cardName': data['cardName'] ?? 'Thẻ tập',
              'endDate': endDate,
              'startDate': startDate,
              'price': data['price'] ?? 0,
              'paymentMethod': data['paymentMethod'] ?? 'Trực tiếp',
            });
          }
        }
      }

      setState(() {
        activeMemberships = memberships;
        isLoadingMemberships = false;
      });
    } catch (e) {
      print('Error loading memberships: $e');
      setState(() {
        isLoadingMemberships = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authController.userAccount;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Xuất Thẻ Tập'),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xuất Thẻ Tập'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.card_membership,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GYM PRO',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'MEMBER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: qrData != null
                        ? QrImageView(
                            data: qrData!,
                            version: QrVersions.auto,
                            size: 160.0,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          )
                        : const SizedBox(
                            width: 160,
                            height: 160,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // User Name
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // User ID
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID: ${user.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Personal Information Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông Tin Cá Nhân',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2196F3),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildInfoRow(
                    context,
                    icon: Icons.person,
                    label: 'Họ và tên',
                    value: user.fullName,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    context,
                    icon: Icons.email,
                    label: 'Email',
                    value: user.email,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    context,
                    icon: Icons.phone,
                    label: 'Số điện thoại',
                    value: user.phone ?? 'Chưa cập nhật',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    context,
                    icon: Icons.wc,
                    label: 'Giới tính',
                    value: user.gender?.toString().split('.').last == 'male'
                        ? 'Nam'
                        : user.gender?.toString().split('.').last == 'female'
                        ? 'Nữ'
                        : 'Khác',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Ngày sinh',
                    value: user.dob != null
                        ? '${user.dob!.day}/${user.dob!.month}/${user.dob!.year}'
                        : 'Chưa cập nhật',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    context,
                    icon: Icons.verified_user,
                    label: 'Trạng thái',
                    value: user.isAdmin ? 'Quản trị viên' : 'Thành viên',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Active Memberships Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thẻ Tập Đang Hoạt Động',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2196F3),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (isLoadingMemberships)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (activeMemberships.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.card_membership_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hiện tại không có thẻ nào hoạt động',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: activeMemberships.map((membership) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.card_membership,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      membership['cardName'] ?? 'Thẻ tập',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildMembershipInfoRow(
                                Icons.calendar_today,
                                'Bắt đầu',
                                _formatMembershipDate(membership['startDate']),
                              ),
                              const SizedBox(height: 8),
                              _buildMembershipInfoRow(
                                Icons.event,
                                'Kết thúc',
                                _formatMembershipDate(membership['endDate']),
                              ),
                              if (membership['price'] != null &&
                                  membership['price'] > 0) ...[
                                const SizedBox(height: 8),
                                _buildMembershipInfoRow(
                                  Icons.monetization_on,
                                  'Giá',
                                  '${_formatPrice(membership['price'])} VND',
                                ),
                              ],
                              if (membership['paymentMethod'] != null) ...[
                                const SizedBox(height: 8),
                                _buildMembershipInfoRow(
                                  Icons.payment,
                                  'Thanh toán',
                                  _formatPaymentMethod(
                                    membership['paymentMethod'].toString(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hướng dẫn sử dụng',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Đưa mã QR này cho nhân viên để check-in/check-out\n'
                    '• Mã QR chứa thông tin định danh của bạn\n'
                    '• Không chia sẻ mã QR với người khác\n'
                    '• Liên hệ quản trị viên nếu gặp vấn đề',
                    style: TextStyle(color: Colors.blue[700], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2196F3)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label: ',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMembershipDate(dynamic date) {
    if (date == null) return 'N/A';

    DateTime? dateTime;

    if (date is DateTime) {
      dateTime = date;
    } else if (date is Timestamp) {
      dateTime = date.toDate();
    } else {
      // Try to parse string
      try {
        dateTime = DateTime.parse(date.toString());
      } catch (e) {
        return date.toString();
      }
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    final numPrice = price is num
        ? price
        : (num.tryParse(price.toString()) ?? 0);
    return numPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatPaymentMethod(String? paymentMethod) {
    if (paymentMethod == null) return 'Chưa cập nhật';

    switch (paymentMethod.toLowerCase()) {
      case 'direct':
        return 'Trực tiếp';
      case 'momo':
        return 'MoMo';
      case 'banking':
      case 'bank':
        return 'Chuyển khoản';
      case 'cash':
        return 'Tiền mặt';
      case 'card':
        return 'Thẻ';
      case 'online':
        return 'Thanh toán online';
      default:
        return paymentMethod;
    }
  }
}
