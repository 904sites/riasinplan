import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/booking_provider.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  // Pilihan Metode Pembayaran
  String _selectedPayment = 'E-Wallet (GoPay/OVO/Dana)';

  final List<String> _paymentMethods = [
    'E-Wallet (GoPay/OVO/Dana)',
    'Transfer Bank (BCA/Mandiri)',
    'Kartu Kredit / Debit',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final isVip = provider.isPremiumUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isVip ? "Status Langganan" : "Upgrade ke VIP"),
        backgroundColor: isVip ? AppColors.sorbetStem : null, // Hijau jika VIP
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: isVip
            ? _buildActiveVipView(context, provider) // Tampilan Jika SUDAH VIP
            : _buildSubscribeView(context, provider), // Tampilan Jika BELUM VIP
      ),
    );
  }

  // --- TAMPILAN 1: FORM BERLANGGANAN (BELUM VIP) ---
  Widget _buildSubscribeView(BuildContext context, BookingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
        const SizedBox(height: 24),
        const Text(
          "RIASIN VIP",
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.dustyOrchid),
        ),
        const SizedBox(height: 12),
        const Text(
          "Nikmati akses tanpa batas untuk bisnis makeup Anda.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),

        // List Fitur
        _buildFeature("Unlimited Booking (Bebas Kuota)"),
        _buildFeature("Lencana VIP di Dashboard"),
        _buildFeature("Backup Data Prioritas"),

        const Divider(height: 40),

        // Pilihan Metode Pembayaran
        const Align(
            alignment: Alignment.centerLeft,
            child: Text("Pilih Metode Pembayaran:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _paymentMethods.map((method) {
              return RadioListTile<String>(
                title: Text(method, style: const TextStyle(fontSize: 14)),
                value: method,
                groupValue: _selectedPayment,
                activeColor: AppColors.dustyOrchid,
                onChanged: (val) {
                  setState(() {
                    _selectedPayment = val!;
                  });
                },
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 32),

        // Harga & Tombol
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.powderedLilac,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Tagihan", style: TextStyle(fontSize: 12)),
                  Text("Rp 49.000",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dustyOrchid,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // PROSES PEMBAYARAN & AKTIVASI
                  provider.subscribeToVip(_selectedPayment);

                  // Notifikasi Sukses
                  _showNotificationDialog(context, "Pembayaran Berhasil!",
                      "Selamat, akun Anda kini sudah VIP menggunakan metode $_selectedPayment.",
                      isSuccess: true);
                },
                child: const Text("BAYAR SEKARANG"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAMPILAN 2: STATUS AKTIF (SUDAH VIP) ---
  Widget _buildActiveVipView(BuildContext context, BookingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppColors.sorbetStem.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle,
              size: 80, color: AppColors.sorbetStem),
        ),
        const SizedBox(height: 24),
        const Text(
          "VIP AKTIF",
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.sorbetStem),
        ),
        const SizedBox(height: 8),
        Text(
          "Terima kasih telah berlangganan.",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 40),

        // Detail Langganan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow("Paket", "Riasin VIP Monthly"),
              const Divider(),
              _buildInfoRow("Harga", "Rp 49.000 / bulan"),
              const Divider(),
              _buildInfoRow("Metode Bayar", provider.vipPaymentMethod ?? "-"),
              const Divider(),
              _buildInfoRow("Status", "Auto-Renewal",
                  color: AppColors.sorbetStem),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Tombol Batal
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              // Dialog Konfirmasi Batal
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        title: const Text("Batalkan VIP?"),
                        content: const Text(
                            "Anda akan kehilangan akses unlimited booking dan kembali ke kuota gratis (15/bulan)."),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Kembali")),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              onPressed: () {
                                // LOGIKA BATAL
                                provider.cancelSubscription();
                                Navigator.pop(ctx); // Tutup dialog konfirmasi

                                // Notifikasi Batal Sukses
                                _showNotificationDialog(
                                    context,
                                    "Berlangganan Dibatalkan",
                                    "Akun Anda telah kembali ke paket Gratis (Free Plan).",
                                    isSuccess: false);
                              },
                              child: const Text("Ya, Batalkan")),
                        ],
                      ));
            },
            child: const Text("BATALKAN BERLANGGANAN"),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Pembatalan akan berlaku segera.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.sorbetStem),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- WIDGET ROW YANG SUDAH DIPERBAIKI (ANTI OVERFLOW) ---
  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            CrossAxisAlignment.start, // Agar rapi jika teks turun
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16), // Jarak minimal
          Expanded(
            // <--- KUNCI PERBAIKAN: Membungkus nilai agar bisa turun baris
            child: Text(
              value,
              textAlign: TextAlign.right, // Tetap rata kanan
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi Popup Notifikasi Sukses/Batal
  void _showNotificationDialog(
      BuildContext context, String title, String message,
      {required bool isSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.info_outline,
                color: isSuccess ? AppColors.sorbetStem : Colors.orange,
                size: 60),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dustyOrchid,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Tutup Dialog Notif
                  // Opsional: Jika sukses subscribe, bisa langsung kembali ke Dashboard
                  if (isSuccess) Navigator.pop(context);
                },
                child: const Text("OKE"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
