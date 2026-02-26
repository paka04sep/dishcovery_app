import 'dart:io';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';

class ManageMenuScreen extends StatefulWidget {
  final RestaurantDetailsData restaurant;

  const ManageMenuScreen({super.key, required this.restaurant});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  bool _isLoading = false;

  late List<MenuCategory> _categories;
  late List<MenuItem> _items;

  Map<String, File> _newMenuImages = {};
  List<String> _deletedCategoryIds = [];
  List<String> _deletedItemIds = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.restaurant.menuCategories)
      ..sort((a, b) => a.order.compareTo(b.order));
    _items = List.from(widget.restaurant.menuItems);
  }

  void _addCategory() {
    String categoryName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'เพิ่มหมวดหมู่เมนู',
          style: AppTextStyles.profileText.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'ชื่อหมวดหมู่ (เช่น อาหารจานหลัก, ของทานเล่น)',
            hintStyle: AppTextStyles.hintText.copyWith(),
          ),
          onChanged: (v) => categoryName = v.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.profileText.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (categoryName.isNotEmpty) {
                if (_categories.any((c) => c.name == categoryName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('มีหมวดหมู่นี้อยู่แล้ว')),
                  );
                  return;
                }
                setState(() {
                  _categories.add(
                    MenuCategory(
                      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
                      name: categoryName,
                      order: _categories.length,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              'เพิ่ม',
              style: AppTextStyles.profileText.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _editCategory(MenuCategory category) {
    String categoryName = category.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'แก้ไขหมวดหมู่',
          style: AppTextStyles.profileText.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: TextEditingController(text: category.name),
          decoration: InputDecoration(
            hintText: 'ชื่อหมวดหมู่',
            hintStyle: AppTextStyles.hintText.copyWith(),
          ),
          onChanged: (v) => categoryName = v.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Delete Option
              Navigator.pop(context);
              _deleteCategory(category);
            },
            child: Text(
              'ลบ',
              style: AppTextStyles.profileText.copyWith(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.profileText.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (categoryName.isNotEmpty) {
                setState(() {
                  final index = _categories.indexWhere(
                    (c) => c.id == category.id,
                  );
                  if (index != -1) {
                    _categories[index] = MenuCategory(
                      id: category.id,
                      name: categoryName,
                      order: category.order,
                    );
                    // Also update category name in all items using this category
                    for (int i = 0; i < _items.length; i++) {
                      if (_items[i].category == category.name) {
                        _items[i] = _items[i].copyWith(category: categoryName);
                      }
                    }
                  }
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              'บันทึก',
              style: AppTextStyles.profileText.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(MenuCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ยืนยันการลบ',
          style: AppTextStyles.profileText.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'คุณต้องการลบหมวดหมู่ ${category.name} และเมนูทั้งหมดในหมวดหมู่นี้หรือไม่?',
          style: AppTextStyles.profileText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.profileText.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (!category.id.startsWith('new_')) {
                  _deletedCategoryIds.add(category.id);
                }
                _categories.removeWhere((c) => c.id == category.id);

                final itemsToDelete = _items
                    .where((i) => i.category == category.name)
                    .toList();
                for (var item in itemsToDelete) {
                  if (!item.id.startsWith('new_')) {
                    _deletedItemIds.add(item.id);
                  }
                  _items.removeWhere((i) => i.id == item.id);
                  _newMenuImages.remove(item.id);
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'ลบ',
              style: AppTextStyles.profileText.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _addOrEditItem({MenuItem? existingItem}) {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มหมวดหมู่ก่อนเพิ่มเมนู')),
      );
      return;
    }

    String itemName = existingItem?.name ?? '';
    String itemPrice = existingItem?.price.toString() ?? '';
    String selectedCat = existingItem?.category ?? _categories.first.name;
    bool isAvailable = existingItem?.isAvailable ?? true;
    bool isRecommended = existingItem?.isRecommended ?? false;
    File? pickedImage = _newMenuImages[existingItem?.id];
    String currentImageUrl = existingItem?.menuImage ?? '';
    final String tempId =
        existingItem?.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existingItem == null ? 'เพิ่มเมนูอาหาร' : 'แก้ไขเมนูอาหาร',
              style: AppTextStyles.profileText.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
                          pickedImage = File(img.path);
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: pickedImage != null
                            ? DecorationImage(
                                image: FileImage(pickedImage!),
                                fit: BoxFit.cover,
                              )
                            : (currentImageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(currentImageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child: pickedImage == null && currentImageUrl.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: itemName)
                      ..selection = TextSelection.collapsed(
                        offset: itemName.length,
                      ),
                    decoration: InputDecoration(
                      hintText: 'ชื่อเมนู',
                      hintStyle: AppTextStyles.hintText,
                    ),
                    onChanged: (v) => itemName = v,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: itemPrice)
                      ..selection = TextSelection.collapsed(
                        offset: itemPrice.length,
                      ),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'ราคา (บาท)',
                      hintStyle: AppTextStyles.hintText,
                    ),
                    onChanged: (v) => itemPrice = v,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _categories.any((c) => c.name == selectedCat)
                        ? selectedCat
                        : _categories.first.name,
                    decoration: const InputDecoration(labelText: 'หมวดหมู่'),
                    items: _categories.map((c) {
                      return DropdownMenuItem(
                        value: c.name,
                        child: Text(c.name, style: AppTextStyles.profileText),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) selectedCat = v;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      "มีสินค้า (Available)",
                      style: AppTextStyles.profileText,
                    ),
                    value: isAvailable,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) => setDialogState(() => isAvailable = val),
                  ),
                  SwitchListTile(
                    title: Text(
                      "เมนูแนะนำ (Recommended)",
                      style: AppTextStyles.profileText,
                    ),
                    value: isRecommended,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      if (val) {
                        int recCount = _items
                            .where((i) => i.isRecommended && i.id != tempId)
                            .length;
                        if (recCount >= 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('เลือกเมนูแนะนำได้สูงสุด 6 เมนู'),
                            ),
                          );
                          return;
                        }
                      }
                      setDialogState(() => isRecommended = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              if (existingItem != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteItem(existingItem);
                  },
                  child: Text(
                    'ลบ',
                    style: AppTextStyles.profileText.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ยกเลิก',
                  style: AppTextStyles.profileText.copyWith(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (itemName.isEmpty || itemPrice.isEmpty) return;
                  int price = int.tryParse(itemPrice) ?? 0;

                  setState(() {
                    final item = MenuItem(
                      id: tempId,
                      name: itemName,
                      price: price,
                      category: selectedCat,
                      menuImage: pickedImage == null ? currentImageUrl : '',
                      isAvailable: isAvailable,
                      isRecommended: isRecommended,
                    );

                    if (pickedImage != null) {
                      _newMenuImages[tempId] = pickedImage!;
                    }

                    if (existingItem != null) {
                      final index = _items.indexWhere(
                        (i) => i.id == existingItem.id,
                      );
                      if (index != -1) _items[index] = item;
                    } else {
                      _items.add(item);
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: Text(
                  'บันทึก',
                  style: AppTextStyles.profileText.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ยืนยันการลบ',
          style: AppTextStyles.profileText.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'ต้องการลบเมนู ${item.name} หรือไม่?',
          style: AppTextStyles.profileText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.profileText.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (!item.id.startsWith('new_')) {
                  _deletedItemIds.add(item.id);
                }
                _items.removeWhere((i) => i.id == item.id);
                _newMenuImages.remove(item.id);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'ลบ',
              style: AppTextStyles.profileText.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Re-order categories based on current list order
      for (int i = 0; i < _categories.length; i++) {
        _categories[i] = _categories[i].copyWith(order: i);
      }

      await RestaurantService.instance.updateRestaurantMenus(
        widget.restaurant.id,
        categories: _categories,
        items: _items,
        newMenuImages: _newMenuImages.isEmpty ? null : _newMenuImages,
        deletedCategoryIds: _deletedCategoryIds.isEmpty
            ? null
            : _deletedCategoryIds,
        deletedItemIds: _deletedItemIds.isEmpty ? null : _deletedItemIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกเมนูสำเร็จ')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          text: "จัดการเมนูอาหาร",
          style: AppTextStyles.profileText.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _categories.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _categories.removeAt(oldIndex);
                        _categories.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, catIndex) {
                      final category = _categories[catIndex];
                      final categoryItems = _items
                          .where((i) => i.category == category.name)
                          .toList();

                      return Container(
                        key: ValueKey(category.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              color: Colors.grey.shade100,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.drag_indicator,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        category.name,
                                        style: AppTextStyles.profileText
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: AppColors.primaryBlue,
                                    ),
                                    onPressed: () => _editCategory(category),
                                  ),
                                ],
                              ),
                            ),
                            ...categoryItems.map((item) {
                              final image = _newMenuImages[item.id] != null
                                  ? FileImage(_newMenuImages[item.id]!)
                                        as ImageProvider
                                  : (item.menuImage.isNotEmpty
                                        ? NetworkImage(item.menuImage)
                                        : null);

                              return ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                    image: image != null
                                        ? DecorationImage(
                                            image: image,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: image == null
                                      ? const Icon(
                                          Icons.fastfood,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: AppTextStyles.profileText,
                                      ),
                                    ),
                                    if (!item.isAvailable)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "หมด",
                                          style: AppTextStyles.profileText
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                    if (item.isRecommended)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.thumb_up,
                                          color: Colors.orange,
                                          size: 14,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  '฿${item.price}',
                                  style: AppTextStyles.hintText,
                                ),
                                trailing: const Icon(Icons.edit, size: 18),
                                onTap: () => _addOrEditItem(existingItem: item),
                              );
                            }),
                            const Divider(height: 1),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "addCat",
            onPressed: _addCategory,
            backgroundColor: AppColors.lightBlue,
            child: const Icon(Icons.category, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "addItem",
            onPressed: () => _addOrEditItem(),
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
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
      ),
    );
  }
}
