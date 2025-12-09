import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now(); // Default bulan ini

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    // 1. Filter Data Berdasarkan Bulan & Tahun yang dipilih
    final monthBookings = provider.bookings.where((b) {
      return b.date.year == _selectedDate.year &&
          b.date.month == _selectedDate.month &&
          b.status ==
              BookingStatus.completed; // Hanya yang selesai yg jadi duit
    }).toList();

    // 2. Hitung Ringkasan
    double totalRevenue =
        monthBookings.fold(0, (sum, item) => sum + item.totalPrice);
    int completedCount = monthBookings.length;
    int canceledCount = provider.bookings
        .where((b) =>
            b.date.year == _selectedDate.year &&
            b.date.month == _selectedDate.month &&
            b.status == BookingStatus.canceled)
        .length;

    // 3. Siapkan Data untuk Grafik (Income per Hari)
    Map<int, double> dailyIncome = {};
    int daysInMonth =
        DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    for (int i = 1; i <= daysInMonth; i++) {
      dailyIncome[i] = 0;
    }
    for (var b in monthBookings) {
      dailyIncome[b.date.day] = (dailyIncome[b.date.day] ?? 0) + b.totalPrice;
    }

    return Scaffold(
      backgroundColor: AppColors.dustyWhite,
      appBar: AppBar(
        title: const Text("Laporan Bulanan",
            style: TextStyle(color: Colors.black)),
        backgroundColor: AppColors.dustyWhite,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: PILIH BULAN ---
            _buildMonthSelector(),
            const SizedBox(height: 20),

            // --- BAGIAN 2: CARD RINGKASAN ---
            Row(
              children: [
                _buildSummaryCard("Pendapatan", totalRevenue, Colors.green,
                    isMoney: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      _buildMiniCard(
                          "Selesai", completedCount.toString(), Colors.blue),
                      const SizedBox(height: 10),
                      _buildMiniCard(
                          "Batal", canceledCount.toString(), Colors.red),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 30),

            // --- BAGIAN 3: GRAFIK MANUAL ---
            const Text("Grafik Pendapatan Harian",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSimpleBarChart(dailyIncome, daysInMonth),

            const SizedBox(height: 30),

            // --- BAGIAN 4: RIWAYAT TRANSAKSI ---
            const Text("Riwayat Transaksi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            monthBookings.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                        child: Text("Belum ada data di bulan ini",
                            style: TextStyle(color: Colors.grey[400]))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthBookings.length,
                    itemBuilder: (ctx, i) {
                      final booking = monthBookings[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking.clientName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    DateFormat("dd MMM yyyy")
                                        .format(booking.date),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                            Text(
                                NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: 'Rp ',
                                        decimalDigits: 0)
                                    .format(booking.totalPrice),
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold))
                          ],
                        ),
                      );
                    },
                  )
          ],
        ),
      ),
    );
  }

  // WIDGET: Pilih Bulan
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.dustyOrchid.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.dustyOrchid),
            onPressed: () {
              setState(() {
                _selectedDate =
                    DateTime(_selectedDate.year, _selectedDate.month - 1);
              });
            },
          ),
          Text(
            DateFormat("MMMMM yyyy", "id_ID").format(_selectedDate),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.dustyOrchid),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.dustyOrchid),
            onPressed: () {
              if (_selectedDate.month < DateTime.now().month ||
                  _selectedDate.year < DateTime.now().year) {
                setState(() {
                  _selectedDate =
                      DateTime(_selectedDate.year, _selectedDate.month + 1);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // WIDGET: Kotak Summary Besar
  Widget _buildSummaryCard(String title, dynamic value, Color color,
      {bool isMoney = false}) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return Expanded(
      flex: 3,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.wallet, color: color, size: 20),
            ),
            const Spacer(),
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                isMoney ? formatter.format(value) : value.toString(),
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            )
          ],
        ),
      ),
    );
  }

  // WIDGET: Kotak Summary Kecil (SUDAH DIPERBAIKI AGAR TIDAK OVERFLOW)
  Widget _buildMiniCard(String title, String value, Color color) {
    return Container(
      height: 65,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            title == "Selesai" ? Icons.check_circle : Icons.cancel,
            color: color.withOpacity(0.5),
            size: 20,
          )
        ],
      ),
    );
  }

  // WIDGET: Grafik Manual
  Widget _buildSimpleBarChart(Map<int, double> data, int daysInMonth) {
    double maxVal = 0;
    data.forEach((k, v) {
      if (v > maxVal) maxVal = v;
    });
    if (maxVal == 0) maxVal = 1;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(daysInMonth, (index) {
          int day = index + 1;
          double value = data[day] ?? 0;
          double heightPct = value / maxVal;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 150 * heightPct,
                decoration: BoxDecoration(
                    color: value > 0 ? AppColors.dustyOrchid : Colors.grey[200],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4))),
              ),
              const SizedBox(height: 4),
              if (day % 5 == 0 || day == 1)
                Text(day.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey))
              else
                const SizedBox(height: 12)
            ],
          );
        }),
      ),
    );
  }
}
