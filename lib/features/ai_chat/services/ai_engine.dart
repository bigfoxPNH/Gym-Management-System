import 'ai_data_service.dart';
import 'body_metrics_calculator.dart';

/// AI Engine - Trái tim của chatbot
/// Xử lý ngữ cảnh, từ khóa, và tạo phản hồi thông minh
class AIEngine {
  final AIDataService _dataService;
  final BodyMetricsCalculator _calculator;

  // Lưu context của cuộc hội thoại
  final Map<String, dynamic> _conversationContext = {};

  // Trạng thái cuộc hội thoại - đang chờ thông tin gì
  String?
  _waitingFor; // 'weight', 'height', 'age', 'gender', 'activity', 'metric_type'
  String? _pendingCalculation; // 'bmi', 'bmr', 'tdee'

  AIEngine(this._dataService, this._calculator);

  /// Xử lý tin nhắn và tạo phản hồi
  Future<String> processMessage(String userMessage) async {
    if (!_dataService.isInitialized) {
      await _dataService.initialize();
    }

    final normalizedMsg = _normalizeText(userMessage);

    // Debug logging
    print('🤖 AI Engine Debug:');
    print('   User msg: $userMessage');
    print('   Waiting for: $_waitingFor');
    print('   Pending calc: $_pendingCalculation');
    print('   Context: $_conversationContext');

    // Nếu đang chờ thông tin từ người dùng, xử lý response
    if (_waitingFor != null && _pendingCalculation != null) {
      return _handlePendingInformationResponse(userMessage, normalizedMsg);
    }

    // Phân tích intent (ý định) của người dùng
    final intent = _detectIntent(normalizedMsg);
    print('   Intent: $intent');

    switch (intent) {
      case 'calculate_bmi':
        return _handleBMICalculation(userMessage, normalizedMsg);
      case 'calculate_bmr':
        return _handleBMRCalculation(userMessage, normalizedMsg);
      case 'calculate_tdee':
        return _handleTDEECalculation(userMessage, normalizedMsg);
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
      case 'general_health':
        return _handleGeneralHealthQuery(userMessage, normalizedMsg);
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

    // General health check query - người dùng hỏi chung chung về sức khỏe
    if (_containsAny(normalizedMsg, [
          'chi so co the',
          'suc khoe',
          'co the',
          'on khong',
          'xem giup',
          'kiem tra',
        ]) &&
        (_containsAny(normalizedMsg, ['kg', 'cm']) ||
            _containsAny(normalizedMsg, ['nang', 'cao', 'can']))) {
      return 'general_health';
    }

    // BMI calculation
    if (_containsAny(normalizedMsg, ['bmi', 'chi so khoi', 'can nang']) ||
        (_containsAny(normalizedMsg, ['tinh', 'tinh toan']) &&
            _containsAny(normalizedMsg, ['kg', 'cm']))) {
      return 'calculate_bmi';
    }

    // BMR calculation
    if (_containsAny(normalizedMsg, [
      'bmr',
      'basal',
      'co ban',
      'nghi ngoi',
      'luong co so',
    ])) {
      return 'calculate_bmr';
    }

    // TDEE calculation
    if (_containsAny(normalizedMsg, [
      'tdee',
      'tieu hao',
      'nang luong',
      'tong nang luong',
    ])) {
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

  /// Xử lý khi người dùng hỏi chung về sức khỏe
  String _handleGeneralHealthQuery(String originalMsg, String normalizedMsg) {
    // Parse thông tin từ tin nhắn
    final weightHeight = _extractWeightAndHeight(normalizedMsg);
    final age = _extractAge(normalizedMsg);

    // Lưu thông tin vào context
    if (weightHeight['weight'] != null) {
      _conversationContext['weight'] = weightHeight['weight'];
    }
    if (weightHeight['height'] != null) {
      _conversationContext['height'] = weightHeight['height'];
    }
    if (age != null) {
      _conversationContext['age'] = age;
    }

    // Detect gender
    if (_containsAny(normalizedMsg, ['nu', 'chi', 'co', 'female', 'woman'])) {
      _conversationContext['gender'] = 'nữ';
    } else if (_containsAny(normalizedMsg, ['nam', 'male', 'man', 'anh'])) {
      _conversationContext['gender'] = 'nam';
    }

    return '''
👋 Để tôi giúp bạn kiểm tra sức khỏe nhé!

📊 Với thông tin cân nặng và chiều cao, tôi có thể tính cho bạn:

🔹 **BMI** - Chỉ số khối cơ thể (đánh giá gầy/chuẩn/thừa cân)
🔹 **BMR** - Lượng calo cơ bản cơ thể cần khi nghỉ ngơi
🔹 **TDEE** - Tổng lượng calo hàng ngày dựa trên hoạt động

💡 Bạn muốn tôi tính chỉ số nào? Hoặc nếu muốn tôi tính cả 3 chỉ số thì hãy nói **"tính cả 3"** nhé! 😊

${_getSuggestedInfoText()}
''';
  }

  /// Xử lý response khi đang chờ thông tin từ người dùng
  String _handlePendingInformationResponse(
    String originalMsg,
    String normalizedMsg,
  ) {
    print('   Processing pending response for: $_waitingFor');

    // Parse TẤT CẢ thông tin từ response (không chỉ cái đang chờ)
    final weightHeight = _extractWeightAndHeight(normalizedMsg);
    final age = _extractAge(normalizedMsg);

    // Detect gender
    if (_containsAny(normalizedMsg, [
      'nu',
      'chi',
      'co',
      'female',
      'woman',
      'girl',
    ])) {
      _conversationContext['gender'] = 'nữ';
    } else if (_containsAny(normalizedMsg, [
      'nam',
      'male',
      'man',
      'boy',
      'anh',
    ])) {
      _conversationContext['gender'] = 'nam';
    }

    // Detect activity
    if (_containsAny(normalizedMsg, [
      'it van dong',
      'khong tap',
      'sedentary',
      'ngoi nhieu',
    ])) {
      _conversationContext['activity'] = 'sedentary';
    } else if (_containsAny(normalizedMsg, [
      'tap nhe',
      'van dong nhe',
      'light',
      '1-3 buoi',
    ])) {
      _conversationContext['activity'] = 'light';
    } else if (_containsAny(normalizedMsg, [
      'tap vua',
      'van dong vua',
      'moderate',
      '3-5 buoi',
      'trung binh',
    ])) {
      _conversationContext['activity'] = 'moderate';
    } else if (_containsAny(normalizedMsg, [
      'tap nang',
      'van dong nang',
      'very active',
      '6-7 buoi',
      'nhieu',
    ])) {
      _conversationContext['activity'] = 'very_active';
    } else if (_containsAny(normalizedMsg, [
      'rat nang',
      'cuc nang',
      'extra',
      'vdv',
    ])) {
      _conversationContext['activity'] = 'extra_active';
    }

    // Cập nhật thông tin CHỈ KHI đang chờ thông tin đó
    // Điều này tránh việc parse nhầm (ví dụ: "166cm" bị parse thành age = 166)
    if (_waitingFor == 'weight' && weightHeight['weight'] != null) {
      _conversationContext['weight'] = weightHeight['weight'];
      print('   Updated weight: ${weightHeight['weight']}');
    } else if (_waitingFor == 'height' && weightHeight['height'] != null) {
      _conversationContext['height'] = weightHeight['height'];
      print('   Updated height: ${weightHeight['height']}');
    } else if (_waitingFor == 'age' && age != null) {
      _conversationContext['age'] = age;
      print('   Updated age: $age');
    } else if (_waitingFor == null) {
      // Nếu không đang chờ gì, lưu tất cả thông tin parse được
      if (weightHeight['weight'] != null) {
        _conversationContext['weight'] = weightHeight['weight'];
        print('   Updated weight: ${weightHeight['weight']}');
      }
      if (weightHeight['height'] != null) {
        _conversationContext['height'] = weightHeight['height'];
        print('   Updated height: ${weightHeight['height']}');
      }
      if (age != null) {
        _conversationContext['age'] = age;
        print('   Updated age: $age');
      }
    }

    // Clear waiting state nếu nhận được thông tin cần
    if (_waitingFor == 'weight' && weightHeight['weight'] != null) {
      _waitingFor = null;
    } else if (_waitingFor == 'height' && weightHeight['height'] != null) {
      _waitingFor = null;
    } else if (_waitingFor == 'age' && age != null) {
      _waitingFor = null;
    } else if (_waitingFor == 'gender' &&
        _conversationContext.containsKey('gender')) {
      _waitingFor = null;
    } else if (_waitingFor == 'activity' &&
        _conversationContext.containsKey('activity')) {
      _waitingFor = null;
    } else if (_waitingFor == 'activity') {
      if (_containsAny(normalizedMsg, [
        'it',
        'khong tap',
        'sedentary',
        'ngoi',
      ])) {
        _conversationContext['activity'] = 'sedentary';
        _waitingFor = null;
      } else if (_containsAny(normalizedMsg, ['nhe', 'light', '1-3'])) {
        _conversationContext['activity'] = 'light';
        _waitingFor = null;
      } else if (_containsAny(normalizedMsg, [
        'vua',
        'moderate',
        '3-5',
        'trung binh',
      ])) {
        _conversationContext['activity'] = 'moderate';
        _waitingFor = null;
      } else if (_containsAny(normalizedMsg, ['nang', 'cao', 'very', '6-7'])) {
        _conversationContext['activity'] = 'very_active';
        _waitingFor = null;
      } else if (_containsAny(normalizedMsg, ['rat nang', 'extra', 'vdv'])) {
        _conversationContext['activity'] = 'extra_active';
        _waitingFor = null;
      }
    } else if (_waitingFor == 'metric_type') {
      // Người dùng chọn chỉ số muốn tính
      if (_containsAny(normalizedMsg, ['bmi'])) {
        _pendingCalculation = 'bmi';
        _waitingFor = null;
      } else if (_containsAny(normalizedMsg, ['bmr'])) {
        _pendingCalculation = 'bmr';
        _waitingFor = null;
      } else if (_containsAny(normalizedMsg, ['tdee'])) {
        _pendingCalculation = 'tdee';
        _waitingFor = null;
      } else if (_containsAny(normalizedMsg, ['ca 3', 'tat ca', 'all'])) {
        return _calculateAllMetrics();
      }
    }

    // Thử tính toán nếu đủ thông tin
    if (_pendingCalculation != null && _waitingFor == null) {
      return _tryCalculatePendingMetric();
    }

    // Nếu vẫn chưa có thông tin cần thiết, tiếp tục hỏi
    return _askForMissingInformation();
  }

  /// Lấy text gợi ý thông tin còn thiếu
  String _getSuggestedInfoText() {
    List<String> missing = [];

    if (!_conversationContext.containsKey('weight')) {
      missing.add('📏 Cân nặng (kg)');
    }
    if (!_conversationContext.containsKey('height')) {
      missing.add('📐 Chiều cao (cm)');
    }

    if (missing.isEmpty) {
      return '';
    }

    return '\n📝 Tôi thấy bạn chưa cho biết:\n${missing.join('\n')}';
  }

  /// Hỏi thông tin còn thiếu
  String _askForMissingInformation() {
    if (_pendingCalculation == null) {
      return _showHelp();
    }

    // Check BMI requirements
    if (_pendingCalculation == 'bmi') {
      if (!_conversationContext.containsKey('weight')) {
        _waitingFor = 'weight';
        return '📏 Bạn nặng bao nhiêu kg vậy? 😊';
      }
      if (!_conversationContext.containsKey('height')) {
        _waitingFor = 'height';
        return '📐 Bạn cao bao nhiêu cm? 😊';
      }
    }

    // Check BMR requirements
    if (_pendingCalculation == 'bmr') {
      if (!_conversationContext.containsKey('weight')) {
        _waitingFor = 'weight';
        return '📏 Bạn nặng bao nhiêu kg vậy? 😊';
      }
      if (!_conversationContext.containsKey('height')) {
        _waitingFor = 'height';
        return '📐 Bạn cao bao nhiêu cm? 😊';
      }
      if (!_conversationContext.containsKey('age')) {
        _waitingFor = 'age';
        return '🎂 Bạn có thể cho tôi biết tuổi của bạn không? 😊';
      }
      if (!_conversationContext.containsKey('gender')) {
        _waitingFor = 'gender';
        return '👤 Bạn là nam hay nữ để tôi tính chính xác hơn? 😊';
      }
    }

    // Check TDEE requirements
    if (_pendingCalculation == 'tdee') {
      if (!_conversationContext.containsKey('weight')) {
        _waitingFor = 'weight';
        return '📏 Bạn nặng bao nhiêu kg vậy? 😊';
      }
      if (!_conversationContext.containsKey('height')) {
        _waitingFor = 'height';
        return '📐 Bạn cao bao nhiêu cm? 😊';
      }
      if (!_conversationContext.containsKey('age')) {
        _waitingFor = 'age';
        return '🎂 Bạn có thể cho tôi biết tuổi của bạn không? 😊';
      }
      if (!_conversationContext.containsKey('gender')) {
        _waitingFor = 'gender';
        return '👤 Bạn là nam hay nữ để tôi tính chính xác hơn? 😊';
      }
      if (!_conversationContext.containsKey('activity')) {
        _waitingFor = 'activity';
        return '''
🏃 Bạn có thường xuyên vận động không?

Chọn một trong các mức sau:
• **Ít vận động** - ngồi văn phòng, ít vận động
• **Nhẹ** - tập 1-3 buổi/tuần
• **Trung bình** - tập 3-5 buổi/tuần  
• **Nhiều** - tập 6-7 buổi/tuần
• **Rất nhiều** - vận động viên chuyên nghiệp

Hãy cho tôi biết mức độ của bạn nhé! 😊
''';
      }
    }

    return _showHelp();
  }

  /// Thử tính toán chỉ số đang pending
  String _tryCalculatePendingMetric() {
    // Các hàm _calculate*WithContext() sẽ tự reset state khi tính xong
    // hoặc giữ nguyên state nếu còn thiếu thông tin
    if (_pendingCalculation == 'bmi') {
      return _calculateBMIWithContext();
    } else if (_pendingCalculation == 'bmr') {
      return _calculateBMRWithContext();
    } else if (_pendingCalculation == 'tdee') {
      return _calculateTDEEWithContext();
    }

    return _showHelp();
  }

  /// Tính cả 3 chỉ số
  String _calculateAllMetrics() {
    final bmi = _calculateBMIWithContext();
    final bmr = _calculateBMRWithContext();
    final tdee = _calculateTDEEWithContext();

    _pendingCalculation = null;
    _waitingFor = null;

    return '''
$bmi

---

$bmr

---

$tdee

Chúc bạn có một cơ thể khỏe mạnh! 💪😊
''';
  }

  /// Xử lý tính BMI với khả năng hỏi lại
  String _handleBMICalculation(String originalMsg, String normalizedMsg) {
    // Parse thông tin từ tin nhắn
    final weightHeight = _extractWeightAndHeight(normalizedMsg);
    final age = _extractAge(normalizedMsg);

    // Cập nhật context
    if (weightHeight['weight'] != null) {
      _conversationContext['weight'] = weightHeight['weight'];
    }
    if (weightHeight['height'] != null) {
      _conversationContext['height'] = weightHeight['height'];
    }
    if (age != null) {
      _conversationContext['age'] = age;
    }

    // Detect gender
    if (_containsAny(normalizedMsg, ['nu', 'chi', 'co', 'female', 'woman'])) {
      _conversationContext['gender'] = 'nữ';
    } else if (_containsAny(normalizedMsg, ['nam', 'male', 'man', 'anh'])) {
      _conversationContext['gender'] = 'nam';
    }

    // Kiểm tra đủ thông tin chưa
    if (!_conversationContext.containsKey('weight') ||
        !_conversationContext.containsKey('height')) {
      _pendingCalculation = 'bmi';
      return _askForMissingInformation();
    }

    return _calculateBMIWithContext();
  }

  /// Tính BMI với context đã có
  String _calculateBMIWithContext() {
    if (!_conversationContext.containsKey('weight') ||
        !_conversationContext.containsKey('height')) {
      // Chưa đủ thông tin, set pending và hỏi lại
      _pendingCalculation = 'bmi';
      return _askForMissingInformation();
    }

    double weight = _conversationContext['weight'];
    double height = _conversationContext['height'];

    // Convert height to m if needed
    if (height > 3) {
      height = height / 100;
    }

    final bmi = _calculator.calculateBMI(weight: weight, height: height);

    String gender = _conversationContext['gender'] ?? 'nam';
    int age = _conversationContext['age'] ?? 25;

    final analysis = _calculator.analyzeBMI(bmi: bmi, gender: gender, age: age);

    // Đã tính xong → Reset pending state
    _pendingCalculation = null;
    _waitingFor = null;

    return '''
📊 **KẾT QUẢ TÍNH BMI**

🔢 Chỉ số BMI của bạn: **${bmi.toStringAsFixed(1)}**

📋 Phân loại: **${analysis['category']}**

💡 Mô tả: ${analysis['description']}

✅ Khuyến nghị: ${analysis['recommendation']}

${analysis['note'] != null ? '📌 Lưu ý: ${analysis['note']}\n' : ''}
Bạn cần tư vấn thêm về chế độ tập luyện hoặc dinh dưỡng không? 😊
''';
  }

  /// Xử lý tính BMR với khả năng hỏi lại
  String _handleBMRCalculation(String originalMsg, String normalizedMsg) {
    // Parse thông tin từ tin nhắn
    final weightHeight = _extractWeightAndHeight(normalizedMsg);
    final age = _extractAge(normalizedMsg);

    // Cập nhật context
    if (weightHeight['weight'] != null) {
      _conversationContext['weight'] = weightHeight['weight'];
    }
    if (weightHeight['height'] != null) {
      _conversationContext['height'] = weightHeight['height'];
    }
    if (age != null) {
      _conversationContext['age'] = age;
    }

    // Detect gender
    if (_containsAny(normalizedMsg, ['nu', 'chi', 'co', 'female', 'woman'])) {
      _conversationContext['gender'] = 'nữ';
    } else if (_containsAny(normalizedMsg, ['nam', 'male', 'man', 'anh'])) {
      _conversationContext['gender'] = 'nam';
    }

    // Kiểm tra đủ thông tin chưa
    if (!_conversationContext.containsKey('weight') ||
        !_conversationContext.containsKey('height') ||
        !_conversationContext.containsKey('age') ||
        !_conversationContext.containsKey('gender')) {
      _pendingCalculation = 'bmr';
      return _askForMissingInformation();
    }

    return _calculateBMRWithContext();
  }

  /// Tính BMR với context đã có
  String _calculateBMRWithContext() {
    if (!_conversationContext.containsKey('weight') ||
        !_conversationContext.containsKey('height') ||
        !_conversationContext.containsKey('age') ||
        !_conversationContext.containsKey('gender')) {
      // Chưa đủ thông tin, set pending và hỏi lại
      _pendingCalculation = 'bmr';
      return _askForMissingInformation();
    }

    double weight = _conversationContext['weight'];
    double height = _conversationContext['height'];
    int age = _conversationContext['age'];
    String gender = _conversationContext['gender'];

    // Convert height to cm if needed
    if (height < 3) {
      height = height * 100;
    }

    final bmr = _calculator.calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );

    final analysis = _calculator.analyzeBMR(bmr: bmr, gender: gender, age: age);

    // Đã tính xong → Reset pending state
    _pendingCalculation = null;
    _waitingFor = null;

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

  /// Xử lý tính TDEE với khả năng hỏi lại
  String _handleTDEECalculation(String originalMsg, String normalizedMsg) {
    // Parse thông tin từ tin nhắn
    final weightHeight = _extractWeightAndHeight(normalizedMsg);
    final age = _extractAge(normalizedMsg);

    // Cập nhật context
    if (weightHeight['weight'] != null) {
      _conversationContext['weight'] = weightHeight['weight'];
    }
    if (weightHeight['height'] != null) {
      _conversationContext['height'] = weightHeight['height'];
    }
    if (age != null) {
      _conversationContext['age'] = age;
    }

    // Detect gender
    if (_containsAny(normalizedMsg, ['nu', 'chi', 'co', 'female', 'woman'])) {
      _conversationContext['gender'] = 'nữ';
    } else if (_containsAny(normalizedMsg, ['nam', 'male', 'man', 'anh'])) {
      _conversationContext['gender'] = 'nam';
    }

    // Detect activity level
    if (_containsAny(normalizedMsg, [
      'it van dong',
      'khong tap',
      'sedentary',
      'ngoi nhieu',
    ])) {
      _conversationContext['activity'] = 'sedentary';
    } else if (_containsAny(normalizedMsg, [
      'tap nhe',
      'van dong nhe',
      'light',
      '1-3 buoi',
    ])) {
      _conversationContext['activity'] = 'light';
    } else if (_containsAny(normalizedMsg, [
      'tap vua',
      'van dong vua',
      'moderate',
      '3-5 buoi',
      'trung binh',
    ])) {
      _conversationContext['activity'] = 'moderate';
    } else if (_containsAny(normalizedMsg, [
      'tap nang',
      'van dong nang',
      'very active',
      '6-7 buoi',
      'nhieu',
    ])) {
      _conversationContext['activity'] = 'very_active';
    } else if (_containsAny(normalizedMsg, [
      'rat nang',
      'cuc nang',
      'extra',
      'vdv',
    ])) {
      _conversationContext['activity'] = 'extra_active';
    }

    // Kiểm tra đủ thông tin chưa
    if (!_conversationContext.containsKey('weight') ||
        !_conversationContext.containsKey('height') ||
        !_conversationContext.containsKey('age') ||
        !_conversationContext.containsKey('gender') ||
        !_conversationContext.containsKey('activity')) {
      _pendingCalculation = 'tdee';
      return _askForMissingInformation();
    }

    return _calculateTDEEWithContext();
  }

  /// Tính TDEE với context đã có
  String _calculateTDEEWithContext() {
    if (!_conversationContext.containsKey('weight') ||
        !_conversationContext.containsKey('height') ||
        !_conversationContext.containsKey('age') ||
        !_conversationContext.containsKey('gender') ||
        !_conversationContext.containsKey('activity')) {
      // Chưa đủ thông tin, set pending và hỏi lại
      _pendingCalculation = 'tdee';
      return _askForMissingInformation();
    }

    double weight = _conversationContext['weight'];
    double height = _conversationContext['height'];
    int age = _conversationContext['age'];
    String gender = _conversationContext['gender'];
    String activityLevel = _conversationContext['activity'];

    // Convert height to cm if needed
    if (height < 3) {
      height = height * 100;
    }

    final bmr = _calculator.calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );

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

    // Đã tính xong → Reset pending state
    _pendingCalculation = null;
    _waitingFor = null;

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
