import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../config/theme.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';

class FinanceDailyScreen extends StatelessWidget {
  final DateTime date; // Tanggal yang mau dilihat laporannya

  const FinanceDailyScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');

    // 1. FILTER DATA TRANSAKSI PADA TANGGAL TERSEBUT
    // (Mengambil yang statusnya tidak batal & ada uang masuk)
    final dailyTransactions = provider.bookings.where((b) {
      return b.date.year == date.year &&
          b.date.month == date.month &&
          b.date.day == date.day &&
          b.status != BookingStatus.canceled &&
          b.depositAmount > 0;
    }).toList();

    // 2. HITUNG TOTAL
    double totalIncome =
        dailyTransactions.fold(0, (sum, item) => sum + item.depositAmount);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Keuangan Harian",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif')),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // TOMBOL PRINT
          IconButton(
            icon:
                const Icon(Icons.print_outlined, color: AppColors.dustyOrchid),
            onPressed: () => _generateDailyReportPdf(
                context, dailyTransactions, date, totalIncome),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CARD HEADER (PINK GRADIENT) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.ruby, AppColors.poppyPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Text(dateFormatter.format(date),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text("Total Pemasukan",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(totalIncome),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("${dailyTransactions.length} Transaksi",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text("Detail Pemasukan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // --- LIST TRANSAKSI ---
            dailyTransactions.isEmpty
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("Tidak ada transaksi.",
                            style: TextStyle(color: Colors.grey))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dailyTransactions.length,
                    itemBuilder: (ctx, i) {
                      final item = dailyTransactions[i];
                      // Tentukan Tipe (DP atau Lunas)
                      String type = item.paymentStatus == PaymentStatus.paid
                          ? "Lunas"
                          : "DP";
                      Color typeColor = item.paymentStatus == PaymentStatus.paid
                          ? AppColors.sorbetStem
                          : const Color(0xFFEBC173);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.clientName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(type,
                                    style: TextStyle(
                                        color: typeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ],
                            ),
                            Text(item.serviceName,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('HH:mm').format(item.date),
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12)),
                                Text(
                                  currencyFormatter.format(item.depositAmount),
                                  style: const TextStyle(
                                      color: AppColors.dustyOrchid,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                                "Ref: INV-${item.id.substring(0, 8).toUpperCase()}",
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 10)),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI CETAK PDF SESUAI GAMBAR ---
  Future<void> _generateDailyReportPdf(
      BuildContext context,
      List<BookingModel> transactions,
      DateTime date,
      double totalIncome) async {
    final pdf = pw.Document();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final dateFormatter = DateFormat('d MMMM yyyy', 'id_ID');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // HEADER
                pw.Center(
                    child: pw.Text("LAPORAN KEUANGAN HARIAN",
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold))),
                pw.Center(
                    child: pw.Text(dateFormatter.format(date).toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(height: 4),
                pw.Center(
                    child: pw.Text(
                        "Dicetak pada: ${dateFormatter.format(DateTime.now())}",
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey))),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),

                // TABEL RINGKASAN
                pw.Text("Ringkasan",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Table(border: pw.TableBorder.all(), columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                }, children: [
                  pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Keterangan",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Jumlah",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ]),
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Total Pemasukan Hari Ini")),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(currencyFormatter.format(totalIncome),
                            textAlign: pw.TextAlign.right)),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Total Transaksi")),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("${transactions.length} transaksi",
                            textAlign: pw.TextAlign.right)),
                  ]),
                ]),

                pw.SizedBox(height: 20),

                // TABEL DETAIL TRANSAKSI
                pw.Text("Detail Transaksi",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 8),
                pw.Table(border: pw.TableBorder.all(), children: [
                  // Table Header
                  pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Client",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Service",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Tipe",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text("Jumlah",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10))),
                      ]),
                  // Table Rows
                  ...transactions.map((t) {
                    return pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(t.clientName,
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(t.serviceName,
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              t.paymentStatus == PaymentStatus.paid
                                  ? "Lunas"
                                  : "DP",
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              currencyFormatter.format(t.depositAmount),
                              style: const pw.TextStyle(fontSize: 10),
                              textAlign: pw.TextAlign.right)),
                    ]);
                  }).toList()
                ]),

                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                    child: pw.Text("Sistem Manajemen MUA - RiasinPlan",
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey))),
              ]);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Harian_${DateFormat('ddMMyy').format(date)}',
    );
  }
}
