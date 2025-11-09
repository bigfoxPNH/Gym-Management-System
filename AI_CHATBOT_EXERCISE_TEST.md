# 🤖 Hướng Dẫn Test Chatbot AI - Tính Năng Bài Tập Nâng Cao

## 📋 Tổng Quan Cải Tiến

Chatbot AI đã được nâng cấp với khả năng hiểu và trả lời thông minh hơn về các câu hỏi bài tập:

### ✨ Tính Năng Mới:

1. **Tìm kiếm theo số lượng chính xác**

   - "1 bài tập chân dễ" → Trả về đúng 1 bài
   - "Chọn 2 bài tập ngực" → Trả về đúng 2 bài
   - "3 bài tập vai" → Trả về đúng 3 bài

2. **Tìm kiếm theo mục tiêu**

   - Giảm cân / Đốt mỡ
   - Tăng cơ / Phát triển cơ
   - Cardio / Tim mạch
   - Sức mạnh / Strength

3. **Tìm kiếm theo nhóm cơ chi tiết**

   - Ngực, Lưng, Vai, Tay, Chân, Bụng, Mông
   - Bicep, Tricep, Bắp chân, Cẳng tay

4. **Tìm kiếm theo độ khó**

   - Dễ / Người mới
   - Trung bình
   - Khó / Nâng cao

5. **Tìm kiếm theo dụng cụ**

   - Không cần dụng cụ / Tại nhà
   - Tạ tay / Dumbbell
   - Thanh tạ / Barbell
   - Máy

6. **Thông tin chi tiết hơn**
   - Nhóm cơ chính + Nhóm cơ phụ
   - Đối tượng phù hợp
   - Mục tiêu cụ thể
   - Cách tập chi tiết
   - Lợi ích rõ ràng

---

## 🧪 Test Cases - Câu Hỏi Mẫu

### 1️⃣ Test Tìm Kiếm Theo Số Lượng

```
✅ "1 bài tập chân dễ"
✅ "cho tôi 1 bài tập ngực"
✅ "chọn 2 bài tập vai"
✅ "gợi ý 3 bài tập bụng"
✅ "2 bài tập chân khó"
```

**Kết quả mong đợi:** Trả về đúng số lượng bài tập yêu cầu

---

### 2️⃣ Test Tìm Kiếm Theo Nhóm Cơ

```
✅ "các bài tập chân"
✅ "bài tập ngực"
✅ "bài tập vai"
✅ "bài tập lưng"
✅ "bài tập bụng"
✅ "bài tập mông"
✅ "bài tập tay"
✅ "bài tập bicep"
✅ "bài tập tricep"
✅ "bài tập bắp chân"
```

**Kết quả mong đợi:** Hiển thị các bài tập thuộc nhóm cơ đó (mặc định 5 bài)

---

### 3️⃣ Test Tìm Kiếm Theo Mục Tiêu

```
✅ "bài tập giảm cân"
✅ "bài tập đốt mỡ"
✅ "bài tập tăng cơ"
✅ "bài tập cardio"
✅ "bài tập tim mạch"
✅ "bài tập tăng sức mạnh"
```

**Kết quả mong đợi:**

- Giảm cân: Burpees, Jump Rope, Mountain Climbers, Running, Swimming...
- Tăng cơ: Bench Press, Deadlift, Squat, Pull-up...
- Cardio: Jumping Jacks, High Knees, Cycling, Running...

---

### 4️⃣ Test Tìm Kiếm Kết Hợp

```
✅ "1 bài tập chân dễ"
✅ "2 bài tập ngực khó"
✅ "bài tập vai dễ"
✅ "bài tập giảm cân cho người mới"
✅ "bài tập tăng cơ ngực"
✅ "bài tập cardio dễ"
✅ "3 bài tập chân tăng cơ"
```

**Kết quả mong đợi:** Kết hợp nhiều filter và trả về chính xác

---

### 5️⃣ Test Tìm Kiếm Theo Dụng Cụ

```
✅ "bài tập không cần dụng cụ"
✅ "bài tập tại nhà"
✅ "bài tập với tạ tay"
✅ "bài tập với thanh tạ"
```

**Kết quả mong đợi:** Lọc theo dụng cụ phù hợp

---

### 6️⃣ Test Câu Hỏi Mơ Hồ

```
✅ "tập gì để giảm cân"
✅ "muốn tăng cơ tay"
✅ "làm sao để có 6 múi"
✅ "tập chân hiệu quả"
```

**Kết quả mong đợi:** AI hiểu ngữ cảnh và gợi ý bài tập phù hợp

---

## 📊 Dữ Liệu Bài Tập Hiện Có

