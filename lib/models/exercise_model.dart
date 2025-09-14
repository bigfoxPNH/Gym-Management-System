class Exercise {
  final String id;
  final String name;
  final String description;
  final String instructions;
  final String animationPath;
  final List<String> commonMistakes;
  final List<String> safetyTips;
  final String difficulty;
  final int duration; // in seconds
  final String targetMuscles;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.animationPath,
    required this.commonMistakes,
    required this.safetyTips,
    required this.difficulty,
    required this.duration,
    required this.targetMuscles,
  });
}

enum FeedbackType { correct, warning, danger, incorrect, guidance }

class WorkoutFeedback {
  final String message;
  final FeedbackType type;
  final DateTime timestamp;

  WorkoutFeedback({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

class ExerciseData {
  static List<Exercise> getAllExercises() {
    return [
      Exercise(
        id: 'squat',
        name: 'Squat',
        description: 'Bài tập squat giúp tăng cường cơ đùi và mông',
        instructions:
            'Đứng thẳng, chân rộng bằng vai, từ từ ngồi xuống như ngồi ghế',
        animationPath: 'assets/animations/squat.json',
        commonMistakes: [
          'Đầu gối vượt quá mũi chân',
          'Lưng cong quá mức',
          'Không ngồi đủ sâu',
        ],
        safetyTips: [
          'Giữ lưng thẳng',
          'Đầu gối hướng ra ngoài',
          'Trọng lượng ở gót chân',
        ],
        difficulty: 'Trung bình',
        duration: 60,
        targetMuscles: 'Đùi, Mông, Core',
      ),
      Exercise(
        id: 'pushup',
        name: 'Push-up',
        description: 'Bài tập hít đất tăng cường cơ ngực, vai và tay',
        instructions: 'Nằm sấp, tay đặt rộng bằng vai, đẩy người lên xuống',
        animationPath: 'assets/animations/pushup.json',
        commonMistakes: [
          'Mông quá cao',
          'Lưng võng',
          'Tay quá rộng hoặc quá hẹp',
        ],
        safetyTips: [
          'Giữ thẳng từ đầu đến chân',
          'Không để mông quá cao',
          'Hạ xuống từ từ',
        ],
        difficulty: 'Trung bình',
        duration: 45,
        targetMuscles: 'Ngực, Vai, Tay',
      ),
      Exercise(
        id: 'plank',
        name: 'Plank',
        description: 'Bài tập plank tăng cường cơ core và sức bền',
        instructions: 'Giữ tư thế như chuẩn bị hít đất, giữ thẳng cơ thể',
        animationPath: 'assets/animations/plank.json',
        commonMistakes: ['Mông quá cao', 'Lưng võng', 'Không thở đều'],
        safetyTips: [
          'Giữ thẳng từ đầu đến chân',
          'Thở đều đặn',
          'Nghỉ ngơi khi cần',
        ],
        difficulty: 'Dễ',
        duration: 30,
        targetMuscles: 'Core, Vai',
      ),
      Exercise(
        id: 'lunge',
        name: 'Lunge',
        description: 'Bài tập lunge tăng cường cơ đùi và cân bằng',
        instructions:
            'Bước một chân ra trước, hạ thấp cho đến khi hai đầu gối 90 độ',
        animationPath: 'assets/animations/lunge.json',
        commonMistakes: [
          'Đầu gối chạm đất',
          'Nghiêng về một bên',
          'Bước quá ngắn',
        ],
        safetyTips: ['Giữ thân thẳng', 'Đầu gối không chạm đất', 'Bước đủ dài'],
        difficulty: 'Trung bình',
        duration: 45,
        targetMuscles: 'Đùi, Mông',
      ),
      Exercise(
        id: 'burpee',
        name: 'Burpee',
        description: 'Bài tập burpee toàn thân tăng cường sức bền',
        instructions:
            'Từ đứng xuống squat, nhảy chân ra sau, hít đất, nhảy về và đứng dậy',
        animationPath: 'assets/animations/burpee.json',
        commonMistakes: [
          'Không hít đất đầy đủ',
          'Nhảy không cao',
          'Động tác quá nhanh',
        ],
        safetyTips: [
          'Thực hiện từ từ ban đầu',
          'Nghỉ ngơi giữa các lần',
          'Giữ form chuẩn',
        ],
        difficulty: 'Khó',
        duration: 60,
        targetMuscles: 'Toàn thân',
      ),
      Exercise(
        id: 'mountain_climbers',
        name: 'Mountain Climbers',
        description: 'Bài tập leo núi tăng cường tim mạch và core',
        instructions: 'Tư thế plank, luân phiên đưa đầu gối về phía ngực',
        animationPath: 'assets/animations/mountain_climbers.json',
        commonMistakes: [
          'Mông quá cao',
          'Động tác quá nhanh',
          'Không giữ thẳng lưng',
        ],
        safetyTips: [
          'Giữ tư thế plank',
          'Động tác có kiểm soát',
          'Thở đều đặn',
        ],
        difficulty: 'Trung bình',
        duration: 30,
        targetMuscles: 'Core, Tim mạch',
      ),
      Exercise(
        id: 'jumping_jacks',
        name: 'Jumping Jacks',
        description: 'Bài tập nhảy bật tăng cường tim mạch',
        instructions: 'Nhảy mở chân và giơ tay lên, rồi nhảy khép lại',
        animationPath: 'assets/animations/jumping_jacks.json',
        commonMistakes: [
          'Không nhảy đủ cao',
          'Tay không duỗi thẳng',
          'Hạ cánh không đúng',
        ],
        safetyTips: [
          'Hạ cánh nhẹ nhàng',
          'Giữ đầu gối mềm mại',
          'Động tác có nhịp điệu',
        ],
        difficulty: 'Dễ',
        duration: 30,
        targetMuscles: 'Tim mạch, Toàn thân',
      ),
      Exercise(
        id: 'situp',
        name: 'Sit-up / Crunches',
        description: 'Bài tập gập bụng tăng cường cơ bụng',
        instructions: 'Nằm ngửa, tay sau đầu, gập bụng đưa vai lên',
        animationPath: 'assets/animations/situp.json',
        commonMistakes: [
          'Kéo cổ quá mạnh',
          'Gập quá cao',
          'Động tác quá nhanh',
        ],
        safetyTips: ['Không kéo cổ', 'Gập từ bụng', 'Thở ra khi gập'],
        difficulty: 'Dễ',
        duration: 45,
        targetMuscles: 'Bụng trên',
      ),
      Exercise(
        id: 'deadlift',
        name: 'Deadlift',
        description: 'Bài tập nâng tạ tăng cường lưng và đùi',
        instructions: 'Cúi xuống nâng tạ, giữ lưng thẳng, đứng dậy',
        animationPath: 'assets/animations/deadlift.json',
        commonMistakes: ['Lưng cong', 'Tạ xa người', 'Không duỗi thẳng'],
        safetyTips: [
          'Giữ lưng thẳng luôn',
          'Tạ sát người',
          'Dùng chân để nâng',
        ],
        difficulty: 'Khó',
        duration: 60,
        targetMuscles: 'Lưng, Đùi, Mông',
      ),
      Exercise(
        id: 'shoulder_press',
        name: 'Shoulder Press',
        description: 'Bài tập đẩy vai tăng cường cơ vai',
        instructions: 'Đẩy tạ từ vai lên trên đầu, hạ xuống từ từ',
        animationPath: 'assets/animations/shoulder_press.json',
        commonMistakes: [
          'Cong lưng quá mức',
          'Đẩy không thẳng',
          'Hạ quá nhanh',
        ],
        safetyTips: ['Giữ core chặt', 'Đẩy thẳng lên', 'Kiểm soát khi hạ'],
        difficulty: 'Trung bình',
        duration: 45,
        targetMuscles: 'Vai, Tay',
      ),
    ];
  }

  static Exercise? getExerciseById(String id) {
    try {
      return getAllExercises().firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }
}
