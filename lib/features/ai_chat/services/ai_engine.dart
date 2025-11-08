import 'ai_data_service.dart';
import 'body_metrics_calculator.dart';

/// AI Engine - Trái tim của chatbot
/// Xử lý ngữ cảnh, từ khóa, và tạo phản hồi thông minh
class AIEngine {
  final AIDataService _dataService;
  final BodyMetricsCalculator _calculator;

  // Lưu context của cuộc hội thoại
  final Map<String, dynamic> _conversationContext = {};

  AIEngine(this._dataService, this._calculator);

  /// Xử lý tin nhắn và tạo phản hồi
  Future<String> processMessage(String userMessage) async {
    if (!_dataService.isInitialized) {
      await _dataService.initialize();
    }

    final normalizedMsg = _normalizeText(userMessage);

    // Phân tích intent (ý định) của người dùng
    final intent = _detectIntent(normalizedMsg);

    // Debug logging
    print('🤖 AI Engine Debug:');
    print('   User msg: $userMessage');
    print('   Intent: $intent');
    print('   Context: $_conversationContext');

    switch (intent) {
      case 'calculate_bmi':
        return _handleBMICalculation(normalizedMsg);
      case 'calculate_bmr':
        return _handleBMRCalculation(normalizedMsg);
      case 'calculate_tdee':
        return _handleTDEECalculation(normalizedMsg);
      case 'ask_exercise':
        return _handleExerciseQuery(normalizedMsg);
      case 'ask_nutrition':
        return _handleNutritionQuery(normalizedMsg);
      case 'ask_membership':
        return _handleMembershipQuery(normalizedMsg);
      case 'ask_workout_schedule':
        return _handleWorkoutScheduleQuery(normalizedMsg);
      case 'greeting':
        return _handleGreeting();
      case 'help':
        return _showHelp();
      default:
        return _handleGeneralQuery(normalizedMsg);
    }
  }

  /// Chuẩn hóa văn bản (loại bỏ dấu, viết thường, v.v.)
  String _normalizeText(String text) {
    // Chuyển thành chữ thường
    text = text.toLowerCase();

    // Map các ký tự có dấu sang không dấu
    const vietnamese =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const nonVietnamese =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    for (int i = 0; i < vietnamese.length; i++) {
      text = text.replaceAll(vietnamese[i], nonVietnamese[i]);
    }

    return text.trim();
  }

  /// Phát hiện intent của người dùng
  String _detectIntent(String normalizedMsg) {
    // Greeting
    if (_containsAny(normalizedMsg, [
      'xin chao',
      'chao',
      'hello',
      'hi',
      'hey',
      'alo',
      'alô',
    ])) {
      return 'greeting';
    }

    // Help
    if (_containsAny(normalizedMsg, [
      'giup',
      'help',
      'huong dan',
      'lam gi',
      'chuc nang',
      'ho tro',
    ])) {
      return 'help';
    }

    // BMI calculation
    if (_containsAny(normalizedMsg, ['bmi', 'chi so khoi', 'can nang']) &&
        _containsAny(normalizedMsg, ['tinh', 'tinh toan', 'la bao nhieu'])) {
      return 'calculate_bmi';
    }

    // BMR calculation
    if (_containsAny(normalizedMsg, ['bmr', 'basal', 'co ban', 'nghi ngoi']) &&
        _containsAny(normalizedMsg, ['tinh', 'tinh toan', 'la bao nhieu'])) {
      return 'calculate_bmr';
    }

    // TDEE calculation
    if (_containsAny(normalizedMsg, ['tdee', 'tieu hao', 'nang luong']) &&
        _containsAny(normalizedMsg, ['tinh', 'tinh toan', 'la bao nhieu'])) {
      return 'calculate_tdee';
    }

    // Exercise queries
    if (_containsAny(normalizedMsg, [
      'bai tap',
      'tap luyen',
      'the duc',
      'exercise',
      'workout',
      'gym',
      'co bap',
      'nguc',
      'lung',
      'vai',
      'tay',
      'chan',
      'bung',
      'mong',
    ])) {
      return 'ask_exercise';
    }

    // Nutrition queries
    if (_containsAny(normalizedMsg, [
      'thuc don',
      'an gi',
      'mon an',
      'dinh duong',
      'nutrition',
      'calo',
      'protein',
      'carb',
      'beo',
      'chat xo',
    ])) {
      return 'ask_nutrition';
    }

    // Membership queries
    if (_containsAny(normalizedMsg, [
      'the tap',
      'goi tap',
      'membership',
      'hoi vien',
      'premium',
      'vip',
      'gia',
      'bao nhieu tien',
    ])) {
      return 'ask_membership';
    }

    // Workout schedule queries
    if (_containsAny(normalizedMsg, [
      'lich tap',
      'chuong trinh tap',
      'ke hoach tap',
      'schedule',
      'program',
      'full body',
      'upper',
      'lower',
      'push',
      'pull',
      'legs',
    ])) {
      return 'ask_workout_schedule';
    }

    return 'general';
  }

