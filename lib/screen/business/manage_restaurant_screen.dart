import 'dart:io';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/constants/app_init_screen.dart';

class ManageRestaurantScreen extends StatefulWidget {
  final RestaurantDetailsData restaurant;

  const ManageRestaurantScreen({super.key, required this.restaurant});

  @override
  State<ManageRestaurantScreen> createState() => _ManageRestaurantScreenState();
}

class _ManageRestaurantScreenState extends State<ManageRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _description;
  late int _priceRange;
  late List<String> _selectedCuisines;

  bool _isLoading = false;

  File? _newCoverImage;
  List<File> _newGalleryImages = [];
  late List<String> _existingGalleryUrls;

  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _foodOptions = [
    {'name': 'อาหารไทย', 'icon': Icons.ramen_dining_rounded},
    {'name': 'อาหารอีสาน', 'icon': Icons.local_fire_department_rounded},
    {'name': 'อาหารเหนือ', 'icon': Icons.terrain_rounded},
    {'name': 'อาหารใต้', 'icon': Icons.waves_rounded},
    {'name': 'อาหารญี่ปุ่น', 'icon': Icons.rice_bowl_rounded},
    {'name': 'อาหารเกาหลี', 'icon': Icons.restaurant_rounded},
    {'name': 'อาหารจีน', 'icon': Icons.set_meal_rounded},
    {'name': 'อาหารตะวันตก', 'icon': Icons.dinner_dining_rounded},
    {'name': 'ฟาสต์ฟู้ด', 'icon': Icons.fastfood_rounded},
    {'name': 'เบอร์เกอร์', 'icon': Icons.lunch_dining_rounded},
    {'name': 'พิซซ่า', 'icon': Icons.local_pizza_rounded},
    {'name': 'ไก่ทอด', 'icon': Icons.restaurant_menu_rounded},
    {'name': 'ก๋วยเตี๋ยว', 'icon': Icons.ramen_dining},
    {'name': 'ข้าวแกง', 'icon': Icons.rice_bowl},
    {'name': 'ข้าวมันไก่', 'icon': Icons.set_meal},
    {'name': 'อาหารตามสั่ง', 'icon': Icons.restaurant},
    {'name': 'ส้มตำ ไก่ย่าง', 'icon': Icons.food_bank},
    {'name': 'ปิ้งย่าง', 'icon': Icons.outdoor_grill_rounded},
    {'name': 'ชาบู / สุกี้', 'icon': Icons.soup_kitchen_rounded},
    {'name': 'เบเกอรี่', 'icon': Icons.cake_rounded},
    {'name': 'ของหวาน', 'icon': Icons.icecream_rounded},
    {'name': 'ไอศกรีม', 'icon': Icons.icecream},
    {'name': 'เครป', 'icon': Icons.egg},
    {'name': 'กาแฟ', 'icon': Icons.local_cafe_rounded},
    {'name': 'ชา / ชานม', 'icon': Icons.emoji_food_beverage_rounded},
    {'name': 'เครื่องดื่ม', 'icon': Icons.local_drink_rounded},
    {'name': 'อาหารเพื่อสุขภาพ', 'icon': Icons.eco_rounded},
    {'name': 'มังสวิรัติ', 'icon': Icons.grass_rounded},
    {'name': 'คลีน', 'icon': Icons.spa_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _name = widget.restaurant.name;
    _description = widget.restaurant.description;
    _priceRange = widget.restaurant.priceRange;
    _selectedCuisines = List.from(widget.restaurant.cuisine);
    _existingGalleryUrls = List.from(widget.restaurant.galleryImages);
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newCoverImage = File(image.path);
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newGalleryImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  void _openCuisinePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เลือกประเภทอาหาร',
                    style: AppTextStyles.primaryTitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _foodOptions.map((option) {
                          final String name = option['name'];
                          final IconData icon = option['icon'];
                          final bool isSelected = _selectedCuisines.contains(
                            name,
                          );

                          return ChoiceChip(
                            showCheckmark: false,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  name,
                                  style: AppTextStyles.profileText.copyWith(
                                    color: AppColors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.lightBlue,
                            backgroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.black,
                              ),
                            ),
                            onSelected: (_) {
                              setModalState(() {
                                if (isSelected) {
                                  _selectedCuisines.remove(name);
                                } else {
                                  _selectedCuisines.add(name);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'ตกลง',
                        style: AppTextStyles.signinText.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedCuisines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกประเภทอาหารอย่างน้อย 1 อย่าง')),
      );
      return;
    }

    final updatedData = widget.restaurant.copyWith(
      name: _name,
      description: _description,
      priceRange: _priceRange,
      cuisine: _selectedCuisines,
      galleryImages: _existingGalleryUrls,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppInitUpdateData(
          onUpdate: () =>
              RestaurantService.instance.updateRestaurantWithDetails(
                updatedData,
                newCoverImage: _newCoverImage,
                newGalleryImages: _newGalleryImages,
              ),
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );
        Navigator.pop(context);
      }
    } else if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $result')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          text: "จัดการข้อมูลร้าน",
          style: AppTextStyles.profileText.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover Image
                    Text(
                      'รูปภาพหน้าปก',
                      style: AppTextStyles.profileText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          image: _newCoverImage != null
                              ? DecorationImage(
                                  image: FileImage(_newCoverImage!),
                                  fit: BoxFit.cover,
                                )
                              : (widget.restaurant.imageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          widget.restaurant.imageUrl,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child:
                            _newCoverImage == null &&
                                widget.restaurant.imageUrl.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Restaurant Name
                    Text(
                      'ชื่อร้านอาหาร',
                      style: AppTextStyles.profileText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _name,
                      decoration: InputDecoration(
                        hintText: 'กรอกชื่อร้าน',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณากรอกชื่อร้าน' : null,
                      onSaved: (v) => _name = v ?? '',
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'คำอธิบายร้านอาหาร',
                      style: AppTextStyles.profileText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _description,
                      decoration: InputDecoration(
                        hintText: 'รายละเอียด หรือ ข้อมูลเพิ่มเติม',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
                      onSaved: (v) => _description = v ?? '',
                    ),
                    const SizedBox(height: 20),

                    // Cuisines
                    Text(
                      'หมวดหมู่ประเภทอาหาร',
                      style: AppTextStyles.profileText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openCuisinePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCuisines.isEmpty
                                    ? 'เลือกหมวดหมู่อาหาร'
                                    : _selectedCuisines.join(', '),
                                style: AppTextStyles.hintText.copyWith(
                                  color: _selectedCuisines.isEmpty
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Price Range
                    Text(
                      'เรทราคาของร้าน',
                      style: AppTextStyles.profileText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [1, 2, 3, 4].map((range) {
                          final isSelected = _priceRange == range;
                          final labels = [
                            '฿ ถูกกว่า 100',
                            '฿฿ 100-250',
                            '฿฿฿ 250-500',
                            '฿฿฿฿ 500+',
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text(
                                labels[range - 1],
                                style: AppTextStyles.hintText.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.lightBlue,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.grey.shade300,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _priceRange = range),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gallery Images
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'รูปภาพบรรยากาศร้าน',
                          style: AppTextStyles.profileText.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _pickGalleryImages,
                          icon: const Icon(
                            Icons.add_photo_alternate,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_existingGalleryUrls.isEmpty &&
                        _newGalleryImages.isEmpty)
                      Center(
                        child: Text(
                          'ยังไม่มีรูปภาพ',
                          style: AppTextStyles.hintText,
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Existing Network Images
                            ..._existingGalleryUrls.map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: NetworkImage(url),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _existingGalleryUrls.remove(url);
                                          });
                                        },
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // New File Images
                            ..._newGalleryImages.map(
                              (file) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: FileImage(file),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _newGalleryImages.remove(file);
                                          });
                                        },
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "บันทึกข้อมูล",
                        style: AppTextStyles.profileText.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
