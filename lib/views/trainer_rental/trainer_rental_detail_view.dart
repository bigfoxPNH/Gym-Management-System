import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/trainer_rental_controller.dart';
import '../../models/trainer.dart';
import '../../models/trainer_rental.dart';
import '../../models/certificate.dart';

/// Model cho 1 buổi tập cụ thể
class TrainingSession {
  DateTime dateTime; // Ngày và giờ bắt đầu
  int durationHours; // Số giờ tập

  TrainingSession({required this.dateTime, required this.durationHours});

  DateTime get endTime => dateTime.add(Duration(hours: durationHours));
}

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
  int _soGioMoiBuoi = 1; // Số giờ mỗi buổi
  String _khoaTap = '3buoi'; // 3buoi, 5buoi, 7buoi (số buổi/tuần)
  List<TrainingSession> _sessions = []; // Danh sách các buổi tập đã lên lịch
  final _ghiChuController = TextEditingController();

  // Helper để tính số buổi tập theo khóa
  int get _soBuoiTrongTuan {
    switch (_khoaTap) {
      case '3buoi':
        return 3;
      case '5buoi':
        return 5;
      case '7buoi':
        return 7;
      default:
        return 3;
    }
  }

  // Tính tổng số buổi trong khóa
  int get _tongSoBuoi {
    if (_startDate == null || _endDate == null) {
      // Nếu chưa chọn ngày, giả định 1 tháng (4 tuần)
      return _soBuoiTrongTuan * 4;
    }
    final weeks = _endDate!.difference(_startDate!).inDays / 7;
    return (weeks * _soBuoiTrongTuan).ceil();
  }

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
                    '${widget.trainer.namKinhNghiem} năm',
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

        // Trình độ PT
        _buildInfoRow(Icons.military_tech, widget.trainer.trinhDoPTText),

        // Giá thuê
        _buildInfoRow(
          Icons.attach_money,
          '${(widget.trainer.giaMoiGio / 1000).toStringAsFixed(0)}k/giờ',
        ),

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
    if (widget.trainer.bangCap.isEmpty && widget.trainer.chungChi.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bằng Cấp & Chứng Chỉ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Bằng cấp
        if (widget.trainer.bangCap.isNotEmpty) ...[
          const Text(
            'Bằng cấp',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...widget.trainer.bangCap.map((cert) => _buildCertCard(cert, true)),
          const SizedBox(height: 12),
        ],

        // Chứng chỉ
        if (widget.trainer.chungChi.isNotEmpty) ...[
          const Text(
            'Chứng chỉ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...widget.trainer.chungChi.map((cert) => _buildCertCard(cert, false)),
        ],
      ],
    );
  }

  Widget _buildCertCard(Certificate cert, bool isDegree) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh chứng chỉ nếu có
          if (cert.anhUrl != null && cert.anhUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: cert.anhUrl!.startsWith('data:image')
                  ? Image.memory(
                      Uri.parse(cert.anhUrl!).data!.contentAsBytes(),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      cert.anhUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
            ),

          // Thông tin chứng chỉ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDegree ? Icons.verified : Icons.workspace_premium,
                      color: isDegree
                          ? Colors.green.shade600
                          : Colors.blue.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cert.ten,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (cert.moTa != null && cert.moTa!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    cert.moTa!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
                if (cert.ngayCap != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ngày cấp: ${cert.ngayCap!.day}/${cert.ngayCap!.month}/${cert.ngayCap!.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
          const SizedBox(height: 8),

          // Thông tin giá
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giá thuê: ${(widget.trainer.giaMoiGio / 1000).toStringAsFixed(0)}k/giờ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

          // Lên lịch các buổi tập
          if (_startDate != null && _endDate != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch Tập Cụ Thể',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_sessions.length}/$_tongSoBuoi buổi',
                  style: TextStyle(
                    fontSize: 12,
                    color: _sessions.length == _tongSoBuoi
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khóa tập: $_soBuoiTrongTuan buổi/tuần',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (_sessions.isEmpty)
                    Center(
                      child: TextButton.icon(
                        onPressed: _addSession,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Thêm buổi tập đầu tiên'),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ..._sessions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final session = entry.value;
                          return _buildSessionCard(index, session);
                        }).toList(),
                        if (_sessions.length < _tongSoBuoi)
                          TextButton.icon(
                            onPressed: _addSession,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm buổi tập'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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
          '3buoi',
          'Khóa 3 Buổi/Tuần',
          'Tập 3 buổi mỗi tuần',
          Icons.calendar_today,
        ),
        const SizedBox(height: 8),
        _buildPackageOption(
          '5buoi',
          'Khóa 5 Buổi/Tuần',
          'Tập 5 buổi mỗi tuần',
          Icons.calendar_month,
        ),
        const SizedBox(height: 8),
        _buildPackageOption(
          '7buoi',
          'Khóa 7 Buổi/Tuần',
          'Tập hàng ngày',
          Icons.event_repeat,
        ),
      ],
    );
  }

  Widget _buildPackageOption(
    String value,
    String title,
    String desc,
    IconData icon,
  ) {
    final isSelected = _khoaTap == value;
    return InkWell(
      onTap: () => setState(() {
        _khoaTap = value;
        _sessions.clear(); // Clear sessions khi đổi khóa
      }),
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
              size: 28,
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
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: _soGioMoiBuoi > 1
              ? () => setState(() => _soGioMoiBuoi--)
              : null,
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
              '$_soGioMoiBuoi giờ/buổi',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          onPressed: _soGioMoiBuoi < 10
              ? () => setState(() => _soGioMoiBuoi++)
              : null,
          icon: const Icon(Icons.add_circle_outline),
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final tongTien = _calculateTotal();
    final numberFormat = NumberFormat('#,###');

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
    // Lấy giá từ trainer dựa trên trình độ
    final giaMoiGio = widget.trainer.giaMoiGio;

    // Tổng tiền = số buổi tập × số giờ mỗi buổi × giá mỗi giờ
    final tongSoGio = _tongSoBuoi * _soGioMoiBuoi;
    return giaMoiGio * tongSoGio;
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

    // Tính số buổi cần thiết dựa trên ngày đã chọn
    final weeks = _endDate!.difference(_startDate!).inDays / 7;
    final requiredSessions = (weeks * _soBuoiTrongTuan).ceil();

    if (_sessions.length < requiredSessions) {
      Get.snackbar(
        'Thiếu lịch tập',
        'Vui lòng lên lịch đủ $requiredSessions buổi tập',
      );
      return;
    }

    // Convert TrainingSession to TrainerSession
    final trainerSessions = _sessions.map((session) {
      final endTime = session.dateTime.add(
        Duration(hours: session.durationHours),
      );
      return TrainerSession(
        ngay: session.dateTime,
        gioBatDau: DateFormat('HH:mm').format(session.dateTime),
        gioKetThuc: DateFormat('HH:mm').format(endTime),
        diaDiem: 'Phòng tập', // Default location
        trangThai: 'scheduled',
        ghiChu: null,
      );
    }).toList();

    final success = await controller.createRental(
      trainer: widget.trainer,
      startDate: _startDate!,
      endDate: _endDate!,
      soGio: _tongSoBuoi * _soGioMoiBuoi, // Tổng số giờ
      goiTap: _khoaTap,
      ghiChu: _ghiChuController.text.trim().isEmpty
          ? null
          : _ghiChuController.text.trim(),
      sessions: trainerSessions,
    );

    if (success) {
      Get.back(); // Quay lại danh sách PT
      Get.toNamed('/my-trainer-rentals'); // Đi đến lịch sử
    }
  }

  // Thêm buổi tập mới
  void _addSession() async {
    final initialDateTime = _sessions.isEmpty
        ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 9, 0)
        : _sessions.last.dateTime.add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime.isBefore(_startDate!)
          ? _startDate!
          : (initialDateTime.isAfter(_endDate!) ? _endDate! : initialDateTime),
      firstDate: _startDate!,
      lastDate: _endDate!,
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime == null) return;

    final sessionDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _sessions.add(
        TrainingSession(
          dateTime: sessionDateTime,
          durationHours: _soGioMoiBuoi,
        ),
      );
      _sessions.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  // Widget hiển thị 1 buổi tập
  Widget _buildSessionCard(int index, TrainingSession session) {
    final dateFormat = DateFormat('EEE, dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(session.dateTime),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${timeFormat.format(session.dateTime)} - ${timeFormat.format(session.endTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${session.durationHours}h)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _sessions.removeAt(index));
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
