import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart'; // Import AuthProvider
import 'booking_detail_screen.dart';
import 'edit_booking_screen.dart';
import '../utils/pdf_helper.dart'; // Import Pdf Helper

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
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

    // Ambil Data Bisnis User
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessName = authProvider.currentUser?.businessName ?? "Riasin MUA";

    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final transactions = provider.paidBookings.where((b) {
      return b.clientName.toLowerCase().contains(_searchKeyword.toLowerCase());
    }).toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.dustyWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Payment",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
                fontSize: 22)),
        centerTitle: true,
        backgroundColor: AppColors.dustyWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchKeyword = val),
              decoration: InputDecoration(
                hintText: "Cari nama client...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 20, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchKeyword = "");
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatCard("Jumlah DP", "${provider.countTransactionDP}",
                    AppColors.poppyPink),
                _buildStatCard("Jumlah Pelunasan",
                    "${provider.countTransactionPaid}", AppColors.forest),
                _buildStatCard(
                    "Total DP",
                    currencyFormatter.format(provider.totalMoneyDP),
                    AppColors.brightBlue),
                _buildStatCard(
                    "Total Pelunasan",
                    currencyFormatter.format(provider.totalMoneyPaid),
                    AppColors.sunshine),
              ],
            ),
            const SizedBox(height: 24),
            transactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                            _searchKeyword.isEmpty
                                ? "Belum ada data pembayaran."
                                : "Data tidak ditemukan.",
                            style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (ctx, i) => _buildTransactionCard(
                        context, transactions[i], businessName),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    final textColor =
        (color == AppColors.sunshine) ? AppColors.forest : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Tambahkan parameter businessName
  Widget _buildTransactionCard(
      BuildContext context, BookingModel booking, String businessName) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr =
        DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(booking.date);

    String badgeText = "DP";
    Color badgeColor = AppColors.brightBlue;
    double amountToShow = booking.depositAmount;

    if (booking.paymentStatus == PaymentStatus.paid) {
      badgeText = "Pelunasan";
      badgeColor = AppColors.forest;
      amountToShow = booking.totalPrice;
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(booking.clientName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif')),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(badgeText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(currencyFormatter.format(amountToShow),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(dateStr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Pass businessName here
                    PdfHelper.printInvoice(booking, businessName);
                  },
                  icon:
                      const Icon(Icons.print, size: 16, color: AppColors.ruby),
                  label: const Text("Cetak Invoice",
                      style: TextStyle(color: AppColors.ruby, fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.poppyPink),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _smallActionButton(
                  label: "Edit",
                  icon: Icons.edit_outlined,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                EditBookingScreen(booking: booking)));
                  }),
            ],
          )
        ],
      ),
    );
  }

  Widget _smallActionButton(
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
