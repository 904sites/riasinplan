import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onDelete;

  const BookingCard({super.key, required this.booking, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Tentukan Warna Status
    Color statusColor;
    String statusText;
    switch (booking.paymentStatus) {
      case PaymentStatus.paid:
        statusColor = AppColors.sorbetStem;
        statusText = "LUNAS";
        break;
      case PaymentStatus.downPayment:
        statusColor = Colors.orange.shade300;
        statusText = "DP OK";
        break;
      default:
        statusColor = Colors.red.shade200;
        statusText = "UNPAID";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Jika VIP, border berwarna emas
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: booking.isVip
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Tanggal (Kiri)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.powderedLilac,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('d').format(booking.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.dustyOrchid,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(booking.date),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Informasi Tengah
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        booking.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (booking.isVip) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    booking.serviceName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(booking.totalPrice),
                    style: const TextStyle(
                      color: AppColors.dustyOrchid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (booking.remainingBalance > 0)
                    Text(
                      "Sisa: ${currencyFormatter.format(booking.remainingBalance)}",
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                ],
              ),
            ),

            // Status Kanan
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.paymentMethod.name.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
