import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../models/booking_model.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String _selectedFilter = 'Mingguan';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.dustyWhite, // <-- BACKGROUND BARU
      appBar: AppBar(
        title: const Text("Laporan Keuangan",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: AppColors.dustyWhite, // <-- BACKGROUND BARU
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILTER BUTTONS
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white, // Putih biar kontras
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ["Harian", "Mingguan", "Bulanan", "Tahunan"]
                        .map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.ruby
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // KARTU RINGKASAN
            if (_selectedFilter == "Harian")
              _buildSummaryCard("Pendapatan Hari Ini", provider.incomeDaily,
                  currencyFormatter, provider.dailyTransactions),
            if (_selectedFilter == "Mingguan")
              _buildSummaryCard("Pendapatan Mingguan", provider.incomeWeekly,
                  currencyFormatter, provider.weeklyTransactions),
            if (_selectedFilter == "Bulanan")
              _buildSummaryCard("Pendapatan Bulanan", provider.incomeMonthly,
                  currencyFormatter, provider.monthlyTransactions),
            if (_selectedFilter == "Tahunan")
              _buildSummaryCard("Pendapatan Tahunan", provider.incomeYearly,
                  currencyFormatter, provider.yearlyTransactions),

            const SizedBox(height: 30),

            // GRAFIK
            Text("Grafik $_selectedFilter",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, // Grafik di atas putih agar bersih
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16)),
              child: _buildChart(provider.getChartData(_selectedFilter)),
            ),

            const SizedBox(height: 30),

            // RIWAYAT TRANSAKSI
            const Text("Rincian Transaksi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildTransactionList(
                _selectedFilter == "Harian"
                    ? provider.dailyTransactions
                    : _selectedFilter == "Mingguan"
                        ? provider.weeklyTransactions
                        : _selectedFilter == "Bulanan"
                            ? provider.monthlyTransactions
                            : provider.yearlyTransactions,
                currencyFormatter),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, double> data) {
    if (data.isEmpty) return const Center(child: Text("Tidak ada data grafik"));
    double maxValue = 0;
    data.forEach((k, v) {
      if (v > maxValue) maxValue = v;
    });
    if (maxValue == 0) maxValue = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final barWidth = (width / data.length) * 0.6;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.entries.map((entry) {
            final heightPct = entry.value / maxValue;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message:
                      "${entry.key}: ${NumberFormat.compact().format(entry.value)}",
                  child: Container(
                    width: barWidth,
                    height: (constraints.maxHeight - 30) * heightPct,
                    decoration: BoxDecoration(
                      color:
                          entry.value > 0 ? AppColors.ruby : Colors.grey[200],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: barWidth + 10,
                  child: Text(entry.key,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, double totalIncome,
      NumberFormat formatter, List<BookingModel> transactions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ruby,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.ruby.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              const Icon(Icons.show_chart, color: Colors.white),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatter.format(totalIncome),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text("${transactions.length} Transaksi",
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTransactionList(
      List<BookingModel> transactions, NumberFormat formatter) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text("Belum ada transaksi periode ini",
                  style: TextStyle(color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }
    // Urutkan dari terbaru
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(
          height: 10), // Pakai SizedBox biar ada jarak antar kartu putih
      itemBuilder: (ctx, i) {
        final b = transactions[i];
        final isPaid = b.paymentStatus == PaymentStatus.paid;
        double realMoney = b.depositAmount;
        if (isPaid) realMoney += b.remainingBalance;

        // Container Putih di atas Background Dusty White
        return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
                backgroundColor: Colors.grey[100],
                child: Icon(Icons.person, color: Colors.grey[400], size: 20)),
            title: Text(b.clientName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(DateFormat('dd MMM yyyy • HH:mm').format(b.date),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("+${formatter.format(realMoney)}",
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(isPaid ? "Lunas" : "DP",
                    style: TextStyle(
                        fontSize: 10,
                        color: isPaid ? Colors.green : Colors.orange)),
              ],
            ),
          ),
        );
      },
    );
  }
}
