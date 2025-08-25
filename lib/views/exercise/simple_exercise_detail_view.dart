import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/exercise.dart';

class SimpleExerciseDetailView extends StatelessWidget {
  final Exercise exercise;

  const SimpleExerciseDetailView({Key? key, required this.exercise})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                  ),
                ),
                child: exercise.anhMinhHoa.isNotEmpty
                    ? Image.network(
                        exercise
                            .anhMinhHoa
                            .first, // Lấy ảnh đầu tiên làm header
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            actions: [
              if (exercise.videoMinhHoa != null &&
                  exercise.videoMinhHoa!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: () =>
                        _launchVideo(exercise.videoMinhHoa!, context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Level
                  Text(
                    exercise.tenBaiTap,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _buildLevelChip(exercise.doKho.label),
                      const SizedBox(width: 12),
                      if (exercise.videoMinhHoa != null &&
                          exercise.videoMinhHoa!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam,
                                size: 14,
                                color: Colors.red.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Video hướng dẫn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (exercise.moTa.isNotEmpty) ...[
                    _buildSectionHeader('Mô tả chi tiết', Icons.description),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        exercise.moTa,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Exercise Types
                  if (exercise.loaiBaiTap.isNotEmpty) ...[
                    _buildSectionHeader('Loại bài tập', Icons.category),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.loaiBaiTap
                          .map((type) => _buildTypeChip(type))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Muscle Groups
                  if (exercise.cochinh.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Nhóm cơ chính',
                      Icons.accessibility_new,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.cochinh
                          .map((muscle) => _buildMuscleChip(muscle))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Secondary Muscles
                  if (exercise.coPhu.isNotEmpty) ...[
                    _buildSectionHeader('Nhóm cơ phụ', Icons.accessibility),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.coPhu
                          .map((muscle) => _buildMuscleChip(muscle))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Equipment
                  if (exercise.dungCu.isNotEmpty) ...[
                    _buildSectionHeader('Dụng cụ', Icons.fitness_center),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.dungCu
                          .map((equipment) => _buildEquipmentChip(equipment))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Positions
                  if (exercise.tuThe.isNotEmpty) ...[
                    _buildSectionHeader('Tư thế', Icons.self_improvement),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.tuThe
                          .map((position) => _buildPositionChip(position))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Goals
                  if (exercise.mucTieu.isNotEmpty) ...[
                    _buildSectionHeader('Mục tiêu', Icons.flag),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercise.mucTieu
                          .map((goal) => _buildGoalChip(goal.label))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Video Section
                  if (exercise.videoMinhHoa != null &&
                      exercise.videoMinhHoa!.isNotEmpty) ...[
                    _buildSectionHeader('Video hướng dẫn', Icons.play_circle),
                    const SizedBox(height: 12),

                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildVideoThumbnail(context),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Video actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVideoAction(
                          icon: Icons.play_arrow,
                          label: 'Xem video',
                          onTap: () =>
                              _launchVideo(exercise.videoMinhHoa!, context),
                        ),
                        _buildVideoAction(
                          icon: Icons.open_in_new,
                          label: 'Mở YouTube',
                          onTap: () =>
                              _launchVideo(exercise.videoMinhHoa!, context),
                        ),
                        _buildVideoAction(
                          icon: Icons.share,
                          label: 'Chia sẻ',
                          onTap: () =>
                              _shareVideo(exercise.videoMinhHoa!, context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],

                  // Image Gallery Section
                  if (exercise.anhMinhHoa.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Hình ảnh minh họa',
                      Icons.photo_library,
                    ),
                    const SizedBox(height: 12),
                    _buildImageGallery(context),
                    const SizedBox(height: 24),
                  ],

                  // Instructions - Skip for now

                  // Tips - Skip for now
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.fitness_center, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChip(String level) {
    MaterialColor color;
    switch (level.toLowerCase()) {
      case 'dễ':
      case 'beginner':
        color = Colors.green;
        break;
      case 'trung bình':
      case 'intermediate':
        color = Colors.orange;
        break;
      case 'khó':
      case 'advanced':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 14, color: color[700]),
          const SizedBox(width: 4),
          Text(
            level,
            style: TextStyle(
              fontSize: 12,
              color: color[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        type,
        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
      ),
    );
  }

  Widget _buildMuscleChip(String muscle, {bool isPrimary = true}) {
    final color = isPrimary ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        muscle,
        style: TextStyle(fontSize: 12, color: color.shade700),
      ),
    );
  }

  Widget _buildPositionChip(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Text(
        position,
        style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
      ),
    );
  }

  Widget _buildGoalChip(String goal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Text(
        goal,
        style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
      ),
    );
  }

  Widget _buildEquipmentChip(String equipment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Text(
        equipment,
        style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
      ),
    );
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    String? videoId;
    if (exercise.videoMinhHoa != null) {
      // Extract video ID from YouTube URL
      final url = exercise.videoMinhHoa!;
      final regExp = RegExp(
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)',
      );
      final match = regExp.firstMatch(url);
      if (match != null) {
        videoId = match.group(1);
      }
    }

    return GestureDetector(
      onTap: () => _launchVideo(exercise.videoMinhHoa!, context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.black12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (videoId != null)
              Image.network(
                'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.video_library,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.video_library,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.red),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    // Sử dụng danh sách ảnh thực từ exercise
    List<String> imageUrls = exercise.anhMinhHoa;

    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(
              right: index == imageUrls.length - 1 ? 0 : 12,
            ),
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _showImageDialog(context, imageUrls[index]),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Badge hiển thị số thứ tự ảnh
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${index + 1}/${imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareVideo(String videoUrl, BuildContext context) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Video URL: $videoUrl')));
  }

  Future<void> _launchVideo(String url, BuildContext context) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể mở video: $e')));
    }
  }
}
