import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/services/auth_service.dart';
import 'package:dishcovery_app/constants/app_init_screen.dart';
import 'package:dishcovery_app/starting_screen/loading_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpcenterScreen extends StatefulWidget {
  const HelpcenterScreen({super.key});

  @override
  State<HelpcenterScreen> createState() => _HelpcenterScreenState();
}

class _HelpcenterScreenState extends State<HelpcenterScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          text: 'ความช่วยเหลือและข้อกำหนด',
          style: AppTextStyles.signinText.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _buildSettingSection(
                title: 'ศูนย์ช่วยเหลือ',
                children: [
                  _buildListTile(
                    icon: Icons.help_outline,
                    title: 'วิธีการใช้งานแอปพลิเคชัน',
                    subtitle: 'วิธีการใช้งานเบื้องต้น',
                    isDestructive: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HowToUseScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSettingSection(
                title: 'ติดต่อเรา',
                children: [
                  _buildListTile(
                    icon: Icons.contact_support_outlined,
                    title: 'เกี่ยวกับผู้พัฒนา',
                    subtitle: 'ติดตามข่าวสารและติดต่อทีมงาน',
                    isDestructive: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutDeveloperScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSettingSection(
                title: 'เกี่ยวกับแอป',
                children: [
                  _buildListTile(
                    icon: Icons.info_outline,
                    title: 'เวอร์ชันแอปพลิเคชัน',
                    subtitle: '1.0.0',
                    isDestructive: false,
                    onTap: () => _showUpdateDetailsModal(context),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showUpdateDetailsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายละเอียดการอัปเดต',
                      style: AppTextStyles.profileText.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Version 1.0.0: Release application',
                  style: AppTextStyles.profileText.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  '- Release application\n',
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'ตกลง',
                      style: AppTextStyles.profileText.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.profileText.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDestructive,
    required VoidCallback onTap,
  }) {
    final color = isDestructive ? Colors.red : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppTextStyles.profileText.copyWith(
          color: color,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.profileText.copyWith(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          text: 'วิธีการใช้งานแอปพลิเคชัน',
          style: AppTextStyles.signinText.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInstructionCard(
            icon: Icons.search,
            title: '1. ค้นหาร้านอาหาร',
            description:
                'ระบบจะแสดงร้านอาหารอร่อยๆ ที่อยู่ใกล้คุณ คุณสามารถปัดหน้าจอเพื่อดูร้านถัดไปได้อย่างง่ายดาย',
          ),
          const SizedBox(height: 16),
          _buildInstructionCard(
            icon: Icons.restaurant_menu,
            title: '2. ดูข้อมูลและเมนู',
            description:
                'กดที่รูปภาพร้านหรือปุ่มรายละเอียด เพื่อเข้าไปดูเมนูอาหาร บรรยากาศ รีวิว และเส้นทางการเดินทางไปยังร้านนั้นๆ',
          ),
          const SizedBox(height: 16),
          _buildInstructionCard(
            icon: Icons.favorite,
            title: '3. บันทึกร้านโปรด',
            description:
                'ปัดขวาที่รูปภาพ หรือกดปุ่มหัวใจ เพื่อเก็บร้านที่คุณสนใจเข้าสู่รายการโปรดส่วนตัว คุณสามารถกลับมาดูรายการเหล่านี้ได้ตลอดเวลาผ่านหน้าโปรไฟล์',
          ),
          const SizedBox(height: 16),
          _buildInstructionCard(
            icon: Icons.settings,
            title: '4. ปรับเปลี่ยนการตั้งค่า',
            description:
                'หากคุณต้องการเปลี่ยนแนวอาหาร หรือระยะทางที่คุณต้องการค้นหา สามารถตั้งค่าได้ในหน้าการตั้งค่าโปรไฟล์',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.profileText.copyWith(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  Future<void> openFacebook(String username) async {
    final Uri url = Uri.parse("https://www.facebook.com/$username");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          text: 'เกี่ยวกับผู้พัฒนา',
          style: AppTextStyles.signinText.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.code,
                size: 60,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ทีมพัฒนา DISHCOVERY',
              style: AppTextStyles.profileText.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Dishcovery เป็นแอปพลิเคชันที่ถูกพัฒนาขึ้นเพื่อตอบโจทย์ผู้ใช้งานที่ต้องการค้นหาร้านอาหารเด็ดๆ และตรงใจที่สุด ในรูปแบบที่ใช้งานง่ายและสนุกสนาน พวกเราตั้งใจออกแบบแอปพลิเคชันนี้เพื่อให้คุณได้ค้นพบมื้ออร่อยในทุกๆ วัน',
                style: AppTextStyles.profileText.copyWith(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ช่องทางการติดต่อ',
                style: AppTextStyles.profileText.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.facebook,
              title: 'Facebook Developer',
              subtitle: 'fb.com/pem.pakawat/',
              onTap: () {
                openFacebook("pem.pakawat");
              },
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.facebook,
              title: 'Facebook Developer',
              subtitle: 'fb.com/apisak.chongkittworkung',
              onTap: () {
                openFacebook("apisak.chongkittworkung");
              },
            ),

            // _buildContactCard(
            //   icon: Icons.email_outlined,
            //   title: 'Email Support',
            //   subtitle: 'support@dishcovery.com',
            //   onTap: () {},
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.profileText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.profileText.copyWith(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
