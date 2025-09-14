// Demo script for Workout Assistant features
// This shows how the AI system provides real-time feedback

class WorkoutAssistantDemo {
  // Simulated feedback scenarios for different exercises

  static void demonstrateSquatFeedback() {
    print("=== SQUAT EXERCISE DEMO ===");

    // Correct form feedback (Green)
    print("✅ Đúng rồi, tiếp tục!");
    print("✅ Tư thế tốt!");
    print("✅ Ngồi sâu hơn nữa!");

    // Warning feedback (Yellow)
    print("⚠️ Điều chỉnh tư thế lưng");
    print("⚠️ Đầu gối hướng ra ngoài");
    print("⚠️ Chậm lại một chút");

    // Danger feedback (Red)
    print("🚨 Nguy hiểm: đầu gối vượt quá mũi chân");
    print("🚨 Dừng lại! Lưng cong quá mức");
    print("🚨 Nguy hiểm: mất thăng bằng");
  }

  static void demonstratePushupFeedback() {
    print("\n=== PUSH-UP EXERCISE DEMO ===");

    // Correct form feedback (Green)
    print("✅ Hoàn hảo! Giữ thẳng người");
    print("✅ Tuyệt vời! Tiếp tục");
    print("✅ Form chuẩn!");

    // Warning feedback (Yellow)
    print("⚠️ Hạ xuống từ từ hơn");
    print("⚠️ Giữ core chặt");
    print("⚠️ Thở đều đặn");

    // Danger feedback (Red)
    print("🚨 Nguy hiểm: tay quá sâu");
    print("🚨 Dừng lại! Mông quá cao");
    print("🚨 Nguy hiểm: lưng võng");
  }

  static void demonstrateWorkoutStats() {
    print("\n=== WORKOUT STATISTICS ===");
    print("⏱️  Thời gian: 02:35");
    print("🔄 Số lần: 15");
    print("📊 Độ chính xác: 87%");
    print("🎯 Trạng thái: Đang tập");
  }

  static void demonstrateExerciseInfo() {
    print("\n=== EXERCISE INFORMATION ===");
    print("🏋️ Tên: Squat");
    print("💪 Nhóm cơ: Đùi, Mông, Core");
    print("📈 Độ khó: Trung bình");
    print("⏰ Thời gian: 60s");

    print("\n📋 Hướng dẫn:");
    print("- Đứng thẳng, chân rộng bằng vai");
    print("- Từ từ ngồi xuống như ngồi ghế");
    print("- Giữ lưng thẳng, đầu gối hướng ra ngoài");

    print("\n⚠️ Lỗi thường gặp:");
    print("- Đầu gối vượt quá mũi chân");
    print("- Lưng cong quá mức");
    print("- Không ngồi đủ sâu");

    print("\n✅ Mẹo an toàn:");
    print("- Giữ lưng thẳng");
    print("- Đầu gối hướng ra ngoài");
    print("- Trọng lượng ở gót chân");
  }

  static void main() {
    print("🤖 WORKOUT ASSISTANT AI DEMO 🤖\n");

    demonstrateSquatFeedback();
    demonstratePushupFeedback();
    demonstrateWorkoutStats();
    demonstrateExerciseInfo();

    print("\n🎉 Demo completed! Try the actual app for full experience.");
  }
}

/*
Expected Output:

🤖 WORKOUT ASSISTANT AI DEMO 🤖

=== SQUAT EXERCISE DEMO ===
✅ Đúng rồi, tiếp tục!
✅ Tư thế tốt!
✅ Ngồi sâu hơn nữa!
⚠️ Điều chỉnh tư thế lưng
⚠️ Đầu gối hướng ra ngoài
⚠️ Chậm lại một chút
🚨 Nguy hiểm: đầu gối vượt quá mũi chân
🚨 Dừng lại! Lưng cong quá mức
🚨 Nguy hiểm: mất thăng bằng

=== PUSH-UP EXERCISE DEMO ===
✅ Hoàn hảo! Giữ thẳng người
✅ Tuyệt vời! Tiếp tục
✅ Form chuẩn!
⚠️ Hạ xuống từ từ hơn
⚠️ Giữ core chặt
⚠️ Thở đều đặn
🚨 Nguy hiểm: tay quá sâu
🚨 Dừng lại! Mông quá cao
🚨 Nguy hiểm: lưng võng

=== WORKOUT STATISTICS ===
⏱️  Thời gian: 02:35
🔄 Số lần: 15
📊 Độ chính xác: 87%
🎯 Trạng thái: Đang tập

=== EXERCISE INFORMATION ===
🏋️ Tên: Squat
💪 Nhóm cơ: Đùi, Mông, Core
📈 Độ khó: Trung bình
⏰ Thời gian: 60s

📋 Hướng dẫn:
- Đứng thẳng, chân rộng bằng vai
- Từ từ ngồi xuống như ngồi ghế
- Giữ lưng thẳng, đầu gối hướng ra ngoài

⚠️ Lỗi thường gặp:
- Đầu gối vượt quá mũi chân
- Lưng cong quá mức
- Không ngồi đủ sâu

✅ Mẹo an toàn:
- Giữ lưng thẳng
- Đầu gối hướng ra ngoài
- Trọng lượng ở gót chân

🎉 Demo completed! Try the actual app for full experience.
*/
