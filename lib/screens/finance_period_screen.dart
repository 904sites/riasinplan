import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../config/theme.dart';
import '../models/booking_model.dart';

class FinancePeriodScreen extends StatelessWidget {
  final String title; // Contoh: "Pendapatan Mingguan"
  final List<BookingModel> transactions; // Datanya dikirim dari luar
  final double totalIncome;

  const FinancePeriodScreen({
    super.key,
    required this.title,
    required this.transactions,
    required this.totalIncome,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    // Sortir transaksi dari terbaru
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.print_outlined, color: AppColors.dustyOrchid),
            onPressed: () => _generatePdf(context, currencyFormatter),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- HEADER TOTAL ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.dustyOrchid,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.dustyOrchid.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Text("Total Pendapatan",
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(totalIncome),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("${transactions.length} Transaksi",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- LIST TRANSAKSI ---
            transactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Text("Tidak ada data untuk periode ini.",
                        style: TextStyle(color: Colors.grey[400])),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (ctx, i) {
                      final item = transactions[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.clientName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(dateFormatter.format(item.date),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            Text(
                              currencyFormatter.format(item.depositAmount),
                              style: const TextStyle(
                                  color: AppColors.dustyOrchid,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
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

  // --- GENERATE PDF ---
  Future<void> _generatePdf(
      BuildContext context, NumberFormat formatter) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                  level: 0,
                  child: pw.Text("LAPORAN $title".toUpperCase(),
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 18))),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: <List<String>>[
                  <String>['Tanggal', 'Klien', 'Layanan', 'Nominal'],
                  ...transactions.map((item) => [
                        DateFormat('dd/MM/yy').format(item.date),
                        item.clientName,
                        item.serviceName,
                        formatter.format(item.depositAmount)
                      ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text("Total: ${formatter.format(totalIncome)}",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(), name: 'Laporan_$title');
  }
}