  /// Kiểm tra chuỗi có chứa bất kỳ từ khóa nào không
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Xử lý tính BMI
  String _handleBMICalculation(String msg) {
    // Trích xuất cân nặng và chiều cao thông minh
    final weightHeight = _extractWeightAndHeight(msg);

    if (weightHeight['weight'] != null && weightHeight['height'] != null) {
      double weight = weightHeight['weight']!;
      double height = weightHeight['height']!;

      // Nếu chiều cao > 3, giả sử đơn vị là cm, convert sang m
      if (height > 3) {
        height = height / 100; // Convert cm to m
      }

      // Lưu vào context để dùng cho tính toán sau
      _conversationContext['weight'] = weight;
      _conversationContext['height'] = height;

      final bmi = _calculator.calculateBMI(weight: weight, height: height);

      // Lấy thông tin giới tính và tuổi từ context nếu có
      String gender = _conversationContext['gender'] ?? 'nam';
      int age = _conversationContext['age'] ?? 25;

      // Detect gender from message nếu có
      if (_containsAny(msg, ['nu', 'chi', 'co', 'female', 'woman', 'girl'])) {
        gender = 'nữ';
        _conversationContext['gender'] = gender;
      } else if (_containsAny(msg, ['nam', 'male', 'man', 'boy', 'anh'])) {
        gender = 'nam';
        _conversationContext['gender'] = gender;
      }

      // Extract age if present
      final ageFromMsg = _extractAge(msg);
      if (ageFromMsg != null) {
        age = ageFromMsg;
        _conversationContext['age'] = age;
      }

      final analysis = _calculator.analyzeBMI(
        bmi: bmi,
        gender: gender,
        age: age,
      );

      return '''
📊 **KẾT QUẢ TÍNH BMI**

🔢 Chỉ số BMI của bạn: **${bmi.toStringAsFixed(1)}**

📋 Phân loại: **${analysis['category']}**

💡 Mô tả: ${analysis['description']}

✅ Khuyến nghị: ${analysis['recommendation']}

📌 Lưu ý: ${analysis['note'] ?? ''}

Bạn cần tư vấn thêm về chế độ tập luyện hoặc dinh dưỡng không? 😊
''';
    }

    // Nếu không đủ thông tin, hỏi lại
    return '''
Để tính BMI, tôi cần biết:
📏 Cân nặng (kg)
📐 Chiều cao (cm)

Ví dụ: "Tính BMI cho tôi, tôi nặng 70kg cao 175cm"

Bạn có thể cho tôi biết cân nặng và chiều cao của bạn không? 😊
''';
  }

