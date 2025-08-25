import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/exercise_management_controller.dart';
import '../../models/exercise.dart';

class ExerciseManagementView extends StatelessWidget {
  const ExerciseManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExerciseManagementController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Bài Tập',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateExerciseDialog(context, controller),
            tooltip: 'Thêm bài tập mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Bar
          _buildStatisticsBar(controller),

          // Search and Filter Section
          _buildSearchAndFilterSection(controller),

          // Exercise List
          Expanded(child: _buildExerciseList(controller)),
        ],
      ),
    );
  }

  Widget _buildStatisticsBar(ExerciseManagementController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tổng số',
                controller.totalExercises.toString(),
                Icons.fitness_center,
                Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Cơ bản',
                controller.beginnerCount.toString(),
                Icons.star_border,
                Colors.green[100]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Trung cấp',
                controller.intermediateCount.toString(),
                Icons.star_half,
                Colors.orange[100]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Nâng cao',
                controller.advancedCount.toString(),
                Icons.star,
                Colors.red[100]!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(ExerciseManagementController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) => controller.searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bài tập...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _buildFilterChip(controller, 'all', 'Tất cả'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'beginner', 'Cơ bản'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'intermediate', 'Trung cấp'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'advanced', 'Nâng cao'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'compound', 'Compound'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'isolation', 'Isolation'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'push', 'Đẩy'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'pull', 'Kéo'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'cardio', 'Cardio'),
                  const SizedBox(width: 8),
                  _buildFilterChip(controller, 'strength', 'Sức mạnh'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ExerciseManagementController controller,
    String value,
    String label,
  ) {
    final isSelected = controller.selectedFilter.value == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        controller.selectedFilter.value = selected ? value : 'all';
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[600],
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildExerciseList(ExerciseManagementController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredExercises.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có bài tập nào',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhấn nút + để thêm bài tập đầu tiên',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredExercises.length,
        itemBuilder: (context, index) {
          final exercise = controller.filteredExercises[index];
          return _buildExerciseCard(context, exercise, controller);
        },
      );
    });
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    ExerciseManagementController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showExerciseDetailDialog(context, exercise),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.tenBaiTap,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildLevelChip(exercise.doKho),
                            const SizedBox(width: 8),
                            _buildMultiTypeChips(exercise.loaiBaiTap),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditExerciseDialog(
                            context,
                            controller,
                            exercise,
                          );
                          break;
                        case 'delete':
                          _showDeleteConfirmDialog(
                            context,
                            controller,
                            exercise,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Muscle Groups
              if (exercise.cochinh.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.accessibility_new,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhóm cơ: ${exercise.cochinh.join(', ')}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Equipment
              if (exercise.dungCu.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dụng cụ: ${exercise.dungCu.join(', ')}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Description preview
              if (exercise.moTa.isNotEmpty) ...[
                Text(
                  exercise.moTa.length > 100
                      ? '${exercise.moTa.substring(0, 100)}...'
                      : exercise.moTa,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
              ],

              // Video and Image indicators
              Row(
                children: [
                  if (exercise.videoMinhHoa != null &&
                      exercise.videoMinhHoa!.isNotEmpty) ...[
                    Icon(
                      Icons.play_circle_filled,
                      size: 16,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(fontSize: 12, color: Colors.red[600]),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (exercise.anhMinhHoa != null &&
                      exercise.anhMinhHoa!.isNotEmpty) ...[
                    Icon(Icons.image, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Hình ảnh',
                      style: TextStyle(fontSize: 12, color: Colors.green[600]),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(exercise.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(ExerciseLevel level) {
    Color color;
    switch (level) {
      case ExerciseLevel.beginner:
        color = Colors.green;
        break;
      case ExerciseLevel.intermediate:
        color = Colors.orange;
        break;
      case ExerciseLevel.advanced:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          fontSize: 12,
          color: Color.lerp(color, Colors.black, 0.3)!,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeChip(ExerciseType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMultiTypeChips(List<String> types) {
    if (types.isEmpty) return const Text('Không có');

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: types.map((type) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Text(
            type,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPositionChips(List<String> positions) {
    if (positions.isEmpty) return const Text('Không có');

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: positions.map((position) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Text(
            position,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCreateExerciseDialog(
    BuildContext context,
    ExerciseManagementController controller,
  ) {
    controller.clearForm();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(maxHeight: Get.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Thêm Bài Tập Mới',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Form content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildExerciseForm(controller, false),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.createExercise(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                          child: controller.isLoading.value
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
                              : const Text('Tạo Bài Tập'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showEditExerciseDialog(
    BuildContext context,
    ExerciseManagementController controller,
    Exercise exercise,
  ) {
    controller.loadExerciseForEdit(exercise);
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(maxHeight: Get.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[400]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Chỉnh Sửa Bài Tập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Form content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildExerciseForm(controller, true),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.updateExercise(exercise.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                          child: controller.isLoading.value
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
                              : const Text('Cập Nhật'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildExerciseForm(
    ExerciseManagementController controller,
    bool isEdit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise Name
        const Text(
          'Tên bài tập *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.tenBaiTapController,
          decoration: InputDecoration(
            hintText: 'Ví dụ: Hít đất cơ bản',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),

        // Primary Muscles
        const Text(
          'Nhóm cơ chính *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: controller.muscleGroups.map((muscle) {
              final isSelected = controller.selectedCochinh.contains(muscle);
              return FilterChip(
                label: Text(muscle),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.selectedCochinh.add(muscle);
                  } else {
                    controller.selectedCochinh.remove(muscle);
                  }
                },
                selectedColor: Colors.blue[100],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Secondary Muscles
        const Text(
          'Nhóm cơ phụ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: controller.muscleGroups.map((muscle) {
              final isSelected = controller.selectedCoPhu.contains(muscle);
              return FilterChip(
                label: Text(muscle),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.selectedCoPhu.add(muscle);
                  } else {
                    controller.selectedCoPhu.remove(muscle);
                  }
                },
                selectedColor: Colors.green[100],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Exercise Type
        const Text(
          'Loại bài tập *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Exercise.loaiBaiTapOptions.map((loai) {
              final isSelected = controller.selectedLoaiBaiTap.contains(loai);
              return FilterChip(
                label: Text(loai),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    if (!controller.selectedLoaiBaiTap.contains(loai)) {
                      controller.selectedLoaiBaiTap.add(loai);
                    }
                  } else {
                    controller.selectedLoaiBaiTap.remove(loai);
                  }
                },
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue.shade600,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Equipment
        const Text('Dụng cụ *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: controller.equipmentOptions.map((equipment) {
              final isSelected = controller.selectedDungCu.contains(equipment);
              return FilterChip(
                label: Text(equipment),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.selectedDungCu.add(equipment);
                  } else {
                    controller.selectedDungCu.remove(equipment);
                  }
                },
                selectedColor: Colors.purple[100],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Position
        const Text('Tư thế *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Exercise.tuTheOptions.map((tuThe) {
              final isSelected = controller.selectedTuThe.contains(tuThe);
              return FilterChip(
                label: Text(tuThe),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    if (!controller.selectedTuThe.contains(tuThe)) {
                      controller.selectedTuThe.add(tuThe);
                    }
                  } else {
                    controller.selectedTuThe.remove(tuThe);
                  }
                },
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade600,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Difficulty Level
        const Text('Độ khó *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<ExerciseLevel>(
            value: controller.selectedDoKho.value,
            onChanged: (value) => controller.selectedDoKho.value = value!,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: ExerciseLevel.values.map((level) {
              return DropdownMenuItem(value: level, child: Text(level.label));
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Goals
        const Text('Mục tiêu *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ExerciseGoal.values.map((goal) {
              final isSelected = controller.selectedMucTieu.contains(goal);
              return FilterChip(
                label: Text(goal.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.selectedMucTieu.add(goal);
                  } else {
                    controller.selectedMucTieu.remove(goal);
                  }
                },
                selectedColor: Colors.teal[100],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Description
        const Text(
          'Mô tả chi tiết *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.moTaController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText:
                'Mô tả cách thực hiện, lưu ý kỹ thuật, lỗi sai thường gặp...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),

        // Image URLs (tối đa 5 ảnh)
        const Text(
          'Hình ảnh minh họa (tối đa 5 ảnh)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildImageUrlsSection(controller),
        const SizedBox(height: 16),

        // Video URL
        const Text(
          'Link video minh họa',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.videoMinhHoaController,
          decoration: InputDecoration(
            hintText: 'https://youtube.com/watch?v=...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.video_library),
            helperText: 'Hỗ trợ YouTube, Vimeo',
            helperStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _showExerciseDetailDialog(BuildContext context, Exercise exercise) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(maxHeight: Get.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[400]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.tenBaiTap,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildExerciseDetailContent(exercise),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseDetailContent(Exercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Info
        Row(
          children: [
            _buildLevelChip(exercise.doKho),
            const SizedBox(width: 8),
            _buildMultiTypeChips(exercise.loaiBaiTap),
          ],
        ),
        const SizedBox(height: 16),

        // Muscle Groups
        if (exercise.cochinh.isNotEmpty) ...[
          _buildDetailSection(
            'Nhóm cơ chính',
            exercise.cochinh.join(', '),
            Icons.accessibility_new,
          ),
        ],

        if (exercise.coPhu.isNotEmpty) ...[
          _buildDetailSection(
            'Nhóm cơ phụ',
            exercise.coPhu.join(', '),
            Icons.accessibility_new_outlined,
          ),
        ],

        // Equipment and Position
        _buildDetailSection(
          'Dụng cụ',
          exercise.dungCu.join(', '),
          Icons.fitness_center,
        ),

        _buildDetailSection(
          'Tư thế',
          exercise.tuThe.join(', '),
          Icons.accessibility,
        ),

        // Goals
        if (exercise.mucTieu.isNotEmpty) ...[
          _buildDetailSection(
            'Mục tiêu',
            exercise.mucTieu.map((goal) => goal.label).join(', '),
            Icons.flag,
          ),
        ],

        // Description
        const Text(
          'Mô tả chi tiết',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            exercise.moTa,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),

        // Media
        if (exercise.videoMinhHoa != null &&
            exercise.videoMinhHoa!.isNotEmpty) ...[
          const Text(
            'Video minh họa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_filled,
                  color: Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.videoMinhHoa!,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (exercise.anhMinhHoa != null && exercise.anhMinhHoa!.isNotEmpty) ...[
          const Text(
            'Hình ảnh minh họa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.anhMinhHoa.isNotEmpty
                        ? exercise.anhMinhHoa.first
                        : 'Chưa có ảnh',
                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Created Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(exercise.createdAt)}',
                style: TextStyle(color: Colors.blue[700], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  content,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    ExerciseManagementController controller,
    Exercise exercise,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài tập "${exercise.tenBaiTap}"?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteExercise(exercise.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Method to build image URLs section
  Widget _buildImageUrlsSection(ExerciseManagementController controller) {
    return Obx(
      () => Column(
        children: [
          // Display existing image URLs
          ...controller.imageUrls.asMap().entries.map((entry) {
            int index = entry.key;
            String url = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  url.isNotEmpty ? url : 'Chưa có URL',
                  style: TextStyle(
                    fontSize: 14,
                    color: url.isNotEmpty ? Colors.black87 : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () =>
                          _showEditImageUrlDialog(controller, index),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => controller.removeImageUrl(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          // Add new image button (if less than 5 images)
          if (controller.imageUrls.length < 5)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => controller.addImageUrl(),
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('Thêm ảnh (${controller.imageUrls.length}/5)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Dialog to edit image URL
  void _showEditImageUrlDialog(
    ExerciseManagementController controller,
    int index,
  ) {
    final urlController = TextEditingController(
      text: controller.imageUrls[index],
    );

    Get.dialog(
      AlertDialog(
        title: Text('Chỉnh sửa ảnh ${index + 1}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'URL hình ảnh',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.image),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            // Preview image if URL is valid
            if (urlController.text.isNotEmpty)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    urlController.text,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              controller.updateImageUrl(index, urlController.text.trim());
              Get.back();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
