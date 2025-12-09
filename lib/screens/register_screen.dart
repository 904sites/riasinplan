import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk input text
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  // Key untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // State untuk Loading dan Password Visibility
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // Bersihkan controller saat halaman ditutup untuk mencegah kebocoran memori
    _nameController.dispose();
    _businessController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _register() async {
    // 1. Validasi Form
    if (_formKey.currentState!.validate()) {
      // 2. Mulai Loading (Tampilkan spinner)
      setState(() {
        _isLoading = true;
      });

      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);

        // Membuat object User baru
        final newUser = UserModel(
          name: _nameController.text.trim(),
          businessName: _businessController.text.trim(),
          email: _emailController.text.trim(),
          password: _passController.text,
          joinDate: DateTime.now(),
        );

        await auth.register(newUser);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Terjadi kesalahan: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Daftar Akun"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black, // Agar teks/icon back berwarna hitam
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mulai Kelola Bisnis MUA Kamu",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Isi data diri untuk membuat akun baru.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // INPUT NAMA
              TextFormField(
                controller: _nameController,
                decoration: _inputDecor("Nama Lengkap", Icons.person_outline),
                textInputAction: TextInputAction.next,
                validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              // INPUT NAMA BISNIS
              TextFormField(
                controller: _businessController,
                decoration: _inputDecor(
                    "Nama Bisnis (Cth: Kirei Salon)", Icons.store_outlined),
                textInputAction: TextInputAction.next,
                validator: (v) => v!.isEmpty ? "Nama bisnis wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              // INPUT EMAIL
              TextFormField(
                controller: _emailController,
                decoration: _inputDecor("Email", Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v!.isEmpty) return "Email wajib diisi";
                  if (!v.contains('@')) return "Email tidak valid";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // INPUT PASSWORD
              TextFormField(
                controller: _passController,
                obscureText:
                    !_isPasswordVisible, // Sembunyikan/Tampilkan password
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  // Tombol mata untuk melihat password
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (v) =>
                    v!.length < 6 ? "Password minimal 6 karakter" : null,
              ),

              const SizedBox(height: 40),

              // TOMBOL DAFTAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors
                        .dustyOrchid, // Pastikan warna ini ada di theme.dart
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  // Jika loading, tombol dimatikan (null) agar tidak bisa diklik 2x
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "DAFTAR SEKARANG",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk styling input
  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dustyOrchid, width: 2),
      ),
    );
  }
}
