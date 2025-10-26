import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/trainer_rental_controller.dart';
import '../../models/trainer.dart';

/// Màn hình chi tiết PT và form thuê
class TrainerRentalDetailView extends StatefulWidget {
  final Trainer trainer;

  const TrainerRentalDetailView({super.key, required this.trainer});

  @override
  State<TrainerRentalDetailView> createState() =>
      _TrainerRentalDetailViewState();
}

class _TrainerRentalDetailViewState extends State<TrainerRentalDetailView> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<TrainerRentalController>();

  DateTime? _startDate;
  DateTime? _endDate;
  int _soGio = 4;
  String _goiTap = 'personal';
  final _ghiChuController = TextEditingController();

  @override
  void dispose() {
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết PT'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar
            _buildHeader(),

            // Info sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildExperienceSection(),
                  const SizedBox(height: 24),
                  _buildCertificatesSection(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildRentalForm(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.trainer.anhDaiDien != null
                      ? NetworkImage(widget.trainer.anhDaiDien!)
                      : null,
                  child: widget.trainer.anhDaiDien == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                widget.trainer.hoTen,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber[300], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.trainer.danhGiaTrungBinh.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${widget.trainer.soLuotDanhGia} đánh giá)',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    Icons.work_history,
                    '${_getExperienceYears(widget.trainer.ngayVaoLam)} năm',
                    'Kinh nghiệm',
                  ),
                  _buildStatItem(
                    Icons.verified,
                    '${widget.trainer.bangCap.length}',
                    'Chứng chỉ',
                  ),
                  _buildStatItem(
                    Icons.fitness_center,
                    '${widget.trainer.chuyenMon.length}',
                    'Chuyên môn',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông Tin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.trainer.email != null)
          _buildInfoRow(Icons.email, widget.trainer.email!),
        if (widget.trainer.soDienThoai != null)
          _buildInfoRow(Icons.phone, widget.trainer.soDienThoai!),
        if (widget.trainer.gioiTinh != null)
          _buildInfoRow(Icons.person, widget.trainer.gioiTinh!),
        if (widget.trainer.moTa != null && widget.trainer.moTa!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              widget.trainer.moTa!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    if (widget.trainer.chuyenMon.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chuyên Môn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.trainer.chuyenMon.map((skill) {
            return Chip(
              label: Text(skill),
              backgroundColor: Colors.deepPurple.shade50,
              avatar: Icon(
                Icons.fitness_center,
                size: 18,
                color: Colors.deepPurple.shade700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCertificatesSection() {
    if (widget.trainer.bangCap.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bằng Cấp & Chứng Chỉ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...widget.trainer.bangCap.map((cert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(cert, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRentalForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đặt Lịch Tập',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Gói tập
          const Text(
            'Chọn Gói Tập',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildPackageSelector(),
          const SizedBox(height: 16),

          // Số giờ
          const Text(
            'Số Giờ Tập',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildHoursSelector(),
          const SizedBox(height: 16),

          // Ngày bắt đầu
          const Text(
            'Ngày Bắt Đầu',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectStartDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _startDate == null
                        ? 'Chọn ngày bắt đầu'
                        : DateFormat('dd/MM/yyyy').format(_startDate!),
                    style: TextStyle(
                      fontSize: 14,
                      color: _startDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ngày kết thúc
          const Text(
            'Ngày Kết Thúc',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectEndDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _endDate == null
                        ? 'Chọn ngày kết thúc'
                        : DateFormat('dd/MM/yyyy').format(_endDate!),
                    style: TextStyle(
                      fontSize: 14,
                      color: _endDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ghi chú
          const Text(
            'Ghi Chú (không bắt buộc)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ghiChuController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mục tiêu tập luyện, thời gian phù hợp...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSelector() {
    return Column(
      children: [
        _buildPackageOption(
          'personal',
          'Cá Nhân 1-1',
          '300,000đ/giờ',
          'Tập riêng với PT',
          Icons.person,
        ),
        const SizedBox(height: 8),
        _buildPackageOption(
          'group',
          'Nhóm Nhỏ',
          '150,000đ/giờ',
          'Tập cùng 2-4 người',
          Icons.people,
        ),
        const SizedBox(height: 8),
        _buildPackageOption(
          'online',
          'Online',
          '200,000đ/giờ',
          'Tập qua video call',
          Icons.videocam,
        ),
      ],
    );
  }

  Widget _buildPackageOption(
    String value,
    String title,
    String price,
    String desc,
    IconData icon,
  ) {
    final isSelected = _goiTap == value;
    return InkWell(
      onTap: () => setState(() => _goiTap = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.deepPurple : Colors.black,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: _soGio > 1 ? () => setState(() => _soGio--) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: Colors.deepPurple,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_soGio giờ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          onPressed: _soGio < 20 ? () => setState(() => _soGio++) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final tongTien = _calculateTotal();
    final numberFormat = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${numberFormat.format(tongTien)}đ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : _submitRental,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Gửi Yêu Cầu Thuê PT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    double giaMoiGio;
    switch (_goiTap) {
      case 'personal':
        giaMoiGio = 300000;
        break;
      case 'group':
        giaMoiGio = 150000;
        break;
      case 'online':
        giaMoiGio = 200000;
        break;
      default:
        giaMoiGio = 300000;
    }
    return giaMoiGio * _soGio;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submitRental() async {
    if (_startDate == null) {
      Get.snackbar('Thiếu thông tin', 'Vui lòng chọn ngày bắt đầu');
      return;
    }
    if (_endDate == null) {
      Get.snackbar('Thiếu thông tin', 'Vui lòng chọn ngày kết thúc');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      Get.snackbar('Lỗi', 'Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }

    final success = await controller.createRental(
      trainer: widget.trainer,
      startDate: _startDate!,
      endDate: _endDate!,
      soGio: _soGio,
      goiTap: _goiTap,
      ghiChu: _ghiChuController.text.trim().isEmpty
          ? null
          : _ghiChuController.text.trim(),
    );

    if (success) {
      Get.back(); // Quay lại danh sách PT
      Get.toNamed('/my-trainer-rentals'); // Đi đến lịch sử
    }
  }

  int _getExperienceYears(DateTime startDate) {
    final now = DateTime.now();
    final diff = now.difference(startDate);
    return (diff.inDays / 365).floor();
  }
}