  /// Xử lý tính BMR
  String _handleBMRCalculation(String msg) {
    // Trích xuất thông tin thông minh
    final weightHeight = _extractWeightAndHeight(msg);
    final age = _extractAge(msg);

    // Cần: cân nặng, chiều cao, tuổi
    if (weightHeight['weight'] != null &&
        weightHeight['height'] != null &&
        age != null) {
      double weight = weightHeight['weight']!;
      double height = weightHeight['height']!;

      // Convert height to cm if needed
      if (height < 3) {
        height = height * 100;
      }

      // Detect gender from message
      String gender = 'nam';
      if (_containsAny(msg, ['nu', 'chi', 'co', 'female', 'woman', 'girl'])) {
        gender = 'nữ';
      }

      // Save to context
      _conversationContext['gender'] = gender;
      _conversationContext['age'] = age;
      _conversationContext['weight'] = weight;
      _conversationContext['height'] = height;

      final bmr = _calculator.calculateBMR(
        weight: weight,
        height: height,
        age: age,
        gender: gender,
      );

      final analysis = _calculator.analyzeBMR(
        bmr: bmr,
        gender: gender,
        age: age,
      );

      return '''
🔥 **KẾT QUẢ TÍNH BMR**

⚡ Chỉ số BMR của bạn: **${bmr.toStringAsFixed(0)} kcal/ngày**

📊 Khoảng tham khảo: ${analysis['range']}

💡 Ý nghĩa: ${analysis['description']}

✅ Khuyến nghị: ${analysis['recommendation']}

📌 *BMR là năng lượng cơ thể cần để duy trì hoạt động sống khi nghỉ ngơi hoàn toàn.*

Bạn có muốn tính **TDEE** (tổng năng lượng tiêu hao hàng ngày) dựa trên mức độ vận động không? 😊
''';
    }

    return '''
Để tính BMR, tôi cần:
📏 Cân nặng (kg)
📐 Chiều cao (cm)
🎂 Tuổi
⚧ Giới tính (nam/nữ)

Ví dụ: "Tính BMR cho nam 25 tuổi, nặng 70kg, cao 175cm"

Hãy cho tôi biết thông tin của bạn nhé! 😊
''';
  }

  /// Xử lý tính TDEE
  String _handleTDEECalculation(String msg) {
    // Thử parse thông tin mới từ tin nhắn trước
    final weightHeight = _extractWeightAndHeight(msg);
    final ageFromMsg = _extractAge(msg);

    // Detect gender from message
    String gender = 'nam';
    if (_containsAny(msg, ['nu', 'chi', 'co', 'female', 'woman', 'girl'])) {
      gender = 'nữ';
    }

    // Nếu có thông tin đầy đủ trong tin nhắn mới, dùng thông tin đó
    double? weight = weightHeight['weight'];
    double? height = weightHeight['height'];
    int? age;

    if (weight != null && height != null) {
      // Save to context
      _conversationContext['weight'] = weight;
      _conversationContext['height'] = height;
      _conversationContext['gender'] = gender;
    } else if (_conversationContext.containsKey('weight') &&
        _conversationContext.containsKey('height')) {
      // Nếu không có trong tin nhắn, dùng từ context
      weight = _conversationContext['weight'];
      height = _conversationContext['height'];
      gender = _conversationContext['gender'] ?? 'nam';
    }

    if (ageFromMsg != null) {
      age = ageFromMsg;
      _conversationContext['age'] = age;
    } else if (_conversationContext.containsKey('age')) {
      age = _conversationContext['age'];
    }

    // Kiểm tra có đủ thông tin không
    if (weight != null && height != null && age != null) {
      final bmr = _calculator.calculateBMR(
        weight: weight,
        height: height,
        age: age,
        gender: gender,
      );

      // Detect activity level - Cần chặt chẽ hơn để tránh nhầm với "nặng 60kg"
      String activityLevel = 'moderate';
      final normalizedMsg = _normalizeText(msg);

      if (_containsAny(normalizedMsg, [
        'it van dong',
        'khong tap',
        'sedentary',
        'ngoi nhieu',
        'ngoi van phong',
      ])) {
        activityLevel = 'sedentary';
      } else if (_containsAny(normalizedMsg, [
        'tap nhe',
        'van dong nhe',
        'light',
        '1-3 buoi',
      ])) {
        activityLevel = 'light';
      } else if (_containsAny(normalizedMsg, [
        'tap vua',
        'van dong vua',
        'moderate',
        '3-5 buoi',
      ])) {
        activityLevel = 'moderate';
      } else if (_containsAny(normalizedMsg, [
        'tap nang',
        'van dong nang',
        'very active',
        '6-7 buoi',
      ])) {
        activityLevel = 'very_active';
      } else if (_containsAny(normalizedMsg, [
        'rat nang',
        'cuc nang',
        'extra',
        'vdv',
        'van dong vien',
      ])) {
        activityLevel = 'extra_active';
      }

      final tdee = _calculator.calculateTDEE(
        bmr: bmr,
        activityLevel: activityLevel,
      );

      final activityLabels = {
        'sedentary': 'Rất ít vận động (1.2x BMR)',
        'light': 'Vận động nhẹ 1-3 buổi/tuần (1.375x BMR)',
        'moderate': 'Vận động vừa 3-5 buổi/tuần (1.55x BMR)',
        'very_active': 'Vận động nặng 6-7 buổi/tuần (1.725x BMR)',
        'extra_active': 'Cường độ cao - VĐV (1.9x BMR)',
      };

      return '''
🔥 **KẾT QUẢ TÍNH TDEE**

📋 **Thông tin:**
   • Cân nặng: ${weight.toStringAsFixed(1)} kg
   • Chiều cao: ${height.toStringAsFixed(0)} cm
   • Tuổi: $age
   • Giới tính: ${gender == 'nam' ? 'Nam' : 'Nữ'}

⚡ BMR: **${bmr.toStringAsFixed(0)} kcal/ngày**

⚡ TDEE: **${tdee.toStringAsFixed(0)} kcal/ngày**

📊 Mức độ vận động: ${activityLabels[activityLevel]}

💡 **Khuyến nghị dinh dưỡng theo mục tiêu:**

🎯 **Giảm cân:** ${(tdee - 500).toStringAsFixed(0)} kcal/ngày (-500 kcal)
🎯 **Duy trì:** ${tdee.toStringAsFixed(0)} kcal/ngày
🎯 **Tăng cơ:** ${(tdee + 300).toStringAsFixed(0)} kcal/ngày (+300 kcal)

Bạn muốn tư vấn về thực đơn cụ thể không? 😊
''';
    }

    return '''
Để tính TDEE, tôi cần biết:
1️⃣ Thông tin cơ bản (cân nặng, chiều cao, tuổi, giới tính)
2️⃣ Mức độ vận động:
   - Ít vận động (ngồi nhiều)
   - Nhẹ (1-3 buổi/tuần)
   - Vừa (3-5 buổi/tuần)
   - Nặng (6-7 buổi/tuần)
   - Rất nặng (VĐV)

Ví dụ: "Tính TDEE cho nam 21 tuổi, cao 170cm, nặng 60kg, tập vừa"

Hãy cho tôi biết thông tin nhé! 😊
''';
  }

