import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class PdfHelper {
  // Tambahkan parameter businessName
  static Future<void> printInvoice(
      BookingModel booking, String businessName) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                    level: 0,
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("INVOICE",
                              style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold)),
                          // GUNAKAN VARIABLE BUSINESS NAME DI SINI
                          pw.Text(businessName,
                              style: const pw.TextStyle(fontSize: 18)),
                        ])),
                pw.SizedBox(height: 20),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Kepada Yth:"),
                            pw.Text(booking.clientName,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(booking.clientPhone),
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                                "No: INV-${booking.id.substring(0, 6).toUpperCase()}"),
                            pw.Text(
                                "Tanggal: ${DateFormat('dd MMM yyyy').format(booking.date)}"),
                            pw.Text(
                                "Status: ${booking.paymentStatus == PaymentStatus.paid ? 'LUNAS' : 'BELUM LUNAS'}",
                                style: pw.TextStyle(
                                    color: booking.paymentStatus ==
                                            PaymentStatus.paid
                                        ? PdfColors.green
                                        : PdfColors.red)),
                          ])
                    ]),
                pw.SizedBox(height: 30),
                pw.Table.fromTextArray(
                    context: context,
                    border: null,
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    cellHeight: 30,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerRight,
                    },
                    headers: [
                      'Deskripsi Layanan',
                      'Harga'
                    ],
                    data: [
                      [
                        booking.serviceName,
                        formatter.format(booking.totalPrice)
                      ],
                    ]),
                pw.Divider(),
                pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                              "Total: ${formatter.format(booking.totalPrice)}",
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              "Deposit: - ${formatter.format(booking.depositAmount)}"),
                          pw.SizedBox(height: 5),
                          pw.Text(
                              "Sisa Tagihan: ${formatter.format(booking.remainingBalance)}",
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red)),
                        ])),
                pw.Spacer(),
                pw.Center(
                    child: pw.Text("Terima kasih telah menggunakan jasa kami."))
              ]);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
