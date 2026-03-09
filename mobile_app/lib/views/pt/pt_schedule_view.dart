import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/trainer_rental.dart';
import '../../controllers/pt_controller.dart';
import '../../widgets/loading_overlay.dart';

/// Màn hình quản lý lịch tập của PT
class PTScheduleView extends StatefulWidget {
  const PTScheduleView({super.key});

  @override
  State<PTScheduleView> createState() => _PTScheduleViewState();
}

class _PTScheduleViewState extends State<PTScheduleView> {
  final _firestore = FirebaseFirestore.instance;
  final _controller = Get.find<PTController>();

  List<_ScheduleItem> _scheduleItems = [];
  bool _isLoading = false;
  String _filterStatus = 'all'; // all, scheduled, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    if (_controller.trainerProfile == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final trainerId = _controller.trainerProfile!.id;

      // Lấy tất cả đơn thuê đang active hoặc completed
      final rentalsSnapshot = await _firestore
          .collection('trainer_rentals')
          .where('trainerId', isEqualTo: trainerId)
          .where('trangThai', whereIn: ['active', 'completed', 'approved'])
          .get();

      final List<_ScheduleItem> items = [];

      for (final doc in rentalsSnapshot.docs) {
        final rental = TrainerRental.fromFirestore(doc);

        // Thêm từng session vào danh sách
        for (int i = 0; i < rental.sessions.length; i++) {
          final session = rental.sessions[i];
          items.add(
            _ScheduleItem(rental: rental, session: session, sessionIndex: i),
          );
        }
      }

      // Sắp xếp theo ngày
      items.sort((a, b) => a.session.ngay.compareTo(b.session.ngay));

