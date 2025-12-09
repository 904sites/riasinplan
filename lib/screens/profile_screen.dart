import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'invoice_settings_screen.dart';
import 'edit_profile_screen.dart'; // Import Halaman Edit

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer agar UI otomatis update saat data user berubah
    return Consumer<AuthProvider>(builder: (context, auth, child) {
      final user = auth.currentUser;

      return Scaffold(
        backgroundColor: AppColors.dustyWhite,
        appBar: AppBar(
          title:
              const Text("Profil Saya", style: TextStyle(color: Colors.black)),
          backgroundColor: AppColors.dustyWhite,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 1. FOTO PROFIL & NAMA
              Center(
                child: Column(
                  children: [
                    // Logika Tampilan Foto
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.dustyOrchid.withOpacity(0.2),
                      backgroundImage: (user?.profileImagePath != null &&
                              File(user!.profileImagePath!).existsSync())
                          ? FileImage(File(user.profileImagePath!))
                          : null,
                      child: (user?.profileImagePath == null ||
                              !File(user!.profileImagePath!).existsSync())
                          ? Text(
                              user?.name.substring(0, 1).toUpperCase() ?? "U",
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dustyOrchid),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? "Nama User",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.businessName ?? "Nama Bisnis",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. DAFTAR MENU
              _buildMenuTile(
                icon: Icons.edit_outlined,
                title: "Edit Profil",
                onTap: () {
                  // Navigasi ke Halaman Edit Profil
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  );
                },
              ),

              _buildMenuTile(
                icon: Icons.receipt_long_outlined,
                title: "Pengaturan Invoice",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InvoiceSettingsScreen()),
                  );
                },
              ),

              const Divider(height: 40),

              _buildMenuTile(
                icon: Icons.logout,
                title: "Keluar (Logout)",
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Konfirmasi"),
                      content: const Text("Yakin ingin keluar aplikasi?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Batal")),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await auth.logout();

                            if (!context.mounted) return;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text("Keluar",
                              style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
    Color iconColor = Colors.grey,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: textColor, fontSize: 16)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
