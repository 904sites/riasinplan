import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import 'booking_detail_screen.dart';
import '../utils/pdf_helper.dart';
import '../providers/auth_provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    // Ambil Nama Bisnis untuk keperluan Cetak di sini juga jika perlu
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessName = authProvider.currentUser?.businessName ?? "Riasin MUA";

    final bookings = provider.bookings;

    // Filter data
    final filteredList = bookings.where((b) {
      final name = b.clientName.toLowerCase();
      final id = b.id.toLowerCase();
      final keyword = _searchKeyword.toLowerCase();
      return name.contains(keyword) || id.contains(keyword);
    }).toList();

    // Urutkan dari yang terbaru
    filteredList.sort((a, b) => b.date.compareTo(a.date));

    // Hitung Statistik
    int totalInv = bookings.length;
    int lunasInv =
        bookings.where((b) => b.paymentStatus == PaymentStatus.paid).length;
    int unpaidInv = totalInv - lunasInv;

    return Scaffold(
      backgroundColor: AppColors.dustyWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Daftar Invoice",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif')),
        centerTitle: true,
        backgroundColor: AppColors.dustyWhite,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text("$totalInv Inv",
                  style: const TextStyle(
                      color: AppColors.ruby, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR (STYLE BARU - MIRIP PAYMENT)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchKeyword = val),
              decoration: InputDecoration(
                hintText: "Cari nomor invoice, client...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 20, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchKeyword = "");
                        })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.white,
                // Border Style: Radius 12
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.ruby)),
              ),
            ),
          ),

          // 2. STATISTIK KOTAK
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatBox(
                    "Total",
                    totalInv.toString(),
                    AppColors.brightBlue.withOpacity(0.2),
                    AppColors.brightBlue),
                const SizedBox(width: 8),
                _buildStatBox("Lunas", lunasInv.toString(),
                    AppColors.forest.withOpacity(0.2), AppColors.forest),
                const SizedBox(width: 8),
                _buildStatBox(
                    "Belum Lunas",
                    unpaidInv.toString(),
                    AppColors.sunshine.withOpacity(0.4),
                    const Color(0xFFC99800)), // Kuning agak gelap untuk teks
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. LIST INVOICE CARD
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("Data tidak ditemukan",
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (ctx, i) => _InvoiceCard(
                        booking: filteredList[i], businessName: businessName),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
      String label, String count, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(label,
                style:
                    TextStyle(color: textColor.withOpacity(0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CARD INVOICE ---
class _InvoiceCard extends StatelessWidget {
  final BookingModel booking;
  final String businessName;

  const _InvoiceCard({required this.booking, required this.businessName});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isPaid = booking.paymentStatus == PaymentStatus.paid;

    final dateCode = DateFormat('yyyyMMdd').format(booking.date);
    final shortId =
        booking.id.length > 4 ? booking.id.substring(0, 4) : booking.id;
    final invoiceNo = "INV/$dateCode/${shortId.toUpperCase()}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(invoiceNo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.forest.withOpacity(0.1)
                        : AppColors.sunshine.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(isPaid ? "Lunas" : "Belum Lunas",
                    style: TextStyle(
                        color: isPaid ? AppColors.forest : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 8),

          // Nama & Layanan
          Text(booking.clientName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(booking.serviceName,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),

          const Divider(height: 24),

          // Rincian
          _rowPrice("Total DP", booking.depositAmount, currencyFormatter),
          _rowPrice("Total Tagihan", booking.totalPrice, currencyFormatter,
              isBold: true),

          if (!isPaid)
            _rowPrice("Sisa Bayar", booking.remainingBalance, currencyFormatter,
                color: AppColors.ruby),

          const SizedBox(height: 16),

          // Tombol Aksi
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Cetak Invoice Langsung
                PdfHelper.printInvoice(booking, businessName);
              },
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text("Lihat / Cetak"),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ruby,
                  side: const BorderSide(color: AppColors.poppyPink)),
            ),
          )
        ],
      ),
    );
  }

  Widget _rowPrice(String label, double amount, NumberFormat fmt,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(fmt.format(amount),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black)),
        ],
      ),
    );
  }
}
