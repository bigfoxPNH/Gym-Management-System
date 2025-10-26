import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/trainer.dart';
import '../../controllers/trainer_management_controller.dart';
import '../../widgets/loading_button.dart';

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
  DateTime? selectedBirthDate;
  List<String> selectedSpecialties = [];
  List<String> degrees = [];
  List<String> certifications = [];

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

            _buildListSection(
              title: 'Bằng cấp',
              items: degrees,
              onAdd: () => _addItem('Bằng cấp', degrees),
              onRemove: (index) => setState(() => degrees.removeAt(index)),
            ),
            const SizedBox(height: 16),

            _buildListSection(
              title: 'Chứng chỉ',
              items: certifications,
              onAdd: () => _addItem('Chứng chỉ', certifications),
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

  Widget _buildListSection({
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
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
              return ListTile(
                dense: true,
                leading: Icon(
                  title == 'Bằng cấp'
                      ? Icons.verified
                      : Icons.workspace_premium,
                  color: title == 'Bằng cấp' ? Colors.green : Colors.blue,
                  size: 20,
                ),
                title: Text(entry.value),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => onRemove(entry.key),
                ),
                contentPadding: EdgeInsets.zero,
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

  Future<void> _addItem(String title, List<String> list) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => list.add(result));
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