### Nhóm Cơ:

- **Ngực:** 3 bài tập (Bench Press, Incline Press, Chest Fly)
- **Lưng:** 3 bài tập (Pull-up, Deadlift, Cable Row)
- **Vai:** 3 bài tập (Shoulder Press, Lateral Raise, Rear Delt Fly)
- **Tay trước:** 3 bài tập (Barbell Curl, Dumbbell Curl, Concentration Curl)
- **Tay sau:** 2 bài tập (Triceps Pushdown, Skull Crusher)
- **Cẳng tay:** 2 bài tập (Wrist Curl, Farmer's Carry)
- **Bụng:** 3 bài tập (Crunch, Leg Raise, Plank)
- **Mông:** 2 bài tập (Hip Thrust, Glute Kickback)
- **Chân:** 4 bài tập (Squat, Leg Extension, Leg Curl, Romanian Deadlift)
- **Bắp chân:** 2 bài tập (Standing Calf Raise, Seated Calf Raise)
- **Cardio/Toàn thân:** 10 bài tập (Burpees, Jumping Jacks, Mountain Climbers, Jump Rope, High Knees, Box Jumps, Cycling, Running, Swimming, Kettlebell Swings)

### Tổng cộng: **37 bài tập**

---

## 🎯 Cách Test

### Bước 1: Chạy ứng dụng

```bash
flutter run
```

### Bước 2: Mở Chatbot AI

- Click vào icon chatbot ở góc màn hình
- Hoặc vào trang Admin → tìm chatbot

### Bước 3: Test các câu hỏi

- Thử lần lượt các câu hỏi ở trên
- Kiểm tra xem bot có trả lời đúng không
- Kiểm tra số lượng bài tập hiển thị
- Kiểm tra thông tin chi tiết

### Bước 4: Test edge cases

```
- "cho tôi 100 bài tập" → Chỉ có tối đa bài tập có sẵn
- "bài tập xyz không tồn tại" → Thông báo không tìm thấy
- "bài tập" → Hiển thị gợi ý chung
```

---

## ✅ Checklist Kiểm Tra

- [ ] Bot hiểu đúng số lượng yêu cầu (1, 2, 3...)
- [ ] Bot tìm đúng nhóm cơ (chân, ngực, vai...)
- [ ] Bot tìm đúng mục tiêu (giảm cân, tăng cơ, cardio)
- [ ] Bot hiểu độ khó (dễ, trung bình, khó)
- [ ] Bot lọc theo dụng cụ
- [ ] Thông tin hiển thị đầy đủ (nhóm cơ chính + phụ, mục tiêu, cách tập)
- [ ] Format hiển thị đẹp, dễ đọc
- [ ] Bot gợi ý khi không tìm thấy
- [ ] Bot xử lý câu hỏi tiếng Việt tốt

---

## 🐛 Báo Lỗi

Nếu gặp lỗi hoặc bot không trả lời đúng, vui lòng ghi chú:

1. **Câu hỏi bạn đã hỏi:**
2. **Kết quả thực tế:**
3. **Kết quả mong đợi:**
4. **Screenshot (nếu có):**

---

## 📝 Ghi Chú Kỹ Thuật

### Cải tiến đã thực hiện:

1. **File: `ai_engine.dart`**

   - Thêm hàm `_extractExerciseCount()` để phát hiện số lượng
   - Cải tiến `_handleExerciseQuery()` với logic tìm kiếm thông minh
   - Thêm scoring system để xếp hạng bài tập phù hợp
   - Mở rộng `_detectIntent()` để nhận diện mục tiêu

2. **File: `exercises.json`**
   - Thêm 10 bài tập cardio/giảm cân mới
   - Bổ sung thông tin chi tiết hơn cho mỗi bài tập
   - Tổng số bài tập: 37 bài

### Thuật toán matching:

```
Score = 0
- Khớp nhóm cơ: +3 điểm
- Khớp độ khó: +2 điểm (hoặc -1 nếu sai độ khó)
- Khớp mục tiêu: +2 điểm
- Khớp dụng cụ: +1 điểm

Sắp xếp theo score giảm dần → Lấy top N bài tập
```

---

## 🚀 Kế Hoạch Phát Triển Tiếp

- [ ] Thêm bài tập cụ thể theo thương hiệu (như CrossFit, Yoga, Pilates)
- [ ] Thêm video demo cho mỗi bài tập
- [ ] Tạo lịch tập theo tuần dựa trên bài tập
- [ ] Tích hợp theo dõi hiệu suất tập luyện
- [ ] Gợi ý bài tập dựa trên lịch sử tập của user

---

**Chúc bạn test thành công! 💪🤖**