  /// Xử lý câu hỏi về bài tập
  String _handleExerciseQuery(String msg) {
    final exercises = _dataService.exercisesData['baiTap'] as List? ?? [];

    // Tìm kiếm bài tập theo từ khóa
    List<String> keywords = [];

    // Nhóm cơ
    if (_containsAny(msg, ['nguc', 'chest'])) keywords.add('ngực');
    if (_containsAny(msg, ['lung', 'back', 'xo'])) keywords.add('lưng');
    if (_containsAny(msg, ['vai', 'shoulder', 'deltoid'])) keywords.add('vai');
    if (_containsAny(msg, ['tay truoc', 'bicep', 'tay'])) keywords.add('tay');
    if (_containsAny(msg, ['chan', 'leg', 'dui'])) keywords.add('chân');
    if (_containsAny(msg, ['bung', 'abs', 'core'])) keywords.add('bụng');
    if (_containsAny(msg, ['mong', 'glute', 'glutes'])) keywords.add('mông');

    // Độ khó
    String difficulty = '';
    if (_containsAny(msg, ['de', 'moi', 'beginner'])) difficulty = 'Dễ';
    if (_containsAny(msg, ['trung binh', 'intermediate'])) {
      difficulty = 'Trung bình';
    }
    if (_containsAny(msg, ['kho', 'nang cao', 'advanced'])) difficulty = 'Khó';

    List<Map<String, dynamic>> matchedExercises = [];

    for (var ex in exercises) {
      bool matches = false;

      if (keywords.isNotEmpty) {
        for (var keyword in keywords) {
          final exName = _normalizeText(ex['tenBaiTap'] ?? '');
          final exGroup = _normalizeText(ex['nhomCoChinh'] ?? '');
          final normalizedKeyword = _normalizeText(keyword);

          if (exName.contains(normalizedKeyword) ||
              exGroup.contains(normalizedKeyword)) {
            matches = true;
            break;
          }
        }
      }

      if (difficulty.isNotEmpty && ex['doKho'] == difficulty) {
        matches = true;
      }

      if (keywords.isEmpty && difficulty.isEmpty) {
        matches = true; // Hiển thị tất cả nếu không có keyword cụ thể
      }

      if (matches) {
        matchedExercises.add(ex as Map<String, dynamic>);
      }
    }

    if (matchedExercises.isEmpty) {
      return '''
Xin lỗi, tôi không tìm thấy bài tập phù hợp với yêu cầu của bạn.

💪 **Bạn có thể hỏi về:**
- Bài tập ngực, lưng, vai, tay, chân, bụng, mông
- Bài tập dễ, trung bình, khó
- Ví dụ: "Gợi ý bài tập ngực cho người mới"

Hãy thử lại nhé! 😊
''';
    }

    // Giới hạn 5 bài tập đầu tiên
    final displayExercises = matchedExercises.take(5).toList();

    String response = '💪 **GỢI Ý BÀI TẬP**\n\n';

    for (var i = 0; i < displayExercises.length; i++) {
      final ex = displayExercises[i];
      response +=
          '''
${i + 1}. **${ex['tenBaiTap']}**
   📍 Nhóm cơ: ${ex['nhomCoChinh']}
   🔧 Dụng cụ: ${ex['dungCu']}
   📊 Độ khó: ${ex['doKho']}
   💡 Cách tập: ${ex['cachTap']}
   ✅ Lợi ích: ${ex['moTa']}

''';
    }

    if (matchedExercises.length > 5) {
      response +=
          '\n📌 Còn ${matchedExercises.length - 5} bài tập khác. Hỏi cụ thể hơn để xem thêm!\n';
    }

    response += '\nBạn muốn biết thêm về bài tập nào không? 😊';

    return response;
  }

