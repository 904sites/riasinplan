import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart'; // Import Auth Provider

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final _footerController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String _userId = ""; // Simpan ID User

  @override
  void initState() {
    super.initState();
    // Ambil ID User setelah widget dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        _userId = auth.currentUser!.email;
        _loadSettings(); // Load data spesifik user ini
      }
    });
  }

  @override
  void dispose() {
    _footerController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (_userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Gunakan Key Unik: inv_footer_email@gmail.com
      _footerController.text = prefs.getString('inv_footer_$_userId') ??
          "Terima kasih telah menggunakan jasa kami.";
      _addressController.text = prefs.getString('inv_address_$_userId') ?? "";
    });
  }

  Future<void> _saveSettings() async {
    if (_userId.isEmpty) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    // Simpan ke Key Unik
    await prefs.setString('inv_footer_$_userId', _footerController.text);
    await prefs.setString('inv_address_$_userId', _addressController.text);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengaturan Invoice Disimpan!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pengaturan Invoice",
            style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Informasi Bisnis",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("Alamat ini akan muncul di kop invoice.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: _inputDecor("Alamat Lengkap"),
            ),
            const SizedBox(height: 24),
            const Text("Catatan Kaki (Footer)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("Pesan ini akan muncul di bagian bawah invoice.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: _footerController,
              maxLines: 2,
              decoration:
                  _inputDecor("Contoh: Terima kasih, transfer ke BCA 123..."),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dustyOrchid,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("SIMPAN PENGATURAN"),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.dustyOrchid)),
    );
  }
}
