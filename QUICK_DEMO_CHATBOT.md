# 🎮 DEMO NHANH - TEST CHATBOT AI

## 🚀 Cách Test Nhanh Nhất

### 1️⃣ Khởi động ứng dụng

```bash
flutter run
```

### 2️⃣ Mở chatbot

- Tìm icon chatbot trên màn hình
- Click để mở cửa sổ chat

### 3️⃣ Thử ngay các câu này:

---

## 💬 15 Câu Test Nhanh

### 🏃 Cardio & Giảm Cân

```
1. "bài tập giảm cân"
2. "bài tập cardio"
3. "bài tập đốt mỡ"
```

**Kỳ vọng:** Hiện Burpees, Jump Rope, Running, Swimming...

---

### 💪 Tăng Cơ

```
4. "bài tập tăng cơ"
5. "bài tập tăng cơ ngực"
```

**Kỳ vọng:** Hiện Bench Press, Deadlift, Squat...

---

### 🎯 Theo Số Lượng

```
6. "1 bài tập chân dễ"
7. "cho tôi 2 bài tập vai"
8. "3 bài tập bụng"
```

**Kỳ vọng:** Hiện ĐÚNG số lượng yêu cầu

---

### 🦵 Theo Nhóm Cơ

```
9. "các bài tập chân"
10. "bài tập ngực"
11. "bài tập lưng"
```

**Kỳ vọng:** Hiện các bài của nhóm cơ đó

---

### 🔀 Kết Hợp

```
12. "bài tập vai dễ"
13. "2 bài tập chân khó"
14. "bài tập tăng cơ tay"
15. "bài tập không cần dụng cụ"
```

**Kỳ vọng:** Filter chính xác

---

## ✅ Checklist Nhanh

Sau khi test 15 câu trên, check xem:

- [ ] Bot hiểu số lượng (1, 2, 3...)
- [ ] Bot tìm đúng nhóm cơ
- [ ] Bot tìm theo mục tiêu (giảm cân, tăng cơ, cardio)
- [ ] Thông tin hiển thị đầy đủ
- [ ] Format dễ đọc

---

## 🎯 Kết Quả Mong Đợi

### VÍ DỤ: "1 bài tập chân dễ"

```
💪 BÀI TẬP PHÙ HỢP

1. **Leg Extension (Duỗi chân)**
   📍 Nhóm cơ: Đùi trước
   ➕ Nhóm cơ phụ: Đùi trong
   🔧 Dụng cụ: Máy duỗi chân
   📊 Độ khó: Dễ
   👥 Đối tượng: Người mới tập chân
   🎯 Mục tiêu: Làm rõ cơ đùi trước

   💡 Cách tập: Ngồi máy, duỗi chân thẳng ra rồi hạ xuống chậm.

   ✅ Lợi ích: Cô lập cơ đùi trước, giúp chân săn chắc rõ nét.

💬 Bạn muốn biết chi tiết hơn về bài tập nào không? 😊
```

### VÍ DỤ: "bài tập giảm cân"

```
💪 BÀI TẬP GIẢM CÂN

1. **Burpees**
   📍 Nhóm cơ: Toàn thân (Full Body)
   ➕ Nhóm cơ phụ: Ngực, Chân, Core, Tim mạch
   🔧 Dụng cụ: Không cần dụng cụ
   📊 Độ khó: Khó
   👥 Đối tượng: Người muốn giảm cân nhanh, Người tập HIIT
   🎯 Mục tiêu: Đốt mỡ hiệu quả, Tăng sức bền tim mạch, Giảm cân

   💡 Cách tập: Đứng thẳng, hạ người xuống tư thế chống đẩy...

   ✅ Lợi ích: Bài tập cardio đốt cháy calo cực mạnh...

2. **Jump Rope (Nhảy dây)**
   ...

3. **Running (Chạy bộ)**
   ...

💬 Bạn muốn biết chi tiết hơn về bài tập nào không? 😊
```

---

## 🆘 Nếu Có Vấn Đề

### Lỗi không hiển thị bài tập

→ Kiểm tra file `exercises.json` đã load đúng chưa

### Lỗi không nhận diện câu hỏi

→ Thử câu đơn giản hơn: "bài tập chân"

### Lỗi số lượng không đúng

→ Kiểm tra logic trong `_extractExerciseCount()`

---

## 📊 Thống Kê Nhanh

- **Tổng số bài tập:** 37 bài
- **Cardio/Giảm cân:** 10 bài
- **Tăng cơ:** 20+ bài
- **Nhóm cơ:** 10+ nhóm

---

## 🎉 Thành Công Khi...

✅ Bot trả lời đúng 10/15 câu test  
✅ Số lượng bài tập chính xác  
✅ Thông tin hiển thị đầy đủ  
✅ Không có lỗi crash

---

**Test xong rồi thì đọc file chi tiết:** `AI_CHATBOT_IMPROVEMENT_SUMMARY.md`

**Good luck! 💪🤖**
