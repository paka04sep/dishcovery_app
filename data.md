# 📚 DISHCOVERY - Project Architecture & Data Documentation

เอกสารฉบับนี้ถูกเขียนขึ้นเพื่อใช้รับช่วงต่อ (Handover) ให้แก่นักพัฒนาหรือ AI Agent โมเดลถัดไป สามารถทำความเข้าใจภาพรวมของโปรเจกต์ โครงสร้างข้อมูล และสถาปัตยกรรมการจัดการ State ทั้งหมดในแอปพลิเคชัน DISHCOVERY

---

## 🏗️ 1. Tech Stack Overview
- **Frontend:** Flutter & Dart
- **Backend/DB:** Firebase (Firestore, Authentication, Cloud Functions, Storage)
- **Key Flow:** แอปค้นหาร้านอาหารสไตล์ Tinder-like (Swipe ขวา=Yum, ซ้าย=Pass, บน=Fav) ขับเคลื่อนด้วยระบบ Recommendation Algorithm หลังบ้าน

---

## 📂 2. Directory & Structure

### 📱 `lib/screen/` (UI หน้าจอหลัก)
- **`swipescreen.dart`**: หน้าหลักสำหรับปัดการ์ดร้านอาหาร ใช้แพ็กเกจ `flutter_card_swiper` คุยกับ `RestaurantService` แบบ Realtime ล่าสุดมีการแก้บั๊ก Memory Reference ขาดกันด้วยการทำ `List.from(cache)`
- **`restarurant_detail_screen.dart`**: หน้ารายละเอียดร้าน จัดการเรื่องรูป เมนู และระบบคอมเมนต์/รีวิว
- **`user_profile_screen.dart`**: หน้าโปรไฟล์ผู้ใช้ โชว์สถิติ (Stats) การปัด และจัดการระบบ Logout / Reset Taste Profile
- **`history_screen.dart` / `favorite_screen.dart`**: หน้าดูประวัติการปัดและร้านโปรด

### ⚙️ `lib/services/` (Data / State Management)
- **`restaurant_service.dart`**: เป็นหัวใจหลักของแอป ทำงานแบบ **Singleton (ChangeNotifier)** เป็น Source of Truth กักเก็บข้อมูลทุกอย่าง:
  - ดึงข้อมูลร้านค้า, พิกัด GPS (`geolocator`), และดึง User Profile
  - แคชข้อมูลร้านทั้งหมดไว้ใน `_restaurants` และร้านที่พร้อมปัดไว้ใน `_swipableCache`
- **`auth_service.dart`**: (ถ้ามี) สำหรับเข้าสู่ระบบผ่าน Google / Email

### ☁️ `functions/index.js` (Cloud Functions)
- **`getRecommendedBatch`**: อัลกอริทึมป้อนร้านหาร โดยคำนวณจาก พิกัดรัศมี (Distance), คะแนนความชอบส่วนตัว (Taste Profile Match Score), และความนิยม (Trending Score) พร้อมการลบร้านที่เพิ่งปัดซ้ำออกผ่าน `excludeIds` แบบ Real-time
- **`recordSwipeAction`**: ฟังก์ชันปรับปรุงโปรไฟล์ผู้ใช้ ให้คะแนน Taste Profile (+2 Yum, -1 Pass, +3 Fav) และทำ Time-Decay ให้กับคะแนน trending ของร้าน

---

## 💾 3. State Management & Variables

### 🧠 Core Variables ใน `RestaurantService`
| ตัวแปร | ชนิดข้อมูล | หน้าที่ |
|----------|-------------|----------|
| `_userModel` | `UserModel?` | เก็บข้อมูลผู้ใช้ปัจจุบัน รวมถึง `history` (yum, pass, fav) และ `stats` |
| `_restaurants` | `List<RestaurantCardData>` | ฐานข้อมูลร้านอาหารทั้งหมดที่ทำการโหลดมาสู่ Local |
| `_swipableCache` | `List<RestaurantCardData>` | คิวของร้านที่รอให้แอปดึงไปปัดใน SwipeScreen (เติมทีละ 10) |
| `_isFetchingBatch` | `bool` | สถานะเปิด/ปิด Lock เพื่อกันไม่ให้คอล API โหลด Batch ร้านอาหารซ้ำซ้อน |
| `_isManualRefresh`| `bool` | สถานะช่วยบอกให้ UI (AppInitScreen) ทำการปิดหน้าจอโหลดเต็มใบ เมื่อกดรีเฟรชจากช้อนส้อม |

