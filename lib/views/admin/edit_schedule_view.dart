import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gympro/controllers/schedule_management_controller.dart';
import 'package:gympro/models/workout_schedule.dart';

class EditScheduleView extends StatelessWidget {
  final WorkoutSchedule schedule;

  const EditScheduleView({Key? key, required this.schedule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScheduleManagementController>();

    // Load schedule data for editing
    controller.loadScheduleForEdit(schedule);

    final titleController = TextEditingController(text: schedule.title);
    final descriptionController = TextEditingController(
      text: schedule.description,
    );
    final imageUrlController = TextEditingController(
      text: schedule.imageUrl ?? '',
    );
    final tagController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa lịch trình'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(controller, titleController, descriptionController),
            const SizedBox(height: 24),
            _buildCategoryAndDifficulty(controller),
            const SizedBox(height: 24),
            _buildDurationSettings(controller),
            const SizedBox(height: 24),
            _buildExerciseSelection(controller),
            const SizedBox(height: 24),
            _buildImageAndTags(controller, imageUrlController, tagController),
            const SizedBox(height: 32),
            _buildUpdateButton(
              controller,
              titleController,
              descriptionController,
              imageUrlController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(
    ScheduleManagementController controller,
    TextEditingController titleController,
    TextEditingController descriptionController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin cơ bản',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Tên lịch trình *',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => controller.titleController.value = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Mô tả *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => controller.descriptionController.value = value,
        ),
      ],
    );
  }

  Widget _buildCategoryAndDifficulty(ScheduleManagementController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phân loại',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<ScheduleCategory>(
                  value: controller.selectedCategoryForm.value,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: ScheduleCategory.values
                      .map(
                        (category) => DropdownMenuItem<ScheduleCategory>(
                          value: category,
                          child: Text(_getCategoryText(category)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedCategoryForm.value = value;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<DifficultyLevel>(
                  value: controller.selectedDifficultyForm.value,
                  decoration: const InputDecoration(
                    labelText: 'Độ khó',
                    border: OutlineInputBorder(),
                  ),
                  items: DifficultyLevel.values
                      .map(
                        (difficulty) => DropdownMenuItem<DifficultyLevel>(
                          value: difficulty,
                          child: Text(_getDifficultyText(difficulty)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedDifficultyForm.value = value;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSettings(ScheduleManagementController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thời lượng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => TextFormField(
                  initialValue: controller.durationWeeks.value.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Số tuần',
                    border: OutlineInputBorder(),
                    suffix: Text('tuần'),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final weeks = int.tryParse(value) ?? 4;
                    controller.durationWeeks.value = weeks;
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(
                () => TextFormField(
                  initialValue: controller.sessionsPerWeek.value.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Buổi/tuần',
                    border: OutlineInputBorder(),
                    suffix: Text('buổi'),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final sessions = int.tryParse(value) ?? 3;
                    controller.sessionsPerWeek.value = sessions;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseSelection(ScheduleManagementController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Chọn bài tập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Obx(
              () => Text(
                controller.selectedExercisesText,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.exercises.isEmpty) {
            return const Center(child: Text('Đang tải danh sách bài tập...'));
          }

          return Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: controller.availableExercises.length,
              itemBuilder: (context, index) {
                final exercise = controller.availableExercises[index];
                return Obx(
                  () => CheckboxListTile(
                    title: Text(exercise.tenBaiTap),
                    subtitle: Text(
                      exercise.moTa.isNotEmpty
                          ? exercise.moTa
                          : 'Không có mô tả',
                    ),
                    value: controller.isExerciseSelected(exercise.id),
                    onChanged: (bool? value) {
                      controller.toggleExerciseSelection(exercise.id);
                    },
                    secondary: exercise.anhMinhHoa.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(
                              exercise.anhMinhHoa.first,
                            ),
                          )
                        : const CircleAvatar(child: Icon(Icons.fitness_center)),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImageAndTags(
    ScheduleManagementController controller,
    TextEditingController imageUrlController,
    TextEditingController tagController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bổ sung',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: imageUrlController,
          decoration: const InputDecoration(
            labelText: 'URL hình ảnh',
            border: OutlineInputBorder(),
            hintText: 'https://example.com/image.jpg',
          ),
          onChanged: (value) => controller.imageUrl.value = value,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: tagController,
                decoration: const InputDecoration(
                  labelText: 'Tag',
                  border: OutlineInputBorder(),
                  hintText: 'Nhập tag và nhấn thêm',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (tagController.text.isNotEmpty) {
                  controller.addTag(tagController.text);
                  tagController.clear();
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: controller.tags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => controller.removeTag(tag),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton(
    ScheduleManagementController controller,
    TextEditingController titleController,
    TextEditingController descriptionController,
    TextEditingController imageUrlController,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Obx(
        () => ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  final updatedSchedule = schedule.copyWith(
                    title: controller.titleController.value,
                    description: controller.descriptionController.value,
                    category: controller.selectedCategoryForm.value,
                    difficulty: controller.selectedDifficultyForm.value,
                    exerciseIds: controller.selectedExerciseIds.toList(),
                    durationWeeks: controller.durationWeeks.value,
                    sessionsPerWeek: controller.sessionsPerWeek.value,
                    imageUrl: controller.imageUrl.value.isEmpty
                        ? null
                        : controller.imageUrl.value,
                    tags: controller.tags.toList(),
                    updatedAt: DateTime.now(),
                  );

                  await controller.updateSchedule(updatedSchedule);
                  if (!controller.isLoading.value) {
                    Get.back();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Cập nhật lịch trình',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ),
    );
  }

  String _getCategoryText(ScheduleCategory category) {
    switch (category) {
      case ScheduleCategory.weightLoss:
        return 'Giảm cân';
      case ScheduleCategory.muscleGain:
        return 'Tăng cơ';
      case ScheduleCategory.strength:
        return 'Sức mạnh';
      case ScheduleCategory.cardio:
        return 'Tim mạch';
      case ScheduleCategory.flexibility:
        return 'Linh hoạt';
      case ScheduleCategory.general:
        return 'Tổng hợp';
    }
  }

  String _getDifficultyText(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Cơ bản';
      case DifficultyLevel.intermediate:
        return 'Trung bình';
      case DifficultyLevel.advanced:
        return 'Nâng cao';
    }
  }
}
