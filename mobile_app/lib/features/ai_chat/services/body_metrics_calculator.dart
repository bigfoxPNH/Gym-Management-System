import 'ai_data_service.dart';

/// Service tính toán các chỉ số cơ thể
class BodyMetricsCalculator {
  final AIDataService _dataService;

  BodyMetricsCalculator(this._dataService);

  /// Tính BMI
  double calculateBMI({required double weight, required double height}) {
    // height in meters, weight in kg
    if (height <= 0 || weight <= 0) return 0;
    return weight / (height * height);
  }

  /// Tính BMR theo công thức Mifflin-St Jeor
  double calculateBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    // height in cm, weight in kg
    double bmr;
    if (gender.toLowerCase() == 'nam' || gender.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }
    return bmr;
  }

  /// Tính TDEE
  double calculateTDEE({required double bmr, required String activityLevel}) {
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'very_active': 1.725,
      'extra_active': 1.9,
    };

    String normalizedLevel = activityLevel.toLowerCase().replaceAll(' ', '_');
    double multiplier = multipliers[normalizedLevel] ?? 1.55;

    return bmr * multiplier;
  }

  /// Phân tích BMI và đưa ra khuyến nghị
  Map<String, dynamic> analyzeBMI({
    required double bmi,
    required String gender,
    required int age,
  }) {
    final bmiRef = _dataService.bmiData['bmi_reference'];
    if (bmiRef == null) {
      return {
        'category': 'Không xác định',
        'description': 'Dữ liệu BMI chưa sẵn sàng',
        'recommendation': '',
      };
    }

    // Tìm category phù hợp với giới tính
    final categories = bmiRef['categories'] as List;
    final genderData = categories.firstWhere(
      (cat) =>
          cat['gioi_tinh'].toString().toLowerCase() ==
          (gender.toLowerCase() == 'nam' ? 'nam' : 'nữ'),
      orElse: () => categories[0],
    );

    // Tìm nhóm tuổi
    final ageGroups = genderData['nhom_tuoi'] as List;
    Map<String, dynamic>? selectedGroup;

    for (var group in ageGroups) {
      final ageRange = group['do_tuoi'] as String;
      if (_isAgeInRange(age, ageRange)) {
        selectedGroup = group;
        break;
      }
    }

    if (selectedGroup == null) {
      selectedGroup = ageGroups.last;
    }

    // Tìm ngưỡng BMI
    final thresholds = selectedGroup!['nguong'] as List;

    // Tìm ngưỡng phù hợp - ưu tiên ngưỡng có khoảng chứa BMI
    for (var threshold in thresholds) {
      final minBmi = (threshold['bmi_min'] as num).toDouble();
      final maxBmi = (threshold['bmi_max'] as num).toDouble();

      // Kiểm tra nằm trong khoảng (bao gồm cả biên)
      if (bmi >= minBmi && bmi <= maxBmi) {
        return {
          'category': threshold['muc'],
          'description': threshold['mo_ta'],
          'recommendation': threshold['khuyen_nghi'],
          'note': selectedGroup['ghi_chu'] ?? '',
        };
      }
    }

    // Nếu không tìm thấy chính xác, tìm ngưỡng gần nhất (xử lý khoảng trống)
    for (int i = 0; i < thresholds.length - 1; i++) {
      final currentMax = (thresholds[i]['bmi_max'] as num).toDouble();
      final nextMin = (thresholds[i + 1]['bmi_min'] as num).toDouble();

      // Nếu BMI rơi vào khoảng trống giữa 2 ngưỡng, chọn ngưỡng tiếp theo
      if (bmi > currentMax && bmi < nextMin) {
        final threshold = thresholds[i + 1];
        return {
          'category': threshold['muc'],
          'description': threshold['mo_ta'],
          'recommendation': threshold['khuyen_nghi'],
          'note': selectedGroup['ghi_chu'] ?? '',
        };
      }
    }

    return {
      'category': 'Ngoài phạm vi',
      'description': 'BMI của bạn nằm ngoài phạm vi tiêu chuẩn',
      'recommendation': 'Hãy tham khảo ý kiến bác sĩ',
    };
  }

  /// Phân tích BMR và đưa ra thông tin
  Map<String, dynamic> analyzeBMR({
    required double bmr,
    required String gender,
    required int age,
  }) {
    final bmrRef = _dataService.bmrData['bmr_reference'];
    if (bmrRef == null) {
      return {
        'range': 'Không xác định',
        'description': '',
        'recommendation': '',
      };
    }

    final categories = bmrRef['categories'] as List;
    final genderData = categories.firstWhere(
      (cat) =>
          cat['gioi_tinh'].toString().toLowerCase() ==
          (gender.toLowerCase() == 'nam' ? 'nam' : 'nữ'),
      orElse: () => categories[0],
    );

    final ageGroups = genderData['nhom_tuoi'] as List;
    Map<String, dynamic>? selectedGroup;

    for (var group in ageGroups) {
      final ageRange = group['do_tuoi'] as String;
      if (_isAgeInRange(age, ageRange)) {
        selectedGroup = group;
        break;
      }
    }

    if (selectedGroup != null) {
      return {
        'range': selectedGroup['average_range_kcal'],
        'description': selectedGroup['mo_ta'],
        'recommendation': selectedGroup['khuyen_nghi'],
      };
    }

    return {'range': 'Không xác định', 'description': '', 'recommendation': ''};
  }

  /// Kiểm tra tuổi có nằm trong khoảng không
  bool _isAgeInRange(int age, String rangeStr) {
    if (rangeStr.contains('+')) {
      final minAge = int.tryParse(rangeStr.replaceAll('+', '')) ?? 0;
      return age >= minAge;
    }

    if (rangeStr.contains('-')) {
      final parts = rangeStr.split('-');
      if (parts.length == 2) {
        final minAge = int.tryParse(parts[0].trim()) ?? 0;
        final maxAge = int.tryParse(parts[1].trim()) ?? 999;
        return age >= minAge && age <= maxAge;
      }
    }

    return false;
  }

  /// Tính macro dinh dưỡng dựa trên TDEE và mục tiêu
  Map<String, dynamic> calculateMacros({
    required double tdee,
    required String goal, // 'weight_loss', 'maintenance', 'weight_gain'
  }) {
    double calories = tdee;
    double proteinGPerKg = 1.6;
    double fatPercent = 0.25;

    switch (goal.toLowerCase()) {
      case 'weight_loss':
      case 'giam_can':
        calories = tdee - 500; // deficit 500 kcal
        proteinGPerKg = 2.0; // protein cao hơn khi giảm cân
        fatPercent = 0.25;
        break;
      case 'weight_gain':
      case 'tang_can':
        calories = tdee + 300; // surplus 300 kcal
        proteinGPerKg = 1.8;
        fatPercent = 0.25;
        break;
      case 'maintenance':
      case 'duy_tri':
      default:
        calories = tdee;
        proteinGPerKg = 1.6;
        fatPercent = 0.25;
        break;
    }

    return {
      'calories': calories.round(),
      'protein_g_per_kg': proteinGPerKg,
      'fat_percent': fatPercent,
    };
  }
}
