import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../config/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _businessController.text = user.businessName;
      if (user.profileImagePath != null) {
        _imageFile = File(user.profileImagePath!);
      }
    }
  }

  // FUNGSI AMBIL GAMBAR
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Simpan file ke direktori aplikasi agar permanen
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage =
          await File(pickedFile.path).copy('${directory.path}/$fileName');

      setState(() {
        _imageFile = savedImage;
      });
    }
  }

  // FUNGSI SIMPAN
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final oldUser = auth.currentUser!;

      final updatedUser = UserModel(
        name: _nameController.text,
        businessName: _businessController.text,
        email: oldUser.email, // Email tidak boleh berubah
        password: oldUser.password, // Password tetap
        joinDate: oldUser.joinDate,
        profileImagePath: _imageFile?.path, // Simpan path baru
      );

      await auth.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui!")),
        );
        Navigator.pop(context); // Kembali ke halaman profil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update profil: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dustyWhite,
      appBar: AppBar(
        title: const Text("Edit Profil", style: TextStyle(color: Colors.black)),
        backgroundColor: AppColors.dustyWhite,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. FOTO PROFIL
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? Icon(Icons.person,
                              size: 60, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.dustyOrchid,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. FORM INPUT
              TextFormField(
                controller: _nameController,
                decoration: _inputDecor("Nama Lengkap"),
                validator: (v) => v!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessController,
                decoration: _inputDecor("Nama Bisnis"),
                validator: (v) =>
                    v!.isEmpty ? "Nama bisnis tidak boleh kosong" : null,
              ),
              const SizedBox(height: 16),
              // Email Read Only
              TextFormField(
                initialValue: Provider.of<AuthProvider>(context, listen: false)
                    .currentUser
                    ?.email,
                readOnly: true,
                decoration: _inputDecor("Email")
                    .copyWith(filled: true, fillColor: Colors.grey[100]),
              ),

              const SizedBox(height: 40),

              // 3. TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dustyOrchid,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SIMPAN PERUBAHAN"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