  /// Xử lý câu hỏi về dinh dưỡng
  String _handleNutritionQuery(String msg) {
    final nutrition = _dataService.nutritionData['nutrition'] as List? ?? [];

    List<Map<String, dynamic>> matchedFoods = [];

    // Keywords for search
    bool searchProtein = _containsAny(msg, ['protein', 'dam', 'thit', 'ca']);
    bool searchCarb = _containsAny(msg, ['carb', 'tinh bot', 'com', 'mi']);
    bool searchLowCal = _containsAny(msg, [
      'giam can',
      'it calo',
      'low calorie',
    ]);
    bool searchHighCal = _containsAny(msg, [
      'tang can',
      'nhieu calo',
      'high calorie',
    ]);

    for (var food in nutrition) {
      bool matches = false;

      // Tìm theo tên món
      final foodName = _normalizeText(food['ten_mon'] ?? '');
      if (foodName.contains(_normalizeText(msg))) {
        matches = true;
      }

      // Tìm theo protein cao
      if (searchProtein && (food['dam_g'] ?? 0) > 15) {
        matches = true;
      }

      // Tìm theo carb cao
      if (searchCarb && (food['carb_g'] ?? 0) > 20) {
        matches = true;
      }

      // Tìm món ít calo
      if (searchLowCal && (food['nang_luong_kcal'] ?? 0) < 100) {
        matches = true;
      }

      // Tìm món nhiều calo
      if (searchHighCal && (food['nang_luong_kcal'] ?? 0) > 200) {
        matches = true;
      }

      if (matches) {
        matchedFoods.add(food as Map<String, dynamic>);
      }
    }

    if (matchedFoods.isEmpty) {
      return '''
🥗 **TƯ VẤN DINH DƯỠNG**

Xin lỗi, tôi không tìm thấy món ăn phù hợp.

💡 **Bạn có thể hỏi:**
- "Món ăn giàu protein"
- "Món ăn ít calo cho người giảm cân"
- "Thực đơn tăng cơ"
- "Giá trị dinh dưỡng của cơm gạo lứt"

Hãy thử lại nhé! 😊
''';
    }

    final displayFoods = matchedFoods.take(5).toList();

    String response = '🥗 **GỢI Ý DINH DƯỠNG**\n\n';

    for (var i = 0; i < displayFoods.length; i++) {
      final food = displayFoods[i];
      response +=
          '''
${i + 1}. **${food['ten_mon']}**
   📊 Năng lượng: ${food['nang_luong_kcal']} kcal/100g
   💪 Protein: ${food['dam_g']}g
   🍚 Carb: ${food['carb_g']}g
   🥑 Béo: ${food['beo_g']}g
   🌾 Chất xơ: ${food['chat_xo_g'] ?? 0}g
   ✅ Lợi ích: ${food['loi_ich']}

''';
    }

    if (matchedFoods.length > 5) {
      response +=
          '\n📌 Còn ${matchedFoods.length - 5} món ăn khác. Hỏi cụ thể hơn để xem thêm!\n';
    }

    response += '\nBạn cần tư vấn thêm về chế độ ăn không? 😊';

    return response;
  }

