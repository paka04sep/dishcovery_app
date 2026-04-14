import 'dart:io';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  String? _existingProfileUrl;
  bool _hasChanges = false;
  String _initialUsername = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
    _usernameController.addListener(_checkChanges);
  }

  void _checkChanges() {
    final hasChanges =
        _usernameController.text.trim() != _initialUsername ||
        _selectedImage != null;
    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_checkChanges);
    _usernameController.dispose();
    super.dispose();
  }

  void _loadCurrentProfile() {
    final userModel = RestaurantService.instance.userModel;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Username logic
    if (userModel?.username != null && userModel!.username!.isNotEmpty) {
      _usernameController.text = userModel.username!;
    } else if (firebaseUser?.displayName != null &&
        firebaseUser!.displayName!.isNotEmpty) {
      _usernameController.text = firebaseUser.displayName!;
    } else {
      _usernameController.text = firebaseUser?.email?.split('@')[0] ?? '';
    }

    _initialUsername = _usernameController.text.trim();

    // Profile picture logic
    _existingProfileUrl =
        userModel?.profilePictureUrl ?? firebaseUser?.photoURL;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _checkChanges();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String? newPicUrl = _existingProfileUrl;

      // 1. Upload image to Firebase Storage if a new image was picked
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'profile_pictures/${user.uid}.jpg',
        );
        await storageRef.putFile(_selectedImage!);
        newPicUrl = await storageRef.getDownloadURL();
      }

      final newUsername = _usernameController.text.trim();

      // 2. Update FirebaseAuth profile
      await user.updateDisplayName(newUsername);
      if (newPicUrl != null) {
        await user.updatePhotoURL(newPicUrl);
      }

      // 3. Update Firestore UserModel
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': newUsername,
        if (newPicUrl != null) 'profilePictureUrl': newPicUrl,
      }, SetOptions(merge: true));

      // 4. Force RestaurantService to fetch new user data
      // This will update local `userModel` property and notify listeners
      // Note: check fetchUserModel implementation in your codebase, it usually updates state natively.
      await RestaurantService.instance.fetchUserModel();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'อัปเดตโปรไฟล์เรียบร้อยแล้ว',
              style: AppTextStyles.restaurantInDetails,
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          text: 'แก้ไขโปรไฟล์',
          style: AppTextStyles.restaurantHeaderDetails,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('บันทึก', style: AppTextStyles.profileText),
              onPressed: _isLoading ? null : _saveProfile,
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (_existingProfileUrl != null
                                  ? NetworkImage(_existingProfileUrl!)
                                  : null),
                        child:
                            (_selectedImage == null &&
                                _existingProfileUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อผู้ใช้ (Username)',
                  labelStyle: AppTextStyles.restaurantInDetails.copyWith(
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