      if (!mounted) return;
      setState(() {
        _scheduleItems = items;
      });
    } catch (e) {
      print('Error loading schedule: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải lịch tập: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<_ScheduleItem> get _filteredItems {
    if (_filterStatus == 'all') return _scheduleItems;

    // Lọc theo ngày
    if (_filterStatus == 'today') {
      final today = DateTime.now();
      return _scheduleItems.where((item) {
        final sessionDate = item.session.ngay;
        return sessionDate.year == today.year &&
            sessionDate.month == today.month &&
            sessionDate.day == today.day;
      }).toList();
    }

    if (_filterStatus == 'upcoming') {
      final today = DateTime.now();
      return _scheduleItems.where((item) {
        return item.session.ngay.isAfter(today) &&
            item.session.trangThai == 'scheduled';
      }).toList();
    }

    // Lọc theo trạng thái
    return _scheduleItems
        .where((item) => item.session.trangThai == _filterStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch tập'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedule,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                _buildStats(),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? _buildEmptyState()
                      : _buildScheduleList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    final today = DateTime.now();

    final todayCount = _scheduleItems.where((item) {
      final sessionDate = item.session.ngay;
      return sessionDate.year == today.year &&
          sessionDate.month == today.month &&
          sessionDate.day == today.day;
    }).length;

    final upcomingCount = _scheduleItems.where((item) {
      return item.session.ngay.isAfter(today) &&
          item.session.trangThai == 'scheduled';
    }).length;

    final scheduledCount = _scheduleItems
        .where((item) => item.session.trangThai == 'scheduled')
        .length;
    final completedCount = _scheduleItems
        .where((item) => item.session.trangThai == 'completed')
        .length;
    final cancelledCount = _scheduleItems
        .where((item) => item.session.trangThai == 'cancelled')
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Tất cả',
              'all',
              _scheduleItems.length,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Hôm nay',
              'today',
              todayCount,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Sắp tới',
              'upcoming',
              upcomingCount,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Đã lên lịch',
              'scheduled',
              scheduledCount,
              color: Colors.indigo,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Hoàn thành',
              'completed',
              completedCount,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Đã hủy',
              'cancelled',
              cancelledCount,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    int count, {
    Color? color,
  }) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : color?.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.white,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && mounted) {
          setState(() => _filterStatus = value);
        }
      },
      selectedColor: color?.withOpacity(0.2),
      checkmarkColor: color,
    );
  }

  Widget _buildStats() {
    final today = DateTime.now();
    final todaySessions = _scheduleItems.where((item) {
      final sessionDate = item.session.ngay;
      return sessionDate.year == today.year &&
          sessionDate.month == today.month &&
          sessionDate.day == today.day;
    }).length;

    final upcomingSessions = _scheduleItems.where((item) {
      return item.session.ngay.isAfter(today) &&
          item.session.trangThai == 'scheduled';
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(bottom: BorderSide(color: Colors.orange.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.today,
              'Hôm nay',
              todaySessions.toString(),
              Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.orange.shade200),
          Expanded(
            child: _buildStatItem(
              Icons.upcoming,
              'Sắp tới',
              upcomingSessions.toString(),
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return InkWell(
      onTap: () => _filterByDateType(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _filterByDateType(String type) {
    if (!mounted) return;

    setState(() {
      if (type == 'Hôm nay') {
        _filterStatus = 'today';
      } else if (type == 'Sắp tới') {
        _filterStatus = 'upcoming';
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có buổi tập nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Các buổi tập sẽ hiển thị sau khi lên lịch',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    // Nhóm theo ngày
    final Map<String, List<_ScheduleItem>> groupedByDate = {};

    for (final item in _filteredItems) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.session.ngay);
      groupedByDate.putIfAbsent(dateKey, () => []);
      groupedByDate[dateKey]!.add(item);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Mới nhất trên cùng

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final items = groupedByDate[dateKey]!;
        final date = items.first.session.ngay;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date),
            const SizedBox(height: 8),
            ...items.map((item) => _buildSessionCard(item)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final isToday = _isToday(date);
    final isTomorrow = _isTomorrow(date);

    String dateText;
    if (isToday) {
      dateText = 'Hôm nay';
    } else if (isTomorrow) {
      dateText = 'Ngày mai';
    } else {
      dateText = DateFormat('EEEE', 'vi').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isToday ? Colors.orange.shade100 : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: isToday ? Colors.orange.shade700 : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.orange.shade700 : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd/MM/yyyy').format(date),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(_ScheduleItem item) {
    final session = item.session;
    final rental = item.rental;
    final isCompleted = session.trangThai == 'completed';
    final isCancelled = session.trangThai == 'cancelled';

    Color statusColor;
    IconData statusIcon;

    if (isCancelled) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buổi ${item.sessionIndex + 1} - ${rental.userName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đơn #${rental.id.substring(0, 8)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(session.trangThai),
              ],
            ),
            const Divider(height: 24),

            // Thông tin chi tiết
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.access_time,
                        'Thời gian',
                        '${session.gioBatDau} - ${session.gioKetThuc}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on,
                        'Địa điểm',
                        session.diaDiem ?? 'Chưa xác định',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (session.ghiChu != null && session.ghiChu!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Ghi chú:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.ghiChu!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],

            // Nút hành động
            if (!isCompleted && !isCancelled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelSession(item),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy buổi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _completeSession(item),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Hoàn thành'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Hoàn thành';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.blue;
        text = 'Đã lên lịch';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  Future<void> _completeSession(_ScheduleItem item) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: Text(
          'Đánh dấu buổi ${item.sessionIndex + 1} với ${item.rental.userName} là hoàn thành?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    LoadingOverlay.show(context);

    try {
      // Cập nhật trạng thái session trong rental
      final updatedSessions = List<TrainerSession>.from(item.rental.sessions);
      updatedSessions[item.sessionIndex] = TrainerSession(
        ngay: item.session.ngay,
        gioBatDau: item.session.gioBatDau,
        gioKetThuc: item.session.gioKetThuc,
        diaDiem: item.session.diaDiem,
        trangThai: 'completed',
        ghiChu: item.session.ghiChu,
      );

      await _firestore
          .collection('trainer_rentals')
          .doc(item.rental.id)
          .update({
            'sessions': updatedSessions.map((s) => s.toMap()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) LoadingOverlay.hide(context);

      Get.snackbar(
        'Thành công',
        'Đã hoàn thành buổi tập',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _loadSchedule();
    } catch (e) {
      if (mounted) LoadingOverlay.hide(context);
      Get.snackbar(
        'Lỗi',
        'Không thể hoàn thành: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _cancelSession(_ScheduleItem item) async {
    final reasonController = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hủy buổi tập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hủy buổi ${item.sessionIndex + 1} với ${item.rental.userName}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy buổi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    LoadingOverlay.show(context);

    try {
      // Cập nhật trạng thái session
      final updatedSessions = List<TrainerSession>.from(item.rental.sessions);
      updatedSessions[item.sessionIndex] = TrainerSession(
        ngay: item.session.ngay,
        gioBatDau: item.session.gioBatDau,
        gioKetThuc: item.session.gioKetThuc,
        diaDiem: item.session.diaDiem,
        trangThai: 'cancelled',
        ghiChu: reasonController.text.isNotEmpty
            ? 'Đã hủy: ${reasonController.text}'
            : 'Đã hủy',
      );

      await _firestore
          .collection('trainer_rentals')
          .doc(item.rental.id)
          .update({
            'sessions': updatedSessions.map((s) => s.toMap()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) LoadingOverlay.hide(context);

      Get.snackbar(
        'Thành công',
        'Đã hủy buổi tập',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      _loadSchedule();
    } catch (e) {
      if (mounted) LoadingOverlay.hide(context);
      Get.snackbar(
        'Lỗi',
        'Không thể hủy: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// Helper class để nhóm rental và session
class _ScheduleItem {
  final TrainerRental rental;
  final TrainerSession session;
  final int sessionIndex;

  _ScheduleItem({
    required this.rental,
    required this.session,
    required this.sessionIndex,
  });
}