  /// Xử lý câu hỏi về thẻ tập
  String _handleMembershipQuery(String msg) {
    final cards = _dataService.membershipData['cards'] as List? ?? [];

    List<Map<String, dynamic>> matchedCards = [];

    // Filter by type
    if (_containsAny(msg, ['vip'])) {
      matchedCards = cards
          .where((card) => (card as Map<String, dynamic>)['loaiGoi'] == 'vip')
          .cast<Map<String, dynamic>>()
          .toList();
    } else if (_containsAny(msg, ['premium'])) {
      matchedCards = cards
          .where(
            (card) => (card as Map<String, dynamic>)['loaiGoi'] == 'premium',
          )
          .cast<Map<String, dynamic>>()
          .toList();
    } else if (_containsAny(msg, ['co ban', 'member', 'basic'])) {
      matchedCards = cards
          .where(
            (card) => (card as Map<String, dynamic>)['loaiGoi'] == 'member',
          )
          .cast<Map<String, dynamic>>()
          .toList();
    } else {
      matchedCards = cards.cast<Map<String, dynamic>>();
    }

    if (matchedCards.isEmpty) {
      matchedCards = cards.cast<Map<String, dynamic>>();
    }

    String response = '💳 **GÓI THẺ TẬP GYM PRO**\n\n';

    for (var i = 0; i < matchedCards.length; i++) {
      final card = matchedCards[i];
      response +=
          '''
${i + 1}. **${card['tenGoi']}** (${card['loaiGoi'].toString().toUpperCase()})
   💰 Giá: ${_formatCurrency(card['gia'])}
   ⏱ Thời hạn: ${card['thoiLuong']} ${card['donViThoiLuong']}
   📝 Mô tả: ${card['moTa']}
   🎯 Phù hợp: ${card['phuHopCho']}
   ✨ Lợi ích:
${(card['loiIch'] as List).map((e) => '      • $e').join('\n')}

''';
    }

    response += '''
📞 Liên hệ ngay để được tư vấn chi tiết và ưu đãi!

Bạn muốn biết thêm về gói nào không? 😊
''';

    return response;
  }