### 🔥 หลักการทำงานของการปัด (Swipe Flow ปัจจุบันที่เสถียรที่สุด)
1. **Swipe Screen** ผูกตัวแปร `restaurantCards` โดยการคัดลอก `List.from(RestaurantService.instance.swipableRestaurants)` เพื่อไม่ให้ Pointer โดนรบกวนเวลา Backend แก้ไข Cache
2. ผู้ใช้ปัดการ์ด 1 ใบ -> ตัว CardSwiper ขยับ `currentIndex` ขึ้น 1
3. ฟังก์ชัน `_onSwipe` ยิงไปที่ `RestaurantService.swipeRestaurant`
4. Backend แอบลบข้อมูลร้านนั้นออกจาก `_swipableCache` และยิงขึ้น Firestore ทันที **แตะต้องไม่โดน UI !**
5. หากคิวใน `_swipableCache` น้อยกว่า 3 ใบ ระบบจะแอบดึง Cloud Function `getRecommendedBatch` มาเติมเงียบๆ และ Append ลงไป 
6. หน้า UI ตรวจพบของใหม่ จึงสั่ง Append `.addAll(toAdd)` เท่านั้น ทำให้ CardSwiper ทำงานสมูท 100%

---

## 🗄️ 4. Data Models (Firestore Schema)

### 🥑 **Users Collection (`users/{uid}`)**
```json
{
  "username": "string",
  "email": "string",
  "history": {
    "yum": ["id_1", "id_2"],
    "passed": ["id_3"],
    "fav": ["id_4"]
  },
  "tasteProfile": {
    "categories": { "Thai": 12, "Dessert": 5 },
    "priceRange": { "2": 20, "3": 10 },
    "timeAffinity": { "lunch": 50, "dinner": 25 }
  },
  "stats": {
    "yums": 45,
    "passes": 12,
    "totalSwipes": 57
  }
}
```

### 🍔 **Restaurants Collection (`restaurants/{id}`)**
```json
{
  "name": "string",
  "categories": ["Thai", "Spicy"],
  "priceRange": 2,
  "rating": 4.5,
  "reviewCount": 120,
  "location": {
    "latitude": 13.75,
    "longitude": 100.5
  },
  "metrics": {
    "trendingScore": 1500,
    "engagementStats": {
      "fav": 30,
      "pass": 5,
      "yum": 150
    }
  }
}
```

---

## 📝 5. ข้อควรระวังสำหรับโมเดล/นักพัฒนาท่านถัดไป (Gotchas)
1. **Flutter Card Swiper Widget:**
   - **ห้ามสั่ง `setState()` พร่ำเพรื่อ** ในหน้า `SwipeScreen` โดยเด็ดขาดหากไม่ได้มีการบวกการ์ดใหม่เข้า List เพราะจังหวะที่เซ็ตสถานะชนกับการแสดงผล Animation มันจะส่งผลให้ Swiper เอ๋อ หรือข้าม Index 
   - **ห้ามใช้ Reference Memory แบบผูกขาด:** `restaurantCards` ต้องถูก Wrap ด้วย `List.from(...)` เสมอเวลาดึงมาจาก Service
2. **Cloud Functions (`index.js`):**
   - ทุกครั้งที่โมเดลมีการแก้ `index.js` จะต้องแนะนำให้ User พิมพ์คำสั่ง `firebase deploy --only functions` เนื่องจาก Cloud Logic ทำงานแยกส่วนกับ App โดยสิ้นเชิง หาไม่รันจะเจอบั๊กข้อมูลเพี้ยน
3. **App Check:**
   - ใน Console อาจมี Error เด้งว่า _"No AppCheckProvider installed"_ เป็นเพียงแค่คำเตือนเพราะระบบยังไม่อนุมัติ App Check สามารถละเลยข้ามไปได้ ไม่แครช
4. **_userModel Caching:**
   - ตรวจสอบ `_userModel` ตอนที่มีการเปลี่ยนบัญชี (Logout/Login) ทุกครั้งผ่านคำสั่ง `RestaurantService.instance.reset()` ไม่งั้นข้อมูล User เก่าจะทะลักไปที่คนอื่น

---

ถ้าโมเดลอ่านถึงตรงนี้ แสดงว่าคุณพร้อมสำหรับการลุยงานสร้าง ฟีเจอร์ แชท, ระบบจับคู่, หรือหน้าแอดมิน เพื่อต่อยอดโปรเจกต์ DISHCOVERY ได้ทันที! 🚀
