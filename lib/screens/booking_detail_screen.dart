import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart'; // Import AuthProvider
import 'edit_booking_screen.dart';
import '../utils/pdf_helper.dart';

class BookingDetailScreen extends StatelessWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    // Ambil Data Bisnis User
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessName = authProvider.currentUser?.businessName ?? "Riasin MUA";

    BookingModel? booking;
    try {
      booking = provider.bookings.firstWhere((b) => b.id == bookingId);
    } catch (e) {
      booking = null;
    }

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detail Booking")),
        body: const Center(child: Text("Data booking tidak ditemukan")),
      );
    }

    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status) {
      case BookingStatus.scheduled:
        statusColor = AppColors.brightBlue;
        statusText = "Jadwal Aktif";
        statusIcon = Icons.event;
        break;
      case BookingStatus.completed:
        statusColor = AppColors.forest;
        statusText = "Selesai";
        statusIcon = Icons.check_circle;
        break;
      case BookingStatus.canceled:
        statusColor = AppColors.ruby;
        statusText = "Dibatalkan";
        statusIcon = Icons.cancel;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.dustyWhite,
      appBar: AppBar(
        title:
            const Text("Detail Booking", style: TextStyle(color: Colors.black)),
        backgroundColor: AppColors.dustyWhite,
        elevation: 0,
        leading: BackButton(
            color: Colors.black, onPressed: () => Navigator.pop(context)),
        actions: [
          // TOMBOL CETAK INVOICE (Updated Parameter)
          IconButton(
            icon: const Icon(Icons.print, color: Colors.black),
            onPressed: () => PdfHelper.printInvoice(booking!, businessName),
          ),

          if (booking.status != BookingStatus.canceled)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditBookingScreen(booking: booking!)));
              },
            ),

          if (booking.status == BookingStatus.canceled ||
              booking.status == BookingStatus.completed)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () =>
                  _confirmDeleteForever(context, provider, booking!.id),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 12),
                  Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  if (booking.status == BookingStatus.canceled)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text("(Fee +50k)",
                          style: TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic)),
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Informasi Client",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _infoRow(Icons.person, "Nama Client", booking.clientName),
            _infoRow(Icons.phone, "Nomor HP", booking.clientPhone),
            _infoRow(Icons.calendar_today, "Tanggal",
                DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(booking.date)),
            _infoRow(Icons.access_time, "Jam",
                DateFormat('HH:mm').format(booking.date)),
            if (booking.isVip)
              _infoRow(Icons.star, "Status", "VIP Client",
                  color: AppColors.sunshine),
            const Divider(height: 40),
            const Text("Rincian Layanan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  _priceRow("Layanan", booking.serviceName),
                  const Divider(),
                  _priceRow("Total Harga",
                      currencyFormatter.format(booking.totalPrice),
                      isBold: true),
                  _priceRow("Deposit (DP)",
                      currencyFormatter.format(booking.depositAmount),
                      color: AppColors.forest),
                  _priceRow("Sisa Bayar",
                      currencyFormatter.format(booking.remainingBalance),
                      color: booking.remainingBalance > 0
                          ? AppColors.ruby
                          : AppColors.forest,
                      isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (booking.paymentStatus != PaymentStatus.paid &&
                booking.status != BookingStatus.canceled)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      _confirmPelunasan(context, provider, booking!),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text("Tandai Lunas"),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.forest),
                ),
              ),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text("Catatan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sunshine.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(booking.notes!),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: booking.status == BookingStatus.scheduled
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ]),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _confirmCancel(context, provider, booking!),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: AppColors.ruby,
                          side: const BorderSide(color: AppColors.ruby),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("Batalkan"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.updateBookingStatus(
                            booking!.id, BookingStatus.completed);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Booking Selesai!")));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ruby,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text("Selesai"),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color ?? Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black)),
        ],
      ),
    );
  }

  void _confirmCancel(
      BuildContext context, BookingProvider provider, BookingModel booking) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Batalkan Jadwal?"),
              content: const Text(
                  "Jadwal akan dibatalkan. Sistem akan mencatat keuntungan Rp 50.000 (Cancellation Fee)."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Kembali")),
                TextButton(
                    onPressed: () {
                      provider.updateBookingStatus(
                          booking.id, BookingStatus.canceled);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Jadwal dibatalkan (+Rp 50rb)")));
                    },
                    child: const Text("Ya, Batalkan",
                        style: TextStyle(color: Colors.red))),
              ],
            ));
  }

  void _confirmPelunasan(
      BuildContext context, BookingProvider provider, BookingModel booking) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Konfirmasi Pelunasan"),
              content: Text("Tandai pembayaran ini sebagai LUNAS?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Batal")),
                TextButton(
                    onPressed: () {
                      provider.updatePayment(booking.id, booking.totalPrice);
                      Navigator.pop(ctx);
                    },
                    child: const Text("Ya, Lunas",
                        style: TextStyle(color: Colors.green))),
              ],
            ));
  }

  void _confirmDeleteForever(
      BuildContext context, BookingProvider provider, String id) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Hapus Permanen?"),
              content: const Text("Data akan hilang selamanya. Lanjutkan?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Batal")),
                TextButton(
                    onPressed: () {
                      provider.deleteBooking(id);
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text("Hapus",
                        style: TextStyle(color: Colors.red))),
              ],
            ));
  }
}