  /// Xử lý câu hỏi về lịch tập
  String _handleWorkoutScheduleQuery(String msg) {
    final workoutData = _dataService.workoutData['workout_schedules'];
    final programs = workoutData['programs'] as List? ?? [];

    List<Map<String, dynamic>> matchedPrograms = [];

    // Filter by goal or difficulty
    for (var program in programs) {
      final prog = program as Map<String, dynamic>;
      final name = _normalizeText(prog['ten'] ?? '');
      final goal = _normalizeText(prog['muc_tieu'] ?? '');
      final difficulty = _normalizeText(prog['do_kho'] ?? '');

      bool matches = false;

      if (_containsAny(msg, ['full body', 'toan than']) &&
          name.contains('full')) {
        matches = true;
      }
      if (_containsAny(msg, ['upper', 'lower', 'tren', 'duoi']) &&
          name.contains('upper')) {
        matches = true;
      }
      if (_containsAny(msg, ['ppl', 'push', 'pull', 'legs']) &&
          name.contains('push')) {
        matches = true;
      }
      if (_containsAny(msg, ['tang co', 'hypertrophy']) &&
          goal.contains('tang co')) {
        matches = true;
      }
      if (_containsAny(msg, ['giam mo', 'fat loss', 'giam can']) &&
          goal.contains('giam mo')) {
        matches = true;
      }
      if (_containsAny(msg, ['moi', 'beginner']) &&
          difficulty.contains('beginner')) {
        matches = true;
      }

      if (matches) {
        matchedPrograms.add(prog);
      }
    }

    if (matchedPrograms.isEmpty) {
      matchedPrograms = programs.take(3).cast<Map<String, dynamic>>().toList();
    }

    String response = '📅 **LỊCH TẬP ĐƯỢC ĐỀ XUẤT**\n\n';

    for (var i = 0; i < matchedPrograms.length; i++) {
      final prog = matchedPrograms[i];
      response +=
          '''
${i + 1}. **${prog['ten']}**
   🎯 Mục tiêu: ${prog['muc_tieu']}
   📊 Độ khó: ${prog['do_kho']}
   ⏰ Thời lượng: ${prog['thoi_luong_tuan']} buổi/tuần
   📆 Chu kỳ: ${prog['thoi_gian_chuong_trinh']}
   📝 Mô tả: ${prog['mo_ta']}

''';
    }

    response += '''
📌 Bạn muốn xem chi tiết lịch tập cho ngày cụ thể không?
💡 Hoặc cần tư vấn lịch tập phù hợp với mục tiêu của bạn?

Hãy cho tôi biết nhé! 😊
''';

    return response;
  }

  /// Xử lý lời chào
  String _handleGreeting() {
    return '''
👋 Xin chào! Tôi là **Gym Pro AI** - trợ lý thông minh của bạn!

💪 **Tôi có thể giúp bạn:**

📊 **Tính toán chỉ số cơ thể:**
   • BMI (chỉ số khối cơ thể)
   • BMR (năng lượng cơ bản)
   • TDEE (tổng năng lượng tiêu hao)

🏋️ **Tư vấn tập luyện:**
   • Gợi ý bài tập theo nhóm cơ
   • Lịch tập chi tiết
   • Chương trình tập theo mục tiêu

🥗 **Dinh dưỡng:**
   • Thực đơn phù hợp
   • Giá trị dinh dưỡng món ăn
   • Chế độ ăn cho mục tiêu

💳 **Thông tin gói tập:**
   • Các gói thành viên
   • Ưu đãi đặc biệt

Bạn muốn bắt đầu từ đâu? 😊
''';
  }

  /// Hiển thị hướng dẫn
  String _showHelp() {
    return '''
💡 **HƯỚNG DẪN SỬ DỤNG**

📝 **Ví dụ câu hỏi:**

1️⃣ **Tính toán:**
   • "Tính BMI cho tôi, 70kg cao 175cm"
   • "Tính TDEE cho nam 25 tuổi, tập vừa"

2️⃣ **Bài tập:**
   • "Gợi ý bài tập ngực"
   • "Bài tập chân cho người mới"

3️⃣ **Dinh dưỡng:**
   • "Món ăn giàu protein"
   • "Thực đơn giảm cân"

4️⃣ **Lịch tập:**
   • "Lịch tập full body"
   • "Chương trình tập 3 buổi/tuần"

5️⃣ **Thẻ tập:**
   • "Gói thẻ VIP"
   • "Thẻ tập 1 tháng bao nhiêu?"

🎯 Tôi hiểu được cả từ viết tắt, sai chính tả, và ngữ cảnh!

Hãy thử hỏi tôi bất cứ điều gì! 😊
''';
  }

  /// Xử lý câu hỏi chung
  String _handleGeneralQuery(String msg) {
    return '''
🤔 Hmm, tôi chưa hiểu rõ câu hỏi của bạn.

💡 **Tôi có thể giúp bạn với:**
- Tính BMI, BMR, TDEE
- Tư vấn bài tập theo nhóm cơ
- Gợi ý dinh dưỡng
- Lịch tập chi tiết
- Thông tin gói thẻ

Hãy hỏi cụ thể hơn hoặc gõ "hướng dẫn" để xem ví dụ! 😊
''';
  }

