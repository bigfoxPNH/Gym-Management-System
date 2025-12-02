import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const ExerciseCard({Key? key, required this.exercise, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: exercise.anhMinhHoa.isNotEmpty
                          ? _buildExerciseImage(exercise.anhMinhHoa.first)
                          : _buildPlaceholderImage(),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title and basic info
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Level chip
                        _buildLevelChip(exercise.doKho),

                        const SizedBox(height: 8),

                        // Muscle groups
                        if (exercise.cochinh.isNotEmpty)
                          Text(
                            'Cơ chính: ${exercise.cochinh.join(", ")}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Video indicator
                  if (exercise.videoMinhHoa != null &&
                      exercise.videoMinhHoa!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Exercise types
              if (exercise.loaiBaiTap.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: exercise.loaiBaiTap
                      .take(3)
                      .map(
                        (type) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 8),

              // Equipment
              if (exercise.dungCu.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        exercise.dungCu.join(', '),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Description preview
              if (exercise.moTa.isNotEmpty)
                Text(
                  exercise.moTa,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseImage(String imageUrl) {
    imageUrl = imageUrl.trim();

    // Check if it's a base64 data URL
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error decoding base64 image: $error');
            return _buildPlaceholderImage();
          },
        );
      } catch (e) {
        print('❌ Error parsing base64 image: $e');
        return _buildPlaceholderImage();
      }
    }

    // Regular network image
    return Image.network(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[100],
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Error loading network image: $error');
        return _buildPlaceholderImage();
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.fitness_center, color: Colors.grey[400], size: 30),
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
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
