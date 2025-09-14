import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/workout_assistant_controller.dart';
import 'web_camera_view.dart';
import 'workout_camera_view_web.dart';

class WorkoutAssistantView extends StatelessWidget {
  const WorkoutAssistantView({super.key});

  // Define 10 specific exercises
  static const List<Map<String, dynamic>> exercises = [
    {
      'id': 'squat',
      'name': 'Squat',
      'icon': Icons.airline_seat_legroom_normal,
      'difficulty': 'Trung bình',
      'color': Colors.orange,
      'description': 'Bài tập cơ đùi và mông hiệu quả',
      'targetMuscles': ['Đùi', 'Mông', 'Lưng dưới'],
    },
    {
      'id': 'pushup',
      'name': 'Push-up',
      'icon': Icons.fitness_center,
      'difficulty': 'Trung bình',
      'color': Colors.blue,
      'description': 'Bài tập cơ ngực và cánh tay',
      'targetMuscles': ['Ngực', 'Cánh tay', 'Vai'],
    },
    {
      'id': 'plank',
      'name': 'Plank',
      'icon': Icons.horizontal_rule,
      'difficulty': 'Dễ',
      'color': Colors.green,
      'description': 'Bài tập cơ bụng và core',
      'targetMuscles': ['Bụng', 'Lưng', 'Vai'],
    },
    {
      'id': 'lunge',
      'name': 'Lunge',
      'icon': Icons.directions_walk,
      'difficulty': 'Trung bình',
      'color': Colors.orange,
      'description': 'Bài tập cơ đùi một chân',
      'targetMuscles': ['Đùi', 'Mông', 'Bắp chân'],
    },
    {
      'id': 'burpee',
      'name': 'Burpee',
      'icon': Icons.sports_gymnastics,
      'difficulty': 'Khó',
      'color': Colors.red,
      'description': 'Bài tập toàn thân cường độ cao',
      'targetMuscles': ['Toàn thân', 'Tim mạch'],
    },
    {
      'id': 'mountain_climbers',
      'name': 'Mountain Climbers',
      'icon': Icons.terrain,
      'difficulty': 'Trung bình',
      'color': Colors.orange,
      'description': 'Bài tập cardio và cơ bụng',
      'targetMuscles': ['Bụng', 'Vai', 'Tim mạch'],
    },
    {
      'id': 'jumping_jacks',
      'name': 'Jumping Jacks',
      'icon': Icons.directions_run,
      'difficulty': 'Dễ',
      'color': Colors.green,
      'description': 'Bài tập cardio cơ bản',
      'targetMuscles': ['Tim mạch', 'Chân', 'Tay'],
    },
    {
      'id': 'situp',
      'name': 'Sit-up / Crunches',
      'icon': Icons.self_improvement,
      'difficulty': 'Dễ',
      'color': Colors.green,
      'description': 'Bài tập cơ bụng cổ điển',
      'targetMuscles': ['Bụng trên', 'Bụng dưới'],
    },
    {
      'id': 'deadlift',
      'name': 'Deadlift',
      'icon': Icons.fitness_center,
      'difficulty': 'Khó',
      'color': Colors.red,
      'description': 'Bài tập nâng tạ toàn thân',
      'targetMuscles': ['Lưng', 'Đùi', 'Mông'],
    },
    {
      'id': 'shoulder_press',
      'name': 'Shoulder Press',
      'icon': Icons.sports_handball,
      'difficulty': 'Trung bình',
      'color': Colors.orange,
      'description': 'Bài tập cơ vai và tay',
      'targetMuscles': ['Vai', 'Tay', 'Lưng trên'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WorkoutAssistantController());
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 800 ? 4 : (screenWidth > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Trợ Lý Tập Thông Minh'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.fitness_center, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Chào mừng đến với AI Fitness!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Chọn Bài Tập',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 16),

            // Exercise Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];

                return Obx(() {
                  final isSelected =
                      controller.selectedExerciseId.value == exercise['id'];

                  return GestureDetector(
                    onTap: () =>
                        controller.selectExerciseById(exercise['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF1976D2).withOpacity(0.3)
                                : Colors.grey.withOpacity(0.1),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Exercise Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : const Color(0xFF1976D2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                exercise['icon'] as IconData,
                                size: 28,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1976D2),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Exercise Name
                            Text(
                              exercise['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 6),

                            // Difficulty Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: exercise['color'] as Color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                exercise['difficulty'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
              },
            ),

            const SizedBox(height: 24),

            // Selected Exercise Info
            Obx(() {
              final selectedId = controller.selectedExerciseId.value;
              if (selectedId.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chọn một bài tập để bắt đầu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy chọn bài tập phù hợp với mục tiêu của bạn',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final selectedExercise = exercises.firstWhere(
                (e) => e['id'] == selectedId,
              );
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4CAF50),
                      Color(0xFF388E3C),
                      Color(0xFF2E7D32),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedExercise['icon'] as IconData,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedExercise['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      selectedExercise['description'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Target Muscles
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          (selectedExercise['targetMuscles'] as List<String>)
                              .map(
                                (muscle) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    muscle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Start Workout Button
            Obx(() {
              final isExerciseSelected =
                  controller.selectedExerciseId.value.isNotEmpty;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isExerciseSelected
                      ? () => _showCameraOptions(context)
                      : null,
                  icon: Icon(
                    isExerciseSelected ? Icons.play_arrow : Icons.block,
                  ),
                  label: Text(
                    isExerciseSelected
                        ? 'Bắt đầu tập luyện với AI'
                        : 'Chọn bài tập để bắt đầu',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExerciseSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  void _showCameraOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn Camera',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera Web'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const WebCameraView());
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera Tích Hợp'),
              onTap: () {
                Navigator.pop(context);
                if (kIsWeb) {
                  Get.to(() => const WorkoutCameraViewWeb());
                } else {
                  Get.snackbar('Thông báo', 'Tính năng đang phát triển');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