  /// Trích xuất cân nặng và chiều cao thông minh dựa trên từ khóa
  Map<String, double?> _extractWeightAndHeight(String text) {
    double? weight;
    double? height;

    final normalizedText = text.toLowerCase();

    // Tìm các số kèm đơn vị hoặc từ khóa
    final regex = RegExp(r'(\d+\.?\d*)\s*(kg|cm|m)?');
    final matches = regex.allMatches(normalizedText);

    // Tạo list các số với context xung quanh
    List<Map<String, dynamic>> numbersWithContext = [];
    for (var match in matches) {
      final number = double.tryParse(match.group(1) ?? '');
      if (number == null) continue;

      final unit = match.group(2)?.toLowerCase() ?? '';

      // Lấy 20 ký tự trước số để phân tích context
      final startPos = match.start > 20 ? match.start - 20 : 0;
      final contextBefore = normalizedText.substring(startPos, match.start);

      numbersWithContext.add({
        'value': number,
        'unit': unit,
        'context': contextBefore,
      });
    }

    // Ưu tiên 1: Số có đơn vị rõ ràng
    for (var item in numbersWithContext) {
      final number = item['value'] as double;
      final unit = item['unit'] as String;

      if (unit == 'kg' && weight == null) {
        weight = number;
      } else if ((unit == 'cm' || unit == 'm') && height == null) {
        height = unit == 'm' ? number * 100 : number;
      }
    }

    // Ưu tiên 2: Số có từ khóa rõ ràng
    for (var item in numbersWithContext) {
      final number = item['value'] as double;
      final context = item['context'] as String;

      // Check weight keywords
      if (weight == null && _containsAny(context, ['nang', 'can', 'weight'])) {
        weight = number;
      }

      // Check height keywords
      if (height == null &&
          _containsAny(context, ['cao', 'chieu cao', 'height'])) {
        height = number;
        // Convert to cm if in meters
        if (height < 3) height = height * 100;
      }
    }

    // Ưu tiên 3: Dựa vào phạm vi giá trị
    if (weight == null || height == null) {
      for (var item in numbersWithContext) {
        final number = item['value'] as double;

        // Chiều cao: 140-220cm hoặc 1.4-2.2m
        if (height == null) {
          if (number >= 140 && number <= 220) {
            height = number; // cm
            continue;
          } else if (number >= 1.4 && number <= 2.2) {
            height = number * 100; // convert m to cm
            continue;
          }
        }

        // Cân nặng: 30-200kg
        if (weight == null && number >= 30 && number <= 200) {
          // Đảm bảo không nhầm với chiều cao
          if (number < 140 || number > 220) {
            weight = number;
          }
        }
      }
    }

    return {'weight': weight, 'height': height};
  }

  /// Trích xuất tuổi từ văn bản
  /// Sử dụng keywords và phạm vi giá trị
  int? _extractAge(String text) {
    // Regex để tìm số có thể kèm đơn vị tuổi
    final regex = RegExp(r'(\d+)\s*(tuoi|tuổi|age|year|yr)?');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2);
      final position = match.start;

      // Kiểm tra keyword tuổi
      final textBefore = text.substring(0, position).toLowerCase();
      final hasAgeKeyword =
          textBefore.contains('tuoi') ||
          textBefore.contains('tuổi') ||
          textBefore.contains('age') ||
          unit != null;

      // Phạm vi hợp lệ cho tuổi: 10-100
      if (hasAgeKeyword && value >= 10 && value <= 100) {
        return value;
      }

      // Nếu không có keyword nhưng giá trị nằm trong khoảng tuổi hợp lý
      if (!hasAgeKeyword && value >= 15 && value <= 90) {
        // Kiểm tra xem số này có phải là cân nặng hoặc chiều cao không
        final isWeight =
            textBefore.contains('nang') ||
            textBefore.contains('can') ||
            textBefore.contains('kg');
        final isHeight =
            textBefore.contains('cao') ||
            textBefore.contains('chieu') ||
            textBefore.contains('cm') ||
            textBefore.contains('met');

        if (!isWeight && !isHeight) {
          return value;
        }
      }
    }

    return null;
  }

  /// Format tiền tệ
  String _formatCurrency(dynamic amount) {
    if (amount is! num) return amount.toString();
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ';
  }

  /// Clear conversation context
  void clearContext() {
    _conversationContext.clear();
  }
}
