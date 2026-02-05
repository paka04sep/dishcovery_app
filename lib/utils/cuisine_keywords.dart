// class CuisineUtils {
//   static List<String> getKeywords(String preference) {
//     if (preference.contains("อาหารไทย") ||
//         preference == "อาหารอีสาน" ||
//         preference == "อาหารเหนือ" ||
//         preference == "อาหารใต้") {
//       return ["ไทย", "อีสาน", "เหนือ", "ใต้"];
//     }
//     if (preference.contains("ญี่ปุ่น")) return ["ญี่ปุ่น", "ซูชิ", "ราเมน"];
//     if (preference.contains("อาหารเกาหลี")) return ["เกาหลี", "ปิ้งย่าง"];
//     if (preference.contains("จีน")) return ["จีน", "ติ่มซำ"];
//     if (preference.contains("ปิ้งย่าง")) return ["อาหารเกาหลี", "ปิ้งย่าง"];
//     if (preference.contains("ตะวันตก") ||
//         preference.contains("ฟาสต์ฟู้ด") ||
//         preference.contains("เบอร์เกอร์") ||
//         preference == "พิซซ่า") {
//       return [
//         "อิตาเลียน",
//         "เม็กซิกัน",
//         "เบอร์เกอร์",
//         "สเต็ก",
//         "พิซซ่า",
//         "ฟาสต์ฟู้ด",
//       ];
//     }
//     if (preference.contains("อินเดีย")) return ["อินเดีย"];
//     if (preference.contains("เวียดนาม")) return ["เวียดนาม"];

//     return [preference.replaceAll("อาหาร", "").trim()];
//   }
// }

class CuisineUtils {
  static List<String> getKeywords(String preference) {
    switch (preference.trim()) {
      // ===== THAI =====
      case 'อาหารไทย':
        return ['อาหารไทย', 'ข้าว', 'กับข้าว', 'อาหารตามสั่ง'];

      case 'อาหารอีสาน':
        return ['อีสาน', 'ส้มตำ', 'ลาบ', 'น้ำตก', 'ไก่ย่าง', 'อาหารอีสาน'];

      case 'อาหารเหนือ':
        return [
          'เหนือ',
          'ขันโตก',
          'ข้าวซอย',
          'น้ำพริก',
          'อาหารเหนือ',
          'ส้มตำ ไก่ย่าง',
        ];

      case 'อาหารใต้':
        return ['ใต้', 'แกงใต้', 'คั่วกลิ้ง', 'ข้าวยำ', 'อาหารใต้'];

      // ===== ASIAN =====
      case 'อาหารญี่ปุ่น':
        return [
          'ญี่ปุ่น',
          'ซูชิ',
          'ซาชิมิ',
          'ราเมน',
          'อิซากายะ',
          'ดงบุริ',
          'อาหารญี่ปุ่น',
        ];

      case 'อาหารเกาหลี':
        return [
          'เกาหลี',
          'ปิ้งย่างเกาหลี',
          'คิมบับ',
          'ต๊อกบกกี',
          'อาหารเกาหลี',
        ];

      case 'อาหารจีน':
        return ['จีน', 'ติ่มซำ', 'หม่าล่า', 'หม้อไฟ', 'บะหมี่', 'อาหารจีน'];

      // ===== WESTERN =====
      case 'อาหารตะวันตก':
        return ['อาหารตะวันตก', 'สเต็ก', 'พาสต้า', 'อิตาเลียน', 'ฝรั่ง'];

      case 'ฟาสต์ฟู้ด':
        return ['ฟาสต์ฟู้ด', 'อาหารจานด่วน'];

      case 'เบอร์เกอร์':
        return ['เบอร์เกอร์', 'อาหารตะวันตก', 'ฟาสต์ฟู้ด'];

      case 'พิซซ่า':
        return ['พิซซ่า', 'อาหารตะวันตก', 'ฟาสต์ฟู้ด'];

      case 'ไก่ทอด':
        return ['ไก่ทอด', 'ไก่กรอบ'];

      // ===== COMMON THAI DISH =====
      case 'ก๋วยเตี๋ยว':
        return ['ก๋วยเตี๋ยว', 'เส้น', 'บะหมี่'];

      case 'ข้าวแกง':
        return ['ข้าวแกง', 'กับข้าว'];

      case 'ข้าวมันไก่':
        return ['ข้าวมันไก่'];

      case 'อาหารตามสั่ง':
        return ['ตามสั่ง', 'ผัด', 'ทอด'];

      case 'ส้มตำ ไก่ย่าง':
        return ['ส้มตำ', 'ไก่ย่าง', 'อีสาน'];

      // ===== GRILL / HOTPOT =====
      case 'ปิ้งย่าง':
        return ['ปิ้งย่าง', 'ย่าง', 'bbq'];

      case 'ชาบู / สุกี้':
        return ['ชาบู', 'สุกี้', 'หม้อไฟ'];

      // ===== DESSERT =====
      case 'เบเกอรี่':
        return ['เบเกอรี่', 'ขนมปัง'];

      case 'ของหวาน':
        return ['ของหวาน', 'ขนม'];

      case 'ไอศกรีม':
        return ['ไอศกรีม'];

      case 'เครป':
        return ['เครป'];

      // ===== DRINK =====
      case 'กาแฟ':
        return ['กาแฟ', 'คาเฟ่'];

      case 'ชา / ชานม':
        return ['ชา', 'ชานม'];

      case 'เครื่องดื่ม':
        return ['เครื่องดื่ม', 'น้ำ'];

      // ===== HEALTH =====
      case 'อาหารเพื่อสุขภาพ':
        return ['สุขภาพ', 'เฮลตี้', 'low fat'];

      case 'มังสวิรัติ':
        return ['มังสวิรัติ', 'เจ', 'vegan'];

      case 'คลีน':
        return ['คลีน', 'clean food'];

      // ===== FALLBACK =====
      default:
        return [preference];
    }
  }
}
