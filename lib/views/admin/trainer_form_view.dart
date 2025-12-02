import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/trainer.dart';
import '../../models/certificate.dart';
import '../../controllers/trainer_management_controller.dart';
import '../../widgets/loading_button.dart';
import '../../services/image_base64_service.dart';

/// Form thêm/sửa PT đầy đủ
class TrainerFormView extends StatefulWidget {
  final Trainer? trainer;

  const TrainerFormView({super.key, this.trainer});

  @override
  State<TrainerFormView> createState() => _TrainerFormViewState();
}

class _TrainerFormViewState extends State<TrainerFormView> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<TrainerManagementController>();

  // Controllers
  late TextEditingController hoTenController;
  late TextEditingController emailController;
  late TextEditingController dienThoaiController;
  late TextEditingController diaChiController;
  late TextEditingController luongController;
  late TextEditingController hoaHongController;

  // State
  String selectedGender = 'male';
  String selectedStatus = 'active';
  String selectedTrinhDo = 'moi'; // Trình độ PT
  int namKinhNghiem = 0; // Số năm kinh nghiệm
  DateTime? selectedBirthDate;
  List<String> selectedSpecialties = [];
  List<Certificate> degrees = []; // Đổi sang Certificate
  List<Certificate> certifications = []; // Đổi sang Certificate

  // Available options
  final List<String> availableSpecialties = [
    'Yoga',
    'Boxing',
    'Cardio',
    'Tăng cơ',
    'Giảm cân',
    'Pilates',
    'CrossFit',
    'Zumba',
    'Spinning',
    'HIIT',
  ];

  @override
  void initState() {
    super.initState();
    final trainer = widget.trainer;

    hoTenController = TextEditingController(text: trainer?.hoTen);
    emailController = TextEditingController(text: trainer?.email);
    dienThoaiController = TextEditingController(text: trainer?.soDienThoai);
    diaChiController = TextEditingController(text: trainer?.diaChi);
    luongController = TextEditingController(
      text: trainer?.mucLuongCoBan.toString() ?? '10000000',
    );
    hoaHongController = TextEditingController(
      text: trainer?.hoaHongPhanTram.toString() ?? '10',
    );

    if (trainer != null) {
      selectedGender = trainer.gioiTinh ?? 'male';
      selectedStatus = trainer.trangThai;
      selectedTrinhDo = trainer.trinhDoPT;
      namKinhNghiem = trainer.namKinhNghiem;
      selectedBirthDate = trainer.namSinh;
      selectedSpecialties = List.from(trainer.chuyenMon);
      degrees = List.from(trainer.bangCap);
      certifications = List.from(trainer.chungChi);
    }
  }

  @override
  void dispose() {
    hoTenController.dispose();
    emailController.dispose();
    dienThoaiController.dispose();
    diaChiController.dispose();
    luongController.dispose();
    hoaHongController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.trainer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa thông tin PT' : 'Thêm PT mới'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section: Thông tin cơ bản
            _buildSectionTitle('Thông tin cơ bản', Icons.person),
            const SizedBox(height: 12),

            TextFormField(
              controller: hoTenController,
              decoration: const InputDecoration(
                labelText: 'Họ tên PT *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: dienThoaiController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!GetUtils.isEmail(value)) {
                    return 'Email không hợp lệ';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: const InputDecoration(
                labelText: 'Giới tính',
                prefixIcon: Icon(Icons.wc),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Nam')),
                DropdownMenuItem(value: 'female', child: Text('Nữ')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => selectedGender = value);
              },
            ),
            const SizedBox(height: 16),

            // Birth date
            InkWell(
              onTap: _selectBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  selectedBirthDate != null
                      ? DateFormat('dd/MM/yyyy').format(selectedBirthDate!)
                      : 'Chọn ngày sinh',
                  style: TextStyle(
                    color: selectedBirthDate != null
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: diaChiController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Trình độ PT
            _buildSectionTitle(
              'Trình độ & Kinh nghiệm',
              Icons.workspace_premium,
            ),
            const SizedBox(height: 12),

            // Trình độ PT dropdown
            DropdownButtonFormField<String>(
              value: selectedTrinhDo,
              decoration: const InputDecoration(
                labelText: 'Trình độ PT',
                labelStyle: TextStyle(fontSize: 13),
                prefixIcon: Icon(Icons.military_tech, size: 20),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'moi',
                  child: Text('Mới (100k/giờ)', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'trung_cap',
                  child: Text(
                    'Trung cấp (150k/giờ)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'chuyen_nghiep',
                  child: Text(
                    'Chuyên nghiệp (200k/giờ)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'ifbb_pro',
                  child: Text(
                    'IFBB Pro (300k/giờ)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedTrinhDo = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Số năm kinh nghiệm
            Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Số năm KN:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  onPressed: namKinhNghiem > 0
                      ? () => setState(() => namKinhNghiem--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 28),
                  color: Colors.orange,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$namKinhNghiem năm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: namKinhNghiem < 50
                      ? () => setState(() => namKinhNghiem++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline, size: 28),
                  color: Colors.orange,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Chuyên môn
            _buildSectionTitle('Chuyên môn', Icons.fitness_center),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn chuyên môn:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSpecialties.map((specialty) {
                      final isSelected = selectedSpecialties.contains(
                        specialty,
                      );
                      return FilterChip(
                        label: Text(specialty),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedSpecialties.add(specialty);
                            } else {
                              selectedSpecialties.remove(specialty);
                            }
                          });
                        },
                        selectedColor: const Color(0xFFFF9800).withOpacity(0.3),
                        checkmarkColor: const Color(0xFFFF9800),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Bằng cấp & Chứng chỉ
            _buildSectionTitle('Bằng cấp & Chứng chỉ', Icons.school),
            const SizedBox(height: 12),

            _buildCertificateSection(
              title: 'Bằng cấp',
              items: degrees,
              onAdd: () => _addCertificate('Bằng cấp', degrees),
              onEdit: (index) => _editCertificate('Bằng cấp', degrees, index),
              onRemove: (index) => setState(() => degrees.removeAt(index)),
            ),
            const SizedBox(height: 16),

            _buildCertificateSection(
              title: 'Chứng chỉ',
              items: certifications,
              onAdd: () => _addCertificate('Chứng chỉ', certifications),
              onEdit: (index) =>
                  _editCertificate('Chứng chỉ', certifications, index),
              onRemove: (index) =>
                  setState(() => certifications.removeAt(index)),
            ),
            const SizedBox(height: 24),

            // Section: Lương & Trạng thái
            _buildSectionTitle('Lương & Trạng thái', Icons.attach_money),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: luongController,
                    decoration: const InputDecoration(
                      labelText: 'Lương cơ bản (VNĐ)',
                      prefixIcon: Icon(Icons.money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nhập lương';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: hoaHongController,
                    decoration: const InputDecoration(
                      labelText: 'Hoa hồng (%)',
                      prefixIcon: Icon(Icons.trending_up),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nhập %';
                      }
                      final percent = int.tryParse(value);
                      if (percent == null || percent < 0 || percent > 100) {
                        return '0-100';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                prefixIcon: Icon(Icons.info),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Đang làm việc')),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Text('Không hoạt động'),
                ),
                DropdownMenuItem(value: 'suspended', child: Text('Tạm ngưng')),
                DropdownMenuItem(value: 'on_leave', child: Text('Nghỉ phép')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => selectedStatus = value);
              },
            ),
            const SizedBox(height: 24),

            // Submit button
            Obx(
              () => LoadingButton(
                text: isEdit ? 'Cập nhật' : 'Thêm PT',
                onPressed: _handleSubmit,
                isLoading: controller.isLoading.value,
                backgroundColor: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF9800)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCertificateSection({
    required String title,
    required List<Certificate> items,
    required VoidCallback onAdd,
    required void Function(int) onEdit,
    required void Function(int) onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFFFF9800)),
                onPressed: onAdd,
                tooltip: 'Thêm $title',
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Chưa có $title nào',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final cert = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: cert.anhUrl != null && cert.anhUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: cert.anhUrl!.startsWith('data:image')
                              ? Image.memory(
                                  Uri.parse(
                                    cert.anhUrl!,
                                  ).data!.contentAsBytes(),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                                )
                              : Image.network(
                                  cert.anhUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                                ),
                        )
                      : Icon(
                          title == 'Bằng cấp'
                              ? Icons.verified
                              : Icons.workspace_premium,
                          color: title == 'Bằng cấp'
                              ? Colors.green
                              : Colors.blue,
                          size: 40,
                        ),
                  title: Text(cert.ten),
                  subtitle: cert.moTa != null && cert.moTa!.isNotEmpty
                      ? Text(
                          cert.moTa!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => onEdit(entry.key),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => onRemove(entry.key),
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF9800)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedBirthDate = picked);
    }
  }

  Future<void> _addCertificate(String title, List<Certificate> list) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    String? uploadedImageUrl;
    bool isUploading = false;

    final result = await showDialog<Certificate>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Thêm $title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên $title *',
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Image options
                const Text(
                  'Tải ảnh chứng chỉ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Upload from device button
                OutlinedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          setState(() => isUploading = true);
                          try {
                            final base64Image =
                                await ImageBase64Service.pickAndConvertImage();
                            if (base64Image != null) {
                              setState(() {
                                uploadedImageUrl = base64Image;
                              });
                            }
                          } finally {
                            setState(() => isUploading = false);
                          }
                        },
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    isUploading ? 'Đang xử lý...' : 'Chọn ảnh từ thiết bị',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),

                if (uploadedImageUrl != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Đã chọn ảnh')),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () =>
                              setState(() => uploadedImageUrl = null),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDate != null
                        ? 'Ngày cấp: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Chọn ngày cấp (tùy chọn)',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên')),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  Certificate(
                    ten: name,
                    moTa: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    anhUrl: uploadedImageUrl,
                    ngayCap: selectedDate,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => list.add(result));
    }
  }

  Future<void> _editCertificate(
    String title,
    List<Certificate> list,
    int index,
  ) async {
    final cert = list[index];
    final nameController = TextEditingController(text: cert.ten);
    final descController = TextEditingController(text: cert.moTa ?? '');
    DateTime? selectedDate = cert.ngayCap;
    String? uploadedImageUrl;
    bool isUploading = false;

    final result = await showDialog<Certificate>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Chỉnh sửa $title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên $title *',
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Image options
                const Text(
                  'Ảnh chứng chỉ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Upload from device button
                OutlinedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          setState(() => isUploading = true);
                          try {
                            final base64Image =
                                await ImageBase64Service.pickAndConvertImage();
                            if (base64Image != null) {
                              setState(() {
                                uploadedImageUrl = base64Image;
                              });
                            }
                          } finally {
                            setState(() => isUploading = false);
                          }
                        },
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    isUploading ? 'Đang xử lý...' : 'Chọn ảnh mới từ thiết bị',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),

                if (uploadedImageUrl != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Đã chọn ảnh mới')),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () =>
                              setState(() => uploadedImageUrl = null),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDate != null
                        ? 'Ngày cấp: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Chọn ngày cấp (tùy chọn)',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên')),
                  );
                  return;
                }

                // Use uploaded image or keep original
                final finalImageUrl = uploadedImageUrl ?? cert.anhUrl;

                Navigator.pop(
                  context,
                  Certificate(
                    ten: name,
                    moTa: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    anhUrl: finalImageUrl,
                    ngayCap: selectedDate,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => list[index] = result);
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedSpecialties.isEmpty) {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng chọn ít nhất 1 chuyên môn',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final trainer = Trainer(
      id: widget.trainer?.id ?? '',
      userId: widget.trainer?.userId, // CRITICAL: Preserve userId when editing
      hoTen: hoTenController.text.trim(),
      email: emailController.text.trim().isEmpty
          ? null
          : emailController.text.trim(),
      soDienThoai: dienThoaiController.text.trim(),
      gioiTinh: selectedGender,
      namSinh: selectedBirthDate,
      diaChi: diaChiController.text.trim().isEmpty
          ? null
          : diaChiController.text.trim(),
      chuyenMon: selectedSpecialties,
      bangCap: degrees,
      chungChi: certifications,
      namKinhNghiem: namKinhNghiem,
      trinhDoPT: selectedTrinhDo,
      trangThai: selectedStatus,
      mucLuongCoBan: double.tryParse(luongController.text) ?? 10000000,
      hoaHongPhanTram: (int.tryParse(hoaHongController.text) ?? 10).toDouble(),
      danhGiaTrungBinh: widget.trainer?.danhGiaTrungBinh ?? 0,
      soLuotDanhGia: widget.trainer?.soLuotDanhGia ?? 0,
      anhDaiDien: widget.trainer?.anhDaiDien,
      ngayVaoLam: widget.trainer?.ngayVaoLam ?? DateTime.now(),
      createdAt: widget.trainer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: widget.trainer?.createdBy ?? 'admin',
    );

    if (widget.trainer != null) {
      controller.updateTrainer(trainer);
    } else {
      controller.addTrainer(trainer);
    }
  }
}
