import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import 'booking_detail_screen.dart';
import 'add_booking_screen.dart';
import 'upgrade_screen.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        final bookingList = provider.filteredBookings;
        bookingList.sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          backgroundColor: AppColors.dustyWhite,
          appBar: AppBar(
            title: const Text("Daftar Booking",
                style: TextStyle(color: Colors.black)),
            backgroundColor: AppColors.dustyWhite,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              // --- STATISTIK ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: _statCard("Total", "${provider.countMonth}",
                            AppColors.brightBlue)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _statCard("Akan Datang",
                            "${provider.countUpcoming}", AppColors.poppyPink)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _statCard("Pending", "${provider.countPending}",
                            AppColors.sunshine)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- SEARCH BAR (STYLE BARU - MIRIP PAYMENT) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => provider.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: "Cari nama client...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[400]),

                          // Style Baru:
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.ruby)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Filter Tanggal (Ikut menyesuaikan style rounded)
                    InkWell(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          provider.setFilterDate(picked);
                        }
                      },
                      borderRadius:
                          BorderRadius.circular(12), // Radius disamakan
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: provider.filterDate != null
                              ? AppColors.ruby
                              : Colors.white, // Putih jika tidak aktif
                          borderRadius: BorderRadius.circular(12), // Radius 12
                          border: Border.all(
                              color: Colors.grey.shade300), // Border halus
                        ),
                        child: Icon(Icons.calendar_today,
                            color: provider.filterDate != null
                                ? Colors.white
                                : Colors.grey[600],
                            size: 20),
                      ),
                    ),

                    // Tombol Reset Filter (Muncul jika ada filter tanggal)
                    if (provider.filterDate != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.setFilterDate(null),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius:
                                BorderRadius.circular(12), // Radius 12
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 20),
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- LIST BOOKING ---
              Expanded(
                child: bookingList.isEmpty
                    ? Center(
                        child: Text("Data tidak ditemukan",
                            style: TextStyle(color: Colors.grey[400])))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: bookingList.length,
                        itemBuilder: (ctx, i) =>
                            _BookingCard(booking: bookingList[i]),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.ruby,
            onPressed: () {
              if (provider.isLimitReached) {
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: const Text("Limit Tercapai"),
                          content: const Text(
                              "Akun Free hanya bisa menyimpan 10 booking. Upgrade ke VIP untuk unlimited!"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Nanti")),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const UpgradeScreen()));
                              },
                              child: const Text("Upgrade Sekarang"),
                            )
                          ],
                        ));
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddBookingScreen()));
              }
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    // Teks hitam/hijau tua agar terbaca di background cerah
    final textColor =
        (color == AppColors.sunshine) ? AppColors.forest : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    String statusText = "";

    switch (booking.status) {
      case BookingStatus.scheduled:
        statusColor = AppColors.brightBlue;
        statusText = "Terjadwal";
        break;
      case BookingStatus.completed:
        statusColor = AppColors.forest;
        statusText = "Selesai";
        break;
      case BookingStatus.canceled:
        statusColor = AppColors.ruby;
        statusText = "Batal";
        break;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BookingDetailScreen(bookingId: booking.id))),
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(DateFormat("MMM").format(booking.date).toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  Text(DateFormat("dd").format(booking.date),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                      "${booking.serviceName} • ${DateFormat("HH:mm").format(booking.date)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 4),
                  if (booking.isVip)
                    Row(children: const [
                      Icon(Icons.star, size: 12, color: AppColors.sunshine),
                      SizedBox(width: 4),
                      Text("VIP Client",
                          style: TextStyle(fontSize: 10, color: Colors.orange))
                    ])
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(statusText,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
