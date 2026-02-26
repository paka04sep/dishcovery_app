import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'package:dishcovery_app/screen/restarurant_detail_screen.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/app_init_screen.dart';

class AddRestaurantDetailScreen extends StatefulWidget {
  final RestaurantDetailsData initialData;

  const AddRestaurantDetailScreen({super.key, required this.initialData});

  @override
  State<AddRestaurantDetailScreen> createState() =>
      _AddRestaurantDetailScreenState();
}

class _AddRestaurantDetailScreenState extends State<AddRestaurantDetailScreen> {
  late RestaurantDetailsData _details;
  bool _isSubmitting = false;

  File? _coverImageFile;
  List<File> _galleryImageFiles = [];
  Map<String, File> _menuImageFiles = {}; // menu item id -> File

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _details = widget.initialData;
  }

  void _submitToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppInitAddRestaurant(
          details: _details,
          coverImage: _coverImageFile,
          galleryImages: _galleryImageFiles,
          menuImages: _menuImageFiles,
        ),
      ),
    );
  }

  void _previewRestaurant() {
    final previewData = RestaurantDetailsData(
      id: 'preview',
      name: _details.name.isEmpty ? 'ชื่อร้าน (ตัวอย่าง)' : _details.name,
      cuisine: _details.cuisine,
      priceRange: _details.priceRange,
      rating: 0.0,
      latitude: _details.latitude,
      longitude: _details.longitude,
      address: _details.address,
      phone: _details.phone,
      imageUrl: _coverImageFile != null
          ? _coverImageFile!.path
          : (_details.imageUrl.isNotEmpty
                ? _details.imageUrl
                : 'https://via.placeholder.com/400x300?text=Preview'),
      description: _details.description.isEmpty
          ? 'รายละเอียดร้านอาหาร'
          : _details.description,
      openingHours: _details.openingHours,
      galleryImages: _galleryImageFiles.map((f) => f.path).toList(),
      menuCategories: _details.menuCategories,
      menuItems: _details.menuItems.map((m) {
        return MenuItem(
          id: m.id,
          name: m.name,
          price: m.price,
          category: m.category,
          menuImage: _menuImageFiles.containsKey(m.id)
              ? _menuImageFiles[m.id]!.path
              : m.menuImage,
          isRecommended: m.isRecommended,
          isAvailable: m.isAvailable,
        );
      }).toList(),
      status: 'pending',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantDetailScreen(restaurant: previewData),
      ),
    );
  }

  Future<void> _editCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _coverImageFile = File(image.path);
      });
    }
  }

  Future<void> _addGalleryImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _galleryImageFiles.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  void _addMenuCategory() {
    String categoryName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'เพิ่มหมวดหมู่เมนู',
          style: AppTextStyles.profileText.copyWith(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'ชื่อหมวดหมู่',
            hintStyle: AppTextStyles.hintText.copyWith(),
          ),
          onChanged: (v) => categoryName = v.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.profileText.copyWith(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (categoryName.isNotEmpty) {
                // Check duplicate
                if (_details.menuCategories.any(
                  (c) => c.name == categoryName,
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('มีหมวดหมู่นี้อยู่แล้ว')),
                  );
                  return;
                }
                setState(() {
                  final newCats = List<MenuCategory>.from(
                    _details.menuCategories,
                  );
                  newCats.add(
                    MenuCategory(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: categoryName,
                      order: newCats.length,
                    ),
                  );
                  _details = _details.copyWith(menuCategories: newCats);
                });
                Navigator.pop(context);
              }
            },
            child: Text(
              'เพิ่ม',
              style: AppTextStyles.profileText.copyWith(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _addMenuItem() {
    if (_details.menuCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเพิ่มหมวดหมู่ก่อนเพิ่มเมนู',
            style: AppTextStyles.profileText.copyWith(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      );
      return;
    }

    String itemName = '';
    String itemPrice = '';
    String selectedCat = _details.menuCategories.first.name;
    File? pickedMenuImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'เพิ่มเมนูอาหาร',
              style: AppTextStyles.profileText.copyWith(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final img = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (img != null) {
                        setDialogState(() {
                          pickedMenuImage = File(img.path);
                        });
                      }
                    },
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: pickedMenuImage != null
                            ? DecorationImage(
                                image: FileImage(pickedMenuImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: pickedMenuImage == null
                          ? const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'ชื่อเมนู',
                      hintStyle: AppTextStyles.hintText.copyWith(),
                    ),
                    onChanged: (v) => itemName = v,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'ราคา (บาท)',
                      hintStyle: AppTextStyles.hintText.copyWith(),
                    ),
                    onChanged: (v) => itemPrice = v,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    items: _details.menuCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedCat = v);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'หมวดหมู่',
                      hintStyle: AppTextStyles.hintText.copyWith(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ยกเลิก',
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (itemName.isNotEmpty && itemPrice.isNotEmpty) {
                    final price = int.tryParse(itemPrice);
                    if (price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'กรุณาใส่ราคาเป็นตัวเลขเท่านั้น',
                            style: AppTextStyles.profileText.copyWith(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      final newItems = List<MenuItem>.from(_details.menuItems);
                      final itemId = DateTime.now().millisecondsSinceEpoch
                          .toString();

                      newItems.add(
                        MenuItem(
                          id: itemId,
                          name: itemName,
                          price: price,
                          category: selectedCat,
                        ),
                      );

                      if (pickedMenuImage != null) {
                        _menuImageFiles[itemId] = pickedMenuImage!;
                      }

                      _details = _details.copyWith(menuItems: newItems);
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'เพิ่ม',
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImageFiles.removeAt(index);
    });
  }

  void _removeMenuCategory(MenuCategory cat) {
    setState(() {
      final newCats = _details.menuCategories
          .where((c) => c.id != cat.id)
          .toList();
      final newItems = _details.menuItems
          .where((m) => m.category != cat.name)
          .toList();
      _details = _details.copyWith(
        menuCategories: newCats,
        menuItems: newItems,
      );
    });
  }

  void _removeMenuItem(MenuItem item) {
    setState(() {
      final newItems = _details.menuItems
          .where((m) => m.id != item.id)
          .toList();
      _menuImageFiles.remove(item.id);
      _details = _details.copyWith(menuItems: newItems);
    });
  }

  void _editMenuCategory(MenuCategory oldCat) {
    String categoryName = oldCat.name;
    final TextEditingController controller = TextEditingController(
      text: categoryName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'แก้ไขหมวดหมู่เมนู',
          style: AppTextStyles.profileText.copyWith(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'ชื่อหมวดหมู่',
            hintStyle: AppTextStyles.hintText.copyWith(),
          ),
          onChanged: (v) => categoryName = v.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.profileText.copyWith(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (categoryName.isNotEmpty) {
                if (categoryName != oldCat.name &&
                    _details.menuCategories.any(
                      (c) => c.name == categoryName,
                    )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'มีหมวดหมู่นี้อยู่แล้ว',
                        style: AppTextStyles.profileText.copyWith(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  );
                  return;
                }
                setState(() {
                  final newCats = List<MenuCategory>.from(
                    _details.menuCategories,
                  );
                  final idx = newCats.indexWhere((c) => c.id == oldCat.id);
                  if (idx != -1) {
                    newCats[idx] = MenuCategory(
                      id: oldCat.id,
                      name: categoryName,
                      order: oldCat.order,
                    );
                  }

                  final newItems = _details.menuItems.map((m) {
                    if (m.category == oldCat.name) {
                      return MenuItem(
                        id: m.id,
                        name: m.name,
                        price: m.price,
                        menuImage: m.menuImage,
                        category: categoryName,
                        isRecommended: m.isRecommended,
                        isAvailable: m.isAvailable,
                      );
                    }
                    return m;
                  }).toList();

                  _details = _details.copyWith(
                    menuCategories: newCats,
                    menuItems: newItems,
                  );
                });
                Navigator.pop(context);
              }
            },
            child: Text(
              'บันทึก',
              style: AppTextStyles.profileText.copyWith(
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editMenuItem(MenuItem oldItem) {
    String itemName = oldItem.name;
    String itemPrice = oldItem.price.toString();
    String selectedCat = oldItem.category;
    File? pickedMenuImage = _menuImageFiles[oldItem.id];

    final TextEditingController nameController = TextEditingController(
      text: itemName,
    );
    final TextEditingController priceController = TextEditingController(
      text: itemPrice,
    );

    if (!_details.menuCategories.any((c) => c.name == selectedCat)) {
      if (_details.menuCategories.isNotEmpty) {
        selectedCat = _details.menuCategories.first.name;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'แก้ไขเมนูอาหาร',
              style: AppTextStyles.profileText.copyWith(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final img = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (img != null) {
                        setDialogState(() {
                          pickedMenuImage = File(img.path);
                        });
                      }
                    },
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: pickedMenuImage != null
                            ? DecorationImage(
                                image: FileImage(pickedMenuImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: pickedMenuImage == null
                          ? const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'ชื่อเมนู',
                      hintStyle: AppTextStyles.hintText.copyWith(),
                    ),
                    onChanged: (v) => itemName = v,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'ราคา (บาท)',
                      hintStyle: AppTextStyles.hintText.copyWith(),
                    ),
                    onChanged: (v) => itemPrice = v,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    items: _details.menuCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedCat = v);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'หมวดหมู่',
                      labelStyle: AppTextStyles.hintText.copyWith(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ยกเลิก',
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (itemName.isNotEmpty && itemPrice.isNotEmpty) {
                    final price = int.tryParse(itemPrice);
                    if (price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'กรุณาใส่ราคาเป็นตัวเลขเท่านั้น',
                            style: AppTextStyles.profileText.copyWith(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      final newItems = List<MenuItem>.from(_details.menuItems);
                      final idx = newItems.indexWhere(
                        (m) => m.id == oldItem.id,
                      );
                      if (idx != -1) {
                        newItems[idx] = MenuItem(
                          id: oldItem.id,
                          name: itemName,
                          price: price,
                          category: selectedCat,
                          menuImage: oldItem.menuImage,
                          isRecommended: oldItem.isRecommended,
                          isAvailable: oldItem.isAvailable,
                        );
                      }

                      if (pickedMenuImage != null) {
                        _menuImageFiles[oldItem.id] = pickedMenuImage!;
                      }

                      _details = _details.copyWith(menuItems: newItems);
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'บันทึก',
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'เพิ่มรายละเอียดร้านอาหาร',
          style: AppTextStyles.profileText.copyWith(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye),
            onPressed: _previewRestaurant,
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'เพิ่มรูปหลักของร้านอาหาร',
                    style: AppTextStyles.profileText.copyWith(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header Image Editable
                  GestureDetector(
                    onTap: _editCoverImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                        image: _coverImageFile != null
                            ? DecorationImage(
                                image: FileImage(_coverImageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _coverImageFile == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'เพิ่มรูปภาพปก',
                                    style: AppTextStyles.hintText.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Divider(),

                  // Gallery
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ภาพบรรยากาศร้าน',
                        style: AppTextStyles.profileText.copyWith(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: _addGalleryImage,
                        child: Text(
                          '+ เพิ่ม',
                          style: AppTextStyles.hintText.copyWith(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: _galleryImageFiles.isEmpty ? 50 : 100,
                    child: _galleryImageFiles.isEmpty
                        ? Center(
                            child: Text(
                              'ยังไม่มีรูปบรรยากาศร้าน',
                              style: AppTextStyles.hintText.copyWith(),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _galleryImageFiles.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: FileImage(
                                          _galleryImageFiles[index],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 14,
                                    child: GestureDetector(
                                      onTap: () => _removeGalleryImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),

                  // Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'หมวดหมู่อาหาร',
                        style: AppTextStyles.profileText.copyWith(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: _addMenuCategory,
                        child: Text(
                          '+ เพิ่มหมวดหมู่',
                          style: AppTextStyles.hintText.copyWith(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_details.menuCategories.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          'ยังไม่มีหมวดหมู่อาหาร',
                          style: AppTextStyles.hintText.copyWith(),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: _details.menuCategories
                          .map(
                            (c) => InputChip(
                              label: Text(c.name),
                              onPressed: () => _editMenuCategory(c),
                              avatar: const Icon(Icons.edit, size: 16),
                              onDeleted: () => _removeMenuCategory(c),
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 20),
                  const Divider(),

                  // Menus
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เมนูอาหาร',
                        style: AppTextStyles.profileText.copyWith(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: _addMenuItem,
                        child: Text(
                          '+ เพิ่มเมนู',
                          style: AppTextStyles.hintText.copyWith(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_details.menuItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'ยังไม่มีเมนูอาหาร',
                          style: AppTextStyles.hintText.copyWith(),
                        ),
                      ),
                    )
                  else
                    ..._details.menuCategories.map((cat) {
                      final itemsInCat = _details.menuItems
                          .where((m) => m.category == cat.name)
                          .toList();
                      if (itemsInCat.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          ...itemsInCat
                              .map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: _menuImageFiles[item.id] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            _menuImageFiles[item.id]!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.fastfood,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  title: Text(item.name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${item.price} ฿',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        onPressed: () => _editMenuItem(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () => _removeMenuItem(item),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      );
                    }).toList(),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _submitToAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001738),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'เพิ่มร้านอาหาร',
                      style: AppTextStyles.profileText.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
