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

  // Lưu kết quả tìm kiếm để hiển thị thêm
  List<Map<String, dynamic>> _lastSearchResults = [];
  int _lastDisplayCount = 0;
  String _lastSearchType = ''; // 'nutrition', 'exercise'

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
    final intent = _detectIntent(userMessage, normalizedMsg);
    print('   Intent: $intent');

    switch (intent) {
      case 'calculate_bmi':
        return _handleBMICalculation(userMessage, normalizedMsg);
      case 'calculate_bmr':
        return _handleBMRCalculation(userMessage, normalizedMsg);
      case 'calculate_tdee':
        return _handleTDEECalculation(userMessage, normalizedMsg);
      case 'show_more':
        return _handleShowMore();
      case 'ask_exercise':
        return _handleExerciseQuery(normalizedMsg);
      case 'ask_nutrition':
        return _handleNutritionQuery(normalizedMsg);
      case 'ask_membership':
        return _handleMembershipQuery(normalizedMsg);
      case 'ask_membership_detail':
        return _handleMembershipDetailQuery(normalizedMsg);
      case 'ask_workout_schedule':
        return _handleWorkoutScheduleQuery(normalizedMsg);
      case 'thank_you':
        return _handleThankYou();
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
  String _detectIntent(String originalMsg, String normalizedMsg) {
    print('   [Intent Detection Start]');
    print('   - Original: "$originalMsg"');
    print('   - Normalized: "$normalizedMsg"');

    // Show more results - CHECK TRƯỚC để không bị greeting chặn
    final lowerMsg = originalMsg.toLowerCase().trim();

    print('   [Show More Check]');
    print('   - Original: "$originalMsg"');
    print('   - Normalized: "$normalizedMsg"');
    print('   - Lower: "$lowerMsg"');

    // Check "hiện thêm" hoặc "xem thêm" bằng cách check cả 2 từ
    final hasHienThem =
        (normalizedMsg.contains('hien') && normalizedMsg.contains('them')) ||
        (lowerMsg.contains('hiện') && lowerMsg.contains('thêm'));
    final hasXemThem =
        (normalizedMsg.contains('xem') && normalizedMsg.contains('them')) ||
        (lowerMsg.contains('xem') && lowerMsg.contains('thêm'));

    // Nếu user chỉ gõ "thêm" hoặc "them" một mình - cũng hiểu là "hiện thêm"
    final justThem =
        (normalizedMsg.trim() == 'them' || lowerMsg.trim() == 'thêm');

    print('   - hasHienThem: $hasHienThem');
    print('   - hasXemThem: $hasXemThem');
    print('   - justThem: $justThem');

    if (hasHienThem ||
        hasXemThem ||
        justThem ||
        normalizedMsg.contains('show more') ||
        normalizedMsg.contains('tiep') ||
        lowerMsg.contains('tiếp') ||
        normalizedMsg.contains('nua') ||
        lowerMsg.contains('nữa') ||
        normalizedMsg.contains('con nua') ||
        lowerMsg.contains('còn nữa') ||
        normalizedMsg.trim() == 'more') {
      print('   ✅ MATCHED show_more!');
      return 'show_more';
    }

    // Thank you - Check TRƯỚC greeting để ưu tiên
    if (_containsAny(normalizedMsg, [
      'cam on',
      'thank',
      'thanks',
      'thank you',
      'thanks you',
      'cam on ban',
      'cam on nhieu',
      'cam on ai',
      'cam on chatbot',
      'cam on gym pro',
      'thank u',
      'ty',
      'tks',
      'ok cam on',
      'duoc roi cam on',
      'tot qua cam on',
    ])) {
      return 'thank_you';
    }

    // Greeting - Check SAU show_more và thank_you để không bị conflict
    if (_containsAny(normalizedMsg, [
      'xin chao',
      'chao',
      'hello',
      'hi',
      'hey',
      'alo',
      'alô',
    ])) {
      print('   ✅ MATCHED greeting');
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

    // Exercise queries - Mở rộng để bao gồm các mục tiêu tập luyện
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
      'giam can', // mục tiêu giảm cân
      'tang co', // mục tiêu tăng cơ
      'cardio', // bài tập cardio
      'suc manh', // tăng sức mạnh
      'dot mo', // đốt mỡ
      'phat trien', // phát triển cơ
      'bap', // các nhóm cơ có chữ bắp
      'squat',
      'push',
      'pull',
      'deadlift',
      'press',
    ])) {
      return 'ask_exercise';
    }

    // Nutrition queries - Mở rộng để bao gồm tìm kiếm theo giá
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
      'gia re', // tìm theo giá
      'binh dan',
      'tiet kiem',
      'dat',
      'cao cap',
      'trai cay', // loại món
      'rau cu',
      'thuc vat',
      'dong vat',
      'giu dang', // mục đích
      'phu hop',
    ])) {
      return 'ask_nutrition';
    }

    // Membership detail query - Hỏi chi tiết về một gói cụ thể
    if (_containsAny(normalizedMsg, [
          'thong tin goi',
          'chi tiet goi',
          'thong tin the',
          'chi tiet the',
        ]) ||
        (_containsAny(normalizedMsg, ['thong tin', 'chi tiet']) &&
            _containsAny(normalizedMsg, [
              'vip',
              'premium',
              'member',
              'co ban',
              'hoi vien',
            ]))) {
      return 'ask_membership_detail';
    }

    // Membership queries - Mở rộng để nhận diện nhiều ngữ cảnh hơn
    if (_containsAny(normalizedMsg, [
      'the tap',
      'goi tap',
      'membership',
      'hoi vien',
      'premium',
      'vip',
      'gia the',
      'bao nhieu tien',
      'chi phi',
      'ngay',
      'thang',
      'nam',
      'tu van the',
      'nen mua',
      'chon the',
      'gia re',
      're nhat',
      'tot nhat',
      'phu hop',
      'tap lau dai',
      'tap ngan han',
      'trai nghiem',
      'moi bat dau',
      'dau tien',
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

    // Phát hiện số lượng bài tập người dùng muốn xem
    int? requestedCount = _extractExerciseCount(msg);

    // Tìm kiếm bài tập theo từ khóa
    List<String> keywords = [];

    // Mục tiêu tập luyện
    List<String> goals = [];
    if (_containsAny(msg, ['giam can', 'diet', 'burn fat', 'dot mo'])) {
      goals.add('giảm cân');
    }
    if (_containsAny(msg, [
      'tang co',
      'build muscle',
      'phat trien co',
      'muscle gain',
    ])) {
      goals.add('tăng cơ');
    }
    if (_containsAny(msg, ['cardio', 'tim mach', 'the luc', 'endurance'])) {
      goals.add('cardio');
    }
    if (_containsAny(msg, ['suc manh', 'strength', 'luc', 'power'])) {
      goals.add('sức mạnh');
    }

    // Nhóm cơ chính xác hơn
    if (_containsAny(msg, ['nguc', 'chest', 'pec'])) keywords.add('ngực');
    if (_containsAny(msg, ['lung', 'back', 'xo', 'lat'])) keywords.add('lưng');
    if (_containsAny(msg, ['vai', 'shoulder', 'deltoid', 'delt']))
      keywords.add('vai');
    if (_containsAny(msg, ['tay truoc', 'bicep', 'bap tay']))
      keywords.add('bicep');
    if (_containsAny(msg, ['tay sau', 'tricep'])) keywords.add('tricep');
    if (_containsAny(msg, ['tay', 'arm']) &&
        !_containsAny(msg, ['chan', 'leg'])) {
      keywords.add('tay');
    }
    if (_containsAny(msg, ['chan', 'leg', 'dui', 'thigh', 'squat']))
      keywords.add('chân');
    if (_containsAny(msg, ['bung', 'abs', 'core', 'six pack']))
      keywords.add('bụng');
    if (_containsAny(msg, ['mong', 'glute', 'hip', 'butt']))
      keywords.add('mông');
    if (_containsAny(msg, ['bap chan', 'calf', 'calves']))
      keywords.add('bắp chân');
    if (_containsAny(msg, ['can tay', 'forearm'])) keywords.add('cẳng tay');

    // Độ khó
    String difficulty = '';
    if (_containsAny(msg, ['de', 'moi', 'beginner', 'nguoi moi']))
      difficulty = 'Dễ';
    if (_containsAny(msg, ['trung binh', 'intermediate', 'vua'])) {
      difficulty = 'Trung bình';
    }
    if (_containsAny(msg, ['kho', 'nang cao', 'advanced', 'chuyen nghiep'])) {
      difficulty = 'Khó';
    }

    // Dụng cụ
    List<String> equipment = [];
    if (_containsAny(msg, [
      'khong dung cu',
      'bodyweight',
      'tai nha',
      'no equipment',
    ])) {
      equipment.add('không');
    }
    if (_containsAny(msg, ['ta tay', 'dumbbell', 'ta']))
      equipment.add('tạ tay');
    if (_containsAny(msg, ['ta don', 'barbell', 'thanh ta']))
      equipment.add('thanh tạ');
    if (_containsAny(msg, ['may', 'machine'])) equipment.add('máy');

    List<Map<String, dynamic>> matchedExercises = [];

    for (var ex in exercises) {
      bool matches = false;
      int matchScore = 0; // Điểm phù hợp - càng cao càng liên quan

      // Kiểm tra nhóm cơ
      if (keywords.isNotEmpty) {
        for (var keyword in keywords) {
          final exName = _normalizeText(ex['tenBaiTap'] ?? '');
          final exGroup = _normalizeText(ex['nhomCoChinh'] ?? '');
          final normalizedKeyword = _normalizeText(keyword);

          if (exName.contains(normalizedKeyword) ||
              exGroup.contains(normalizedKeyword)) {
            matches = true;
            matchScore += 3; // Điểm cao cho khớp nhóm cơ
            break;
          }
        }
      }

      // Kiểm tra độ khó
      if (difficulty.isNotEmpty) {
        if (ex['doKho'] == difficulty) {
          matches = keywords.isEmpty
              ? true
              : matches; // Nếu chưa match thì mới set true
          matchScore += 2;
        } else if (keywords.isNotEmpty && matches) {
          matchScore -= 1; // Trừ điểm nếu không đúng độ khó
        }
      }

      // Kiểm tra mục tiêu
      if (goals.isNotEmpty) {
        final exGoals =
            (ex['mucTieu'] as List?)
                ?.map((e) => _normalizeText(e.toString()))
                .toList() ??
            [];
        final exDescription = _normalizeText(ex['moTa'] ?? '');

        for (var goal in goals) {
          final normalizedGoal = _normalizeText(goal);
          if (exGoals.any((g) => g.contains(normalizedGoal)) ||
              exDescription.contains(normalizedGoal)) {
            matches = true;
            matchScore += 2;
            break;
          }
        }
      }

      // Kiểm tra dụng cụ
      if (equipment.isNotEmpty) {
        final exEquipment = _normalizeText(ex['dungCu'] ?? '');
        for (var eq in equipment) {
          final normalizedEq = _normalizeText(eq);
          if (exEquipment.contains(normalizedEq) ||
              (normalizedEq == 'khong' &&
                  exEquipment.contains('khong can dung cu'))) {
            matchScore += 1;
            matches = true;
            break;
          }
        }
      }

      // Nếu không có filter cụ thể, hiện tất cả
      if (keywords.isEmpty &&
          difficulty.isEmpty &&
          goals.isEmpty &&
          equipment.isEmpty) {
        matches = true;
        matchScore = 1;
      }

      if (matches) {
        matchedExercises.add({
          'exercise': ex as Map<String, dynamic>,
          'score': matchScore,
        });
      }
    }

    // Sắp xếp theo điểm phù hợp
    matchedExercises.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    if (matchedExercises.isEmpty) {
      return '''
Xin lỗi, tôi không tìm thấy bài tập phù hợp với yêu cầu của bạn.

💪 **Bạn có thể hỏi về:**
- **Nhóm cơ:** ngực, lưng, vai, tay, chân, bụng, mông
- **Độ khó:** dễ, trung bình, khó
- **Mục tiêu:** giảm cân, tăng cơ, cardio, sức mạnh
- **Số lượng:** 1 bài tập, 2 bài tập, 3 bài tập...

📝 **Ví dụ câu hỏi:**
- "Các bài tập chân"
- "1 bài tập chân dễ"
- "Chọn 2 bài tập ngực"
- "Bài tập giảm cân"
- "Bài tập tăng cơ vai"

Hãy thử lại nhé! 😊
''';
    }

    // Lưu kết quả để có thể hiển thị thêm sau
    _lastSearchResults = matchedExercises;
    _lastSearchType = 'exercise';

    // Xác định số lượng bài tập cần hiển thị
    int displayCount;
    if (requestedCount != null) {
      // Người dùng yêu cầu số lượng cụ thể
      displayCount = requestedCount;
    } else if (_containsAny(msg, [
      'cac bai tap',
      'tat ca',
      'all',
      'goi y',
      'nhieu',
    ])) {
      // Người dùng muốn xem nhiều bài
      displayCount = 5;
    } else if (keywords.isNotEmpty && difficulty.isEmpty && goals.isEmpty) {
      // Chỉ hỏi về nhóm cơ → hiện nhiều bài
      displayCount = 5;
    } else {
      // Mặc định hiển thị 3 bài
      displayCount = 3;
    }

    // Save display count for "show more"
    _lastDisplayCount = displayCount;

    final displayExercises = matchedExercises.take(displayCount).toList();

    String response = '';

    // Tiêu đề phù hợp
    if (requestedCount == 1) {
      response = '💪 **BÀI TẬP PHÙ HỢP**\n\n';
    } else if (requestedCount != null && requestedCount > 1) {
      response = '💪 **${requestedCount} BÀI TẬP PHÙ HỢP**\n\n';
    } else if (keywords.isNotEmpty) {
      response = '💪 **BÀI TẬP ${keywords.first.toUpperCase()}**\n\n';
    } else if (goals.isNotEmpty) {
      response = '💪 **BÀI TẬP ${goals.first.toUpperCase()}**\n\n';
    } else {
      response = '💪 **GỢI Ý BÀI TẬP**\n\n';
    }

    for (var i = 0; i < displayExercises.length; i++) {
      final ex = displayExercises[i]['exercise'] as Map<String, dynamic>;
      response +=
          '''
${i + 1}. **${ex['tenBaiTap']}**
   📍 Nhóm cơ: ${ex['nhomCoChinh']}
   ${(ex['nhomCoPhu'] as List?)?.isNotEmpty == true ? '➕ Nhóm cơ phụ: ${(ex['nhomCoPhu'] as List).join(', ')}\n   ' : ''}🔧 Dụng cụ: ${ex['dungCu']}
   📊 Độ khó: ${ex['doKho']}
   � Đối tượng: ${(ex['doiTuong'] as List?)?.join(', ') ?? 'Phù hợp mọi đối tượng'}
   🎯 Mục tiêu: ${(ex['mucTieu'] as List?)?.join(', ') ?? 'Tăng cường thể lực'}
   
   �💡 **Cách tập:** ${ex['cachTap']}
   
   ✅ **Lợi ích:** ${ex['moTa']}

''';
    }

    if (matchedExercises.length > displayCount) {
      response +=
          '📌 Còn ${matchedExercises.length - displayCount} bài tập khác phù hợp. Nói "hiện thêm" để xem tiếp!\n\n';
    }

    response += '💬 Bạn muốn biết chi tiết hơn về bài tập nào không? 😊';

    return response;
  }

  /// Trích xuất số lượng bài tập từ câu hỏi
  int? _extractExerciseCount(String msg) {
    // Tìm số trong câu hỏi
    final numbers = {
      'mot': 1,
      '1': 1,
      'một': 1,
      'hai': 2,
      '2': 2,
      'ba': 3,
      '3': 3,
      'bon': 4,
      '4': 4,
      'bốn': 4,
      'nam': 5,
      '5': 5,
      'năm': 5,
    };

    for (var entry in numbers.entries) {
      if (msg.contains(entry.key) &&
          (_containsAny(msg, ['bai tap', 'bai', 'exercise']))) {
        return entry.value;
      }
    }

    // Tìm pattern "X bài"
    final match = RegExp(r'(\d+)\s*bai').firstMatch(msg);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }

    return null;
  }

  /// Xử lý yêu cầu "hiện thêm" - hiển thị thêm kết quả từ tìm kiếm trước đó
  String _handleShowMore() {
    // Kiểm tra có kết quả trước đó không
    if (_lastSearchResults.isEmpty) {
      return '''
❌ **CHƯA CÓ KẾT QUẢ TÌM KIẾM**

Bạn chưa tìm kiếm gì cả. Hãy tìm kiếm món ăn hoặc bài tập trước khi dùng "hiện thêm" nhé! 😊

💡 **Gợi ý:**
- Tìm bài tập: "các bài tập chân", "bài tập ngực"
- Tìm món ăn: "món ăn giảm cân", "thức ăn nhiều protein"
''';
    }

    // Lấy các item tiếp theo
    final remainingItems = _lastSearchResults.skip(_lastDisplayCount).toList();

    if (remainingItems.isEmpty) {
      return '''
✅ **ĐÃ HIỂN THỊ HẾT**

Bạn đã xem hết tất cả ${_lastSearchResults.length} kết quả phù hợp rồi! 😊

💬 Hãy tìm kiếm với từ khóa khác để xem thêm nhé!
''';
    }

    // Hiển thị tối đa 5 item tiếp theo
    final nextBatch = remainingItems.take(5).toList();
    final newDisplayCount = _lastDisplayCount + nextBatch.length;

    String response = '';

    // Hiển thị theo loại (bài tập hoặc món ăn)
    if (_lastSearchType == 'exercise') {
      response = '💪 **THÊM BÀI TẬP PHÙ HỢP**\n\n';

      for (var i = 0; i < nextBatch.length; i++) {
        final ex = nextBatch[i]['exercise'] as Map<String, dynamic>;
        response +=
            '''
${_lastDisplayCount + i + 1}. **${ex['tenBaiTap']}**
   📍 Nhóm cơ: ${ex['nhomCoChinh']}
   ${(ex['nhomCoPhu'] as List?)?.isNotEmpty == true ? '➕ Nhóm cơ phụ: ${(ex['nhomCoPhu'] as List).join(', ')}\n   ' : ''}🔧 Dụng cụ: ${ex['dungCu']}
   📊 Độ khó: ${ex['doKho']}
   👤 Đối tượng: ${(ex['doiTuong'] as List?)?.join(', ') ?? 'Phù hợp mọi đối tượng'}
   🎯 Mục tiêu: ${(ex['mucTieu'] as List?)?.join(', ') ?? 'Tăng cường thể lực'}
   
   💡 **Cách tập:** ${ex['cachTap']}
   
   ✅ **Lợi ích:** ${ex['moTa']}

''';
      }
    } else if (_lastSearchType == 'nutrition') {
      response = '🍽️ **THÊM MÓN ĂN PHÙ HỢP**\n\n';

      for (var i = 0; i < nextBatch.length; i++) {
        final food = nextBatch[i]['food'] as Map<String, dynamic>;
        final score = nextBatch[i]['score'] as int;

        response +=
            '''
${_lastDisplayCount + i + 1}. **${food['ten_mon']}** ${score >= 10
                ? '⭐'
                : score >= 7
                ? '✨'
                : ''}
   💰 Giá: **${food['gia'] ?? 'N/A'}**
   � Năng lượng: ${food['nang_luong_kcal']} kcal/100g
   💪 Protein: ${food['dam_g']}g | 🍚 Carb: ${food['carb_g']}g | 🥑 Béo: ${food['beo_g']}g
   🌾 Chất xơ: ${food['chat_xo_g'] ?? 0}g
   ${food['phu_hop_voi'] != null ? '� Phù hợp: ${food['phu_hop_voi']}\n   ' : ''}✅ ${food['loi_ich']}

''';
      }
    } else if (_lastSearchType == 'membership') {
      response = '💳 **THÊM GÓI THẺ TẬP**\n\n';

      for (var i = 0; i < nextBatch.length; i++) {
        final card = nextBatch[i];
        final price = card['gia'] as int;
        final duration = card['thoiLuong'] as int;
        final unit = card['donViThoiLuong'] as String;

        // Tính giá theo ngày
        int totalDays = duration;
        if (unit == 'tháng') {
          totalDays = duration * 30;
        } else if (unit == 'năm') {
          totalDays = duration * 365;
        }
        final pricePerDay = (price / totalDays).round();

        response +=
            '''
${_lastDisplayCount + i + 1}. ✨ **${card['tenGoi']}** 
   💰 Giá: ${_formatCurrency(price)} (≈ ${_formatCurrency(pricePerDay)}/ngày)
   ⏱ Thời hạn: **$duration $unit**
   📋 Loại: ${_getCardTypeBadge(card['loaiGoi'])}
   
   📝 ${card['moTa']}
   
   🎯 **Phù hợp cho:** ${card['phuHopCho']}
   🏋️ **Mục tiêu:** ${card['mucTieuTapLuyen']}
   
   ✅ **Quyền lợi:**
${(card['loiIch'] as List).map((e) => '      • $e').join('\n')}

─────────────────────
''';
      }
    }

    // Cập nhật số lượng đã hiển thị
    _lastDisplayCount = newDisplayCount;

    // Thông báo còn bao nhiêu item nữa
    final remaining = _lastSearchResults.length - newDisplayCount;
    if (remaining > 0) {
      response +=
          '📌 Còn $remaining kết quả khác. Nói "hiện thêm" để xem tiếp! 😊\n\n';
    } else {
      response +=
          '✅ Đã hiển thị hết ${_lastSearchResults.length} kết quả phù hợp!\n\n';
    }

    // Thông điệp khác nhau tùy loại
    if (_lastSearchType == 'membership') {
      response +=
          '💬 Bạn muốn biết thêm về gói nào? Hỏi "thông tin gói [tên gói]" nhé! 😊';
    } else {
      response +=
          '💬 Bạn muốn biết chi tiết hơn về ${_lastSearchType == 'exercise' ? 'bài tập' : 'món ăn'} nào không? 😊';
    }

    return response;
  }

  /// Xử lý câu hỏi về dinh dưỡng
  String _handleNutritionQuery(String msg) {
    final nutrition = _dataService.nutritionData['nutrition'] as List? ?? [];

    List<Map<String, dynamic>> matchedFoods = [];

    // Phát hiện context - nếu có từ liên quan đồ ăn + giá thì tự hiểu
    bool hasFoodContext = _containsAny(msg, [
      'mon',
      'mon an',
      'do an',
      'thuc pham',
      'rau',
      'cu',
      'qua',
      'trai cay',
      'thit',
      'ca',
      'tom',
      'ga',
      'heo',
      'bo',
      'com',
      'mi',
      'bun',
      'pho',
      'trung',
      'sua',
      'dau',
      'an',
      'an gi',
      'thuc don',
    ]);

    // Tìm kiếm theo giá - linh hoạt hơn
    String? priceFilter;
    if (_containsAny(msg, ['re', 'gia re', 'tiet kiem', 'cheap', 'rẻ'])) {
      priceFilter = 'rẻ';
    } else if (_containsAny(msg, [
      'binh dan',
      'vua tui',
      'affordable',
      'phai chang',
    ])) {
      priceFilter = 'bình dân';
    } else if (_containsAny(msg, [
      'trung binh',
      'gia trung binh',
      'vua phai',
    ])) {
      priceFilter = 'trung bình';
    } else if (_containsAny(msg, [
      'dat',
      'cao cap',
      'expensive',
      'tuong doi dat',
      'gia cao',
    ])) {
      priceFilter = 'tương đối đắt';
    }

    // Tìm theo loại món - mở rộng
    List<String> foodTypes = [];
    if (_containsAny(msg, [
      'thuc vat',
      'rau',
      'cu',
      'chay',
      'vegetarian',
      'rau cu',
    ])) {
      if (!foodTypes.contains('Thực vật')) foodTypes.add('Thực vật');
    }
    if (_containsAny(msg, [
      'dong vat',
      'thit',
      'ca',
      'meat',
      'animal',
      'hai san',
      'tom',
      'ga',
      'heo',
      'bo',
    ])) {
      if (!foodTypes.contains('Động vật')) foodTypes.add('Động vật');
    }
    if (_containsAny(msg, ['trai cay', 'qua', 'fruit', 'hoa qua'])) {
      if (!foodTypes.contains('Trái cây')) foodTypes.add('Trái cây');
    }
    if (_containsAny(msg, ['hon hop', 'ket hop', 'mix'])) {
      if (!foodTypes.contains('Hỗn hợp')) foodTypes.add('Hỗn hợp');
    }

    // Tìm theo dinh dưỡng cụ thể - chi tiết hơn
    bool highProtein = _containsAny(msg, [
      'nhieu protein',
      'giau protein',
      'protein cao',
      'nhieu dam',
    ]);
    bool lowProtein = _containsAny(msg, ['it protein', 'protein thap']);

    bool highCarb = _containsAny(msg, [
      'nhieu carb',
      'giau carb',
      'nhieu tinh bot',
      'carb cao',
    ]);
    bool lowCarb = _containsAny(msg, [
      'it carb',
      'carb thap',
      'low carb',
      'it tinh bot',
    ]);

    bool highCal = _containsAny(msg, [
      'nhieu calo',
      'nhieu kcal',
      'calo cao',
      'tang can',
    ]);
    bool lowCal = _containsAny(msg, [
      'it calo',
      'it kcal',
      'calo thap',
      'low cal',
      'giam can',
    ]);

    bool highFiber = _containsAny(msg, [
      'nhieu chat xo',
      'giau chat xo',
      'fiber',
    ]);
    bool lowFat = _containsAny(msg, [
      'it beo',
      'beo thap',
      'low fat',
      'khong beo',
    ]);
    bool highFat = _containsAny(msg, ['nhieu beo', 'giau beo']);

    // Tìm theo mục đích - mở rộng
    bool forWeightLoss = _containsAny(msg, [
      'giam can',
      'giu dang',
      'diet',
      'lose weight',
      'clean',
      'healthy',
    ]);
    bool forMuscleGain = _containsAny(msg, [
      'tang co',
      'muscle',
      'phat trien co',
      'build muscle',
      'gym',
    ]);
    bool forEnergy = _containsAny(msg, [
      'nang luong',
      'energy',
      'suc khoe',
      'the luc',
    ]);
    bool forBulking = _containsAny(msg, [
      'tang can',
      'bulking',
      'tang khoi luong',
    ]);

    // Phát hiện yêu cầu số lượng
    int? requestedCount = _extractFoodCount(msg);

    for (var food in nutrition) {
      bool matches = false;
      int matchScore = 0;

      final foodName = _normalizeText(food['ten_mon'] ?? '');
      final foodPrice = _normalizeText(food['gia'] ?? '');
      final foodType = _normalizeText(food['loai'] ?? '');
      final suitableFor = _normalizeText(food['phu_hop_voi'] ?? '');
      final benefit = _normalizeText(food['loi_ich'] ?? '');

      final calories = (food['nang_luong_kcal'] ?? 0) as num;
      final protein = (food['dam_g'] ?? 0) as num;
      final carb = (food['carb_g'] ?? 0) as num;
      final fat = (food['beo_g'] ?? 0) as num;
      final fiber = (food['chat_xo_g'] ?? 0) as num;

      // Tìm theo tên món - ưu tiên cao nhất
      if (foodName.contains(_normalizeText(msg)) && msg.length > 2) {
        matches = true;
        matchScore += 10;
      }

      // Tìm theo giá
      if (priceFilter != null) {
        if (foodPrice == _normalizeText(priceFilter)) {
          matches = true;
          matchScore += 5;
        } else {
          // Nếu có filter giá mà không khớp thì trừ điểm
          matchScore -= 2;
        }
      }

      // Tìm theo loại - linh hoạt
      if (foodTypes.isNotEmpty) {
        bool typeMatches = false;
        for (var type in foodTypes) {
          if (foodType.contains(_normalizeText(type))) {
            typeMatches = true;
            matchScore += 3;
            break;
          }
        }
        if (typeMatches) {
          matches = true;
        } else if (priceFilter != null) {
          // Nếu có filter loại mà không khớp, không loại bỏ nhưng giảm điểm
          matchScore -= 1;
        }
      }

      // Tìm theo protein
      if (highProtein) {
        if (protein >= 20) {
          matches = true;
          matchScore += 4;
        } else if (protein >= 15) {
          matches = true;
          matchScore += 3;
        } else if (protein >= 10) {
          matches = true;
          matchScore += 1;
        }
      }
      if (lowProtein && protein < 5) {
        matches = true;
        matchScore += 3;
      }

      // Tìm theo carb
      if (highCarb) {
        if (carb >= 40) {
          matches = true;
          matchScore += 4;
        } else if (carb >= 25) {
          matches = true;
          matchScore += 3;
        } else if (carb >= 15) {
          matches = true;
          matchScore += 1;
        }
      }
      if (lowCarb && carb < 10) {
        matches = true;
        matchScore += 3;
      }

      // Tìm theo calo
      if (highCal) {
        if (calories >= 250) {
          matches = true;
          matchScore += 4;
        } else if (calories >= 180) {
          matches = true;
          matchScore += 3;
        } else if (calories >= 120) {
          matches = true;
          matchScore += 1;
        }
      }
      if (lowCal) {
        if (calories <= 50) {
          matches = true;
          matchScore += 4;
        } else if (calories <= 80) {
          matches = true;
          matchScore += 3;
        } else if (calories <= 100) {
          matches = true;
          matchScore += 1;
        }
      }

      // Tìm theo chất xơ
      if (highFiber && fiber >= 2) {
        matches = true;
        matchScore += 3;
      }

      // Tìm theo béo
      if (lowFat && fat <= 3) {
        matches = true;
        matchScore += 3;
      }
      if (highFat && fat >= 10) {
        matches = true;
        matchScore += 3;
      }

      // Tìm theo mục đích
      if (forWeightLoss) {
        if (suitableFor.contains('giam can') ||
            suitableFor.contains('giu dang')) {
          matches = true;
          matchScore += 4;
        } else if (calories < 100 && fiber >= 2) {
          matches = true;
          matchScore += 3;
        } else if (benefit.contains('giam can') ||
            benefit.contains('thanh loc')) {
          matches = true;
          matchScore += 2;
        }
      }

      if (forMuscleGain) {
        if (suitableFor.contains('tang co')) {
          matches = true;
          matchScore += 4;
        } else if (protein >= 15) {
          matches = true;
          matchScore += 3;
        } else if (benefit.contains('tang co') ||
            benefit.contains('phat trien co')) {
          matches = true;
          matchScore += 2;
        }
      }

      if (forEnergy) {
        if (suitableFor.contains('nang luong')) {
          matches = true;
          matchScore += 4;
        } else if (calories >= 150 || carb >= 20) {
          matches = true;
          matchScore += 2;
        }
      }

      if (forBulking) {
        if (calories >= 200 && (protein >= 10 || carb >= 20)) {
          matches = true;
          matchScore += 4;
        }
      }

      // Nếu chỉ có context về giá mà không có context đồ ăn, skip
      if (priceFilter != null && !hasFoodContext && !matches) {
        continue;
      }

      if (matches && matchScore > 0) {
        matchedFoods.add({
          'food': food as Map<String, dynamic>,
          'score': matchScore,
        });
      }
    }

    // Sắp xếp theo điểm
    matchedFoods.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    if (matchedFoods.isEmpty) {
      return '''
🥗 **TƯ VẤN DINH DƯỠNG**

Xin lỗi, tôi không tìm thấy món ăn phù hợp với yêu cầu của bạn.

💡 **Gợi ý câu hỏi:**

📊 **Theo dinh dưỡng:**
- "Món ăn nhiều protein" / "Món ăn ít calo"
- "Món ăn nhiều carb" / "Món ăn ít béo"
- "Món ăn giàu chất xơ"

💰 **Theo giá:**
- "Món ăn rẻ" / "Món ăn bình dân"
- "Rau củ rẻ" / "Thịt bình dân"
- "Trái cây giá rẻ"

🎯 **Theo mục tiêu:**
- "Món ăn giảm cân" / "Món ăn tăng cơ"
- "Món ăn tăng cân" / "Món ăn healthy"

🔥 **Kết hợp:**
- "Món ăn rẻ nhiều protein"
- "Món ăn bình dân giảm cân"
- "Trái cây ít calo giá rẻ"
- "Thịt nhiều protein bình dân"
- "Rau rẻ giàu chất xơ"

Hãy thử lại nhé! 😊
''';
    }

    // Lưu kết quả để có thể hiển thị thêm sau
    _lastSearchResults = matchedFoods;
    _lastSearchType = 'nutrition';

    // Xác định số lượng hiển thị
    int displayCount;
    if (requestedCount != null) {
      displayCount = requestedCount;
    } else if (_containsAny(msg, ['tat ca', 'all', 'nhieu'])) {
      displayCount = 10;
    } else {
      displayCount = 5;
    }

    _lastDisplayCount = displayCount;
    final displayFoods = matchedFoods.take(displayCount).toList();

    String response = '';

    // Tạo tiêu đề thông minh dựa trên filter
    List<String> filters = [];
    if (priceFilter != null) filters.add('giá $priceFilter');
    if (foodTypes.isNotEmpty) filters.add(foodTypes.join(', ').toLowerCase());
    if (highProtein) filters.add('nhiều protein');
    if (lowCal) filters.add('ít calo');
    if (highCal) filters.add('nhiều calo');
    if (highCarb) filters.add('nhiều carb');
    if (lowCarb) filters.add('ít carb');
    if (forWeightLoss) filters.add('giảm cân');
    if (forMuscleGain) filters.add('tăng cơ');

    if (filters.isNotEmpty) {
      response = '🥗 **MÓN ĂN: ${filters.join(' • ').toUpperCase()}**\n\n';
    } else {
      response = '🥗 **GỢI Ý DINH DƯỠNG**\n\n';
    }

    response += '🔍 Tìm thấy **${matchedFoods.length}** món phù hợp\n\n';

    for (var i = 0; i < displayFoods.length; i++) {
      final food = displayFoods[i]['food'] as Map<String, dynamic>;
      final score = displayFoods[i]['score'] as int;

      response +=
          '''
${i + 1}. **${food['ten_mon']}** ${score >= 10
              ? '⭐'
              : score >= 7
              ? '✨'
              : ''}
   💰 Giá: **${food['gia'] ?? 'N/A'}**
   📊 Năng lượng: ${food['nang_luong_kcal']} kcal/100g
   💪 Protein: ${food['dam_g']}g | 🍚 Carb: ${food['carb_g']}g | 🥑 Béo: ${food['beo_g']}g
   🌾 Chất xơ: ${food['chat_xo_g'] ?? 0}g
   ${food['phu_hop_voi'] != null ? '🎯 Phù hợp: ${food['phu_hop_voi']}\n   ' : ''}✅ ${food['loi_ich']}

''';
    }

    if (matchedFoods.length > displayCount) {
      response +=
          '📌 Còn **${matchedFoods.length - displayCount}** món khác. Hỏi cụ thể hơn hoặc nói "hiện thêm" để xem!\n\n';
    }

    // Gợi ý thêm
    response += '''

💡 **Tip:** Bạn có thể kết hợp nhiều điều kiện như:
   • "Rẻ mà nhiều protein"
   • "Trái cây ít calo"
   • "Thịt bình dân tăng cơ"
''';

    return response;
  }

  /// Trích xuất số lượng món ăn từ câu hỏi
  int? _extractFoodCount(String msg) {
    final numbers = {
      'mot': 1,
      '1': 1,
      'một': 1,
      'hai': 2,
      '2': 2,
      'ba': 3,
      '3': 3,
      'bon': 4,
      '4': 4,
      'bốn': 4,
      'nam': 5,
      '5': 5,
      'năm': 5,
      'sau': 6,
      '6': 6,
      'bay': 7,
      '7': 7,
      'bảy': 7,
      'tam': 8,
      '8': 8,
      'tám': 8,
      'chin': 9,
      '9': 9,
      'chín': 9,
      'muoi': 10,
      '10': 10,
      'mười': 10,
    };

    for (var entry in numbers.entries) {
      if (msg.contains(entry.key) &&
          (_containsAny(msg, ['mon', 'mon an', 'loai', 'option']))) {
        return entry.value;
      }
    }

    return null;
  }

  /// Xử lý câu hỏi về thẻ tập
  String _handleMembershipQuery(String msg) {
    final cards = _dataService.membershipData['cards'] as List? ?? [];

    if (cards.isEmpty) {
      return '❌ Xin lỗi, hiện tại chưa có thông tin về các gói thẻ tập.';
    }

    List<Map<String, dynamic>> allCards = cards.cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> matchedCards = [];

    // Phân tích ngữ cảnh để tư vấn phù hợp
    String? recommendationType;
    String reasonText = '';

    // 1. Lọc theo loại thẻ (vip, premium, cơ bản)
    if (_containsAny(msg, ['vip'])) {
      matchedCards = allCards
          .where((card) => card['loaiGoi'] == 'vip')
          .toList();
      recommendationType = 'VIP';
      reasonText = 'Bạn đang tìm gói VIP - dịch vụ cao cấp nhất 🌟';
    } else if (_containsAny(msg, ['premium', 'trung cap', 'nang cao'])) {
      matchedCards = allCards
          .where((card) => card['loaiGoi'] == 'premium')
          .toList();
      recommendationType = 'Premium';
      reasonText =
          'Bạn đang tìm gói Premium - cân bằng giữa giá và chất lượng 💪';
    } else if (_containsAny(msg, [
      'co ban',
      'member',
      'basic',
      'gia re',
      're nhat',
      'tiet kiem',
    ])) {
      matchedCards = allCards
          .where((card) => card['loaiGoi'] == 'member')
          .toList();
      recommendationType = 'Cơ bản';
      reasonText =
          'Bạn đang tìm gói cơ bản - phù hợp túi tiền, hiệu quả cao 💰';
    }

    // 2. Lọc theo thời gian nếu có
    if (_containsAny(msg, ['1 ngay', 'ngay', 'thu', 'trai nghiem'])) {
      matchedCards = matchedCards.isEmpty ? allCards : matchedCards;
      matchedCards = matchedCards
          .where((card) => card['donViThoiLuong'] == 'ngày')
          .toList();
      if (recommendationType == null) {
        recommendationType = 'Ngắn hạn';
        reasonText = 'Bạn muốn thử nghiệm hoặc tập ngắn hạn 🎯';
      }
    } else if (_containsAny(msg, ['1 tuan', 'tuan', '7 ngay'])) {
      matchedCards = matchedCards.isEmpty ? allCards : matchedCards;
      matchedCards = matchedCards
          .where(
            (card) =>
                card['thoiLuong'] == 7 && card['donViThoiLuong'] == 'ngày',
          )
          .toList();
      if (recommendationType == null) {
        recommendationType = '1 tuần';
        reasonText = 'Bạn muốn tập trong 1 tuần 📅';
      }
    } else if (_containsAny(msg, ['1 thang', 'thang'])) {
      matchedCards = matchedCards.isEmpty ? allCards : matchedCards;
      matchedCards = matchedCards
          .where(
            (card) =>
                card['thoiLuong'] == 1 && card['donViThoiLuong'] == 'tháng',
          )
          .toList();
      if (recommendationType == null) {
        recommendationType = '1 tháng';
        reasonText = 'Bạn muốn tập trong 1 tháng 📆';
      }
    } else if (_containsAny(msg, ['3 thang', 'quy'])) {
      matchedCards = matchedCards.isEmpty ? allCards : matchedCards;
      matchedCards = matchedCards
          .where(
            (card) =>
                card['thoiLuong'] == 3 && card['donViThoiLuong'] == 'tháng',
          )
          .toList();
      if (recommendationType == null) {
        recommendationType = '3 tháng';
        reasonText = 'Bạn muốn cam kết tập 3 tháng 💪';
      }
    } else if (_containsAny(msg, ['6 thang', 'nua nam'])) {
      matchedCards = matchedCards.isEmpty ? allCards : matchedCards;
      matchedCards = matchedCards
          .where(
            (card) =>
                card['thoiLuong'] == 6 && card['donViThoiLuong'] == 'tháng',
          )
          .toList();
      if (recommendationType == null) {
        recommendationType = '6 tháng';
        reasonText = 'Bạn muốn tập lâu dài 6 tháng 🎖';
      }
    } else if (_containsAny(msg, ['1 nam', 'nam', 'lau dai', '12 thang'])) {
      matchedCards = matchedCards.isEmpty ? allCards : matchedCards;
      matchedCards = matchedCards
          .where(
            (card) => card['thoiLuong'] >= 1 && card['donViThoiLuong'] == 'năm',
          )
          .toList();
      if (recommendationType == null) {
        recommendationType = 'Dài hạn';
        reasonText = 'Bạn muốn cam kết lâu dài 🏆';
      }
    }

    // 3. Lọc theo ngân sách
    if (_containsAny(msg, ['re nhat', 'gia re', 'tiet kiem', 'binh dan'])) {
      matchedCards = matchedCards.isEmpty ? allCards : matchedCards;
      matchedCards.sort((a, b) => (a['gia'] as int).compareTo(b['gia'] as int));
      matchedCards = matchedCards.take(3).toList();
      if (recommendationType == null) {
        recommendationType = 'Tiết kiệm';
        reasonText = 'Bạn đang tìm gói giá rẻ nhất 💰';
      }
    } else if (_containsAny(msg, ['tot nhat', 'uu dai', 'hieu qua'])) {
      matchedCards = matchedCards.isEmpty ? allCards : matchedCards;
      // Ưu tiên gói 3-6 tháng (tỷ lệ giá/ngày tốt nhất)
      matchedCards = matchedCards
          .where(
            (card) =>
                (card['thoiLuong'] == 3 || card['thoiLuong'] == 6) &&
                card['donViThoiLuong'] == 'tháng',
          )
          .toList();
      if (matchedCards.isEmpty) {
        matchedCards = allCards;
      }
      if (recommendationType == null) {
        recommendationType = 'Tốt nhất';
        reasonText = 'Bạn đang tìm gói tập hiệu quả, ưu đãi nhất ⭐';
      }
    }

    // 4. Nếu là người mới bắt đầu
    if (_containsAny(msg, [
      'moi bat dau',
      'moi tap',
      'lan dau',
      'chua biet',
      'nen chon',
    ])) {
      if (recommendationType == null) {
        // Gợi ý gói 1 ngày hoặc 7 ngày cho người mới
        matchedCards = allCards
            .where(
              (card) =>
                  card['loaiGoi'] == 'member' &&
                  (card['thoiLuong'] == 1 || card['thoiLuong'] == 7) &&
                  card['donViThoiLuong'] == 'ngày',
            )
            .toList();
        recommendationType = 'Người mới';
        reasonText =
            '🌟 Bạn mới bắt đầu? Tuyệt vời! Hãy thử gói ngắn hạn trước nhé!';
      }
    }

    // Nếu không có filter cụ thể, hiển thị top picks
    if (matchedCards.isEmpty) {
      // Hiển thị các gói phổ biến: 1 ngày, 1 tháng, 3 tháng, 1 năm
      final popularDurations = [
        {'duration': 1, 'unit': 'ngày'},
        {'duration': 7, 'unit': 'ngày'},
        {'duration': 1, 'unit': 'tháng'},
        {'duration': 3, 'unit': 'tháng'},
        {'duration': 1, 'unit': 'năm'},
      ];

      for (var duration in popularDurations) {
        final card = allCards.firstWhere(
          (c) =>
              c['thoiLuong'] == duration['duration'] &&
              c['donViThoiLuong'] == duration['unit'],
          orElse: () => {},
        );
        if (card.isNotEmpty) {
          matchedCards.add(card);
        }
      }

      if (matchedCards.isEmpty) {
        matchedCards = allCards.take(5).toList();
      }

      recommendationType = 'Gói phổ biến';
      reasonText = '📋 Đây là các gói thẻ phổ biến tại Gym Pro:';
    }

    // Tạo response
    String response = '💳 **TƯ VẤN GÓI THẺ TẬP GYM PRO**\n\n';
    response += '$reasonText\n\n';
    response += '─────────────────────\n\n';

    // Lưu kết quả để có thể "hiện thêm"
    _lastSearchResults = matchedCards;
    _lastDisplayCount = matchedCards.length > 3 ? 3 : matchedCards.length;
    _lastSearchType = 'membership';

    // Hiển thị tối đa 3 gói đầu tiên
    final displayCards = matchedCards.take(_lastDisplayCount).toList();

    for (var i = 0; i < displayCards.length; i++) {
      final card = displayCards[i];
      final price = card['gia'] as int;
      final duration = card['thoiLuong'] as int;
      final unit = card['donViThoiLuong'] as String;

      // Tính giá theo ngày
      int totalDays = duration;
      if (unit == 'tháng') {
        totalDays = duration * 30;
      } else if (unit == 'năm') {
        totalDays = duration * 365;
      }
      final pricePerDay = (price / totalDays).round();

      response +=
          '''
${i + 1}. ✨ **${card['tenGoi']}** 
   💰 Giá: ${_formatCurrency(price)} (≈ ${_formatCurrency(pricePerDay)}/ngày)
   ⏱ Thời hạn: **$duration $unit**
   📋 Loại: ${_getCardTypeBadge(card['loaiGoi'])}
   
   📝 ${card['moTa']}
   
   🎯 **Phù hợp cho:** ${card['phuHopCho']}
   🏋️ **Mục tiêu:** ${card['mucTieuTapLuyen']}
   
   ✅ **Quyền lợi:**
${(card['loiIch'] as List).map((e) => '      • $e').join('\n')}

─────────────────────
''';
    }

    // Thông báo nếu còn kết quả
    if (matchedCards.length > _lastDisplayCount) {
      response +=
          '\n💡 Còn ${matchedCards.length - _lastDisplayCount} gói khác! Gõ "hiện thêm" để xem tiếp.\n\n';
    }

    // Tư vấn thêm
    response += '''
� **GỢI Ý CỦA TÔI:**
• Người mới: Thử **gói 1 ngày** hoặc **7 ngày** trước
• Tập đều: Chọn **gói 1-3 tháng** để có động lực
• Cam kết dài hạn: **Gói 6 tháng - 1 năm** tiết kiệm nhất!
• Yêu thích sang chảnh: **Gói VIP** đẳng cấp 5 sao ⭐

📞 Hỏi tôi: "thẻ vip", "thẻ 3 tháng", "thẻ giá rẻ"... để tôi tư vấn cụ thể hơn nhé! 😊
''';

    return response;
  }

  /// Lấy badge cho loại thẻ
  String _getCardTypeBadge(String type) {
    switch (type) {
      case 'vip':
        return '� VIP';
      case 'premium':
        return '⭐ PREMIUM';
      case 'member':
        return '🎫 CƠ BẢN';
      default:
        return type.toUpperCase();
    }
  }

  /// Xử lý câu hỏi chi tiết về một gói thẻ cụ thể
  String _handleMembershipDetailQuery(String msg) {
    final cards = _dataService.membershipData['cards'] as List? ?? [];

    if (cards.isEmpty) {
      return '❌ Xin lỗi, hiện tại chưa có thông tin về các gói thẻ tập.';
    }

    final allCards = cards.cast<Map<String, dynamic>>();

    // Tìm tên gói trong câu hỏi
    Map<String, dynamic>? foundCard;

    // Tìm theo số (VIP 1, Premium 2, v.v.)
    for (var card in allCards) {
      final cardName = _normalizeText(card['tenGoi'] as String);

      // Check tên đầy đủ
      if (msg.contains(cardName)) {
        foundCard = card;
        break;
      }

      // Check theo pattern: vip 1, vip 2, premium 1, member 3...
      if (_containsAny(msg, ['vip']) && cardName.contains('vip')) {
        if (msg.contains('1') && cardName.contains('1')) {
          foundCard = card;
          break;
        } else if (msg.contains('2') && cardName.contains('2')) {
          foundCard = card;
          break;
        } else if (msg.contains('3') && cardName.contains('3')) {
          foundCard = card;
          break;
        } else if (msg.contains('x') && cardName.contains('x')) {
          foundCard = card;
          break;
        }
      }

      if (_containsAny(msg, ['premium']) && cardName.contains('premium')) {
        if (msg.contains('1') && cardName.contains('1')) {
          foundCard = card;
          break;
        } else if (msg.contains('2') && cardName.contains('2')) {
          foundCard = card;
          break;
        } else if (msg.contains('3') && cardName.contains('3')) {
          foundCard = card;
          break;
        }
      }

      if (_containsAny(msg, ['co ban', 'member', 'hoi vien']) &&
          cardName.contains('co ban')) {
        if (msg.contains('1') && cardName.contains('1')) {
          foundCard = card;
          break;
        } else if (msg.contains('2') && cardName.contains('2')) {
          foundCard = card;
          break;
        } else if (msg.contains('3') && cardName.contains('3')) {
          foundCard = card;
          break;
        }
      }
    }

    // Nếu không tìm thấy, hiển thị hướng dẫn
    if (foundCard == null) {
      return '''
❓ **CÁCH HỎI THÔNG TIN GÓI THẺ**

Để xem chi tiết một gói, hãy hỏi như sau:
• "thông tin gói VIP 1"
• "chi tiết gói Premium 2"
• "thông tin thẻ Hội viên cơ bản 3"

Hoặc đơn giản hơn:
• "vip 1"
• "premium 3"
• "member 2"

💡 Bạn cũng có thể hỏi "thẻ tập" để xem tất cả các gói nhé! 😊
''';
    }

    // Hiển thị chi tiết gói tìm được
    final price = foundCard['gia'] as int;
    final duration = foundCard['thoiLuong'] as int;
    final unit = foundCard['donViThoiLuong'] as String;

    // Tính giá theo ngày và tháng
    int totalDays = duration;
    if (unit == 'tháng') {
      totalDays = duration * 30;
    } else if (unit == 'năm') {
      totalDays = duration * 365;
    }
    final pricePerDay = (price / totalDays).round();
    final pricePerMonth = unit == 'năm'
        ? (price / (duration * 12)).round()
        : unit == 'ngày'
        ? (price * 30).round()
        : price;

    String response =
        '''
✨ **THÔNG TIN CHI TIẾT GÓI THẺ**

━━━━━━━━━━━━━━━━━━━━━
📋 **${foundCard['tenGoi']}**
${_getCardTypeBadge(foundCard['loaiGoi'])}
━━━━━━━━━━━━━━━━━━━━━

💰 **GIÁ CẢ:**
   • Tổng: **${_formatCurrency(price)}**
   • Trung bình: **${_formatCurrency(pricePerDay)}/ngày**
''';

    if (unit != 'tháng') {
      response += '   • Quy đổi: **${_formatCurrency(pricePerMonth)}/tháng**\n';
    }

    response +=
        '''

⏱ **THỜI HẠN:**
   • **$duration $unit**
''';

    if (totalDays > 1) {
      response += '   • Tương đương: **$totalDays ngày**\n';
    }

    response +=
        '''

📝 **MÔ TẢ:**
${'   ${foundCard['moTa']}'.replaceAll('\n', '\n   ')}

🎯 **PHÙ HỢP CHO:**
${'   ${foundCard['phuHopCho']}'.replaceAll('\n', '\n   ')}

🏋️ **MỤC TIÊU TẬP LUYỆN:**
${'   ${foundCard['mucTieuTapLuyen']}'.replaceAll('\n', '\n   ')}

✅ **QUYỀN LỢI:**
${(foundCard['loiIch'] as List).map((e) => '   • $e').join('\n')}

━━━━━━━━━━━━━━━━━━━━━

💡 **SO SÁNH:**
''';

    // Tìm gói tương tự để so sánh
    final sameType = allCards
        .where(
          (c) =>
              c['loaiGoi'] == foundCard!['loaiGoi'] &&
              c['tenGoi'] != foundCard['tenGoi'],
        )
        .toList();

    if (sameType.isNotEmpty) {
      response +=
          '\n📊 **Các gói ${foundCard['loaiGoi'].toUpperCase()} khác:**\n';
      for (var card in sameType.take(2)) {
        final otherPrice = card['gia'] as int;
        final otherDuration = card['thoiLuong'] as int;
        final otherUnit = card['donViThoiLuong'] as String;
        response +=
            '   • ${card['tenGoi']}: ${_formatCurrency(otherPrice)} ($otherDuration $otherUnit)\n';
      }
    }

    response += '''

🤔 **ĐÁNH GIÁ:**
''';

    // Đánh giá dựa trên giá/ngày
    if (pricePerDay < 10000) {
      response += '   ⭐⭐⭐ **CỰC KỲ TIẾT KIỆM** - Chỉ $pricePerDay/ngày!\n';
    } else if (pricePerDay < 20000) {
      response += '   ⭐⭐ **TIẾT KIỆM** - Giá rất hợp lý!\n';
    } else if (pricePerDay < 50000) {
      response += '   ⭐ **HỢP LÝ** - Giá ổn cho chất lượng dịch vụ\n';
    } else {
      response +=
          '   👑 **CAO CẤP** - Dịch vụ premium, trải nghiệm đẳng cấp!\n';
    }

    // Gợi ý
    if (foundCard['loaiGoi'] == 'member' && duration <= 7) {
      response +=
          '   💡 Gói này phù hợp để **thử nghiệm** hoặc tập **ngắn hạn**\n';
    } else if (duration >= 3 && unit == 'tháng') {
      response +=
          '   💡 Gói này giúp bạn **cam kết** và thấy **kết quả rõ rệt**\n';
    } else if (duration >= 1 && unit == 'năm') {
      response +=
          '   💡 Gói dài hạn - **Tiết kiệm nhất** cho người tập đều đặn!\n';
    }

    response += '''

━━━━━━━━━━━━━━━━━━━━━

📞 **LIÊN HỆ ĐĂNG KÝ:**
Liên hệ quầy lễ tân hoặc hotline để được tư vấn và đăng ký ngay!

💬 Hỏi tôi về gói khác: "thẻ vip", "premium 3", "member 1"... 😊
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
   • Lịch trình tập luyện

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

  /// Xử lý lời cảm ơn từ người dùng
  String _handleThankYou() {
    // Random response để tự nhiên hơn
    final responses = [
      '''
😊 **Không có gì đâu!**

Rất vui được giúp bạn! 💪

🔔 **Nhớ nhé:**
• Tôi luôn sẵn sàng hỗ trợ bạn 24/7
• Hỏi tôi bất cứ điều gì về gym, tập luyện, dinh dưỡng
• Tính toán BMI, BMR, TDEE miễn phí
• Tư vấn thẻ tập phù hợp với bạn

💬 Cần gì cứ gọi tôi nhé! Chúc bạn tập luyện hiệu quả! 🏋️‍♀️
''',
      '''
🙏 **Rất hân hạnh được hỗ trợ bạn!**

Đó là nhiệm vụ của tôi mà! 😊

💡 **Mẹo nhỏ:**
Hãy tập đều đặn, ăn uống khoa học và nghỉ ngơi đủ giấc để đạt mục tiêu tốt nhất nhé!

📞 Bất cứ khi nào cần tư vấn:
• Bài tập → Hỏi tôi
• Dinh dưỡng → Hỏi tôi
• Thẻ tập → Hỏi tôi
• Lịch tập → Hỏi tôi

Chúc bạn luôn khỏe mạnh và đạt được body mơ ước! 💪✨
''',
      '''
😄 **Không sao, đừng khách sáo!**

Tôi ở đây để giúp bạn mà! 🤗

🎯 **Nhắc nhở:**
• Đừng quên uống đủ nước khi tập (2-3 lít/ngày)
• Khởi động kỹ trước mỗi buổi tập
• Theo dõi tiến trình để có động lực

💬 **Lần sau cần gì cứ nhắn:**
"Tôi muốn..." hoặc "Tư vấn cho tôi..."
Tôi sẽ giúp bạn ngay! 

Gym Pro luôn đồng hành cùng bạn trên hành trình chinh phục bản thân! 🔥
''',
      '''
❤️ **Cảm ơn bạn đã tin tưởng Gym Pro AI!**

Mình luôn sẵn sàng để hỗ trợ bạn! 💪

✨ **Fun fact:**
Mỗi lần bạn tập đều đặn, cơ thể bạn sẽ tiết ra hormone hạnh phúc (endorphin) - giúp bạn vui vẻ và tích cực hơn!

🚀 **Keep going!**
Đừng từ bỏ giấc mơ body đẹp của bạn nhé!

📲 Cần tư vấn gì thêm? Cứ hỏi thoải mái! Tôi luôn ở đây! 😊
''',
    ];

    // Random chọn 1 response
    final randomIndex = DateTime.now().microsecond % responses.length;
    return responses[randomIndex];
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
   • "Tư vấn dinh dưỡng"

4️⃣ **Lịch tập:**
   • "Lịch tập full body"

5️⃣ **Thẻ tập:**
   • "Gói thẻ VIP"
   • "Tư vấn gói tập"

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
