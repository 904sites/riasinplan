import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riasin/main.dart'; // Ganti 'riasin' sesuai nama project Anda di pubspec.yaml
import 'package:riasin/providers/booking_provider.dart'; // Sesuaikan import

void main() {
  testWidgets('Riasin app smoke test', (WidgetTester tester) async {
    // Build app dengan Provider karena RiasinApp butuh data booking
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => BookingProvider())],
        child: const RiasinApp(),
      ),
    );

    // Verifikasi bahwa judul Dashboard muncul
    expect(find.text('Riasin Dashboard'), findsOneWidget);

    // Verifikasi bahwa belum ada jadwal (empty state) atau list
    // Tergantung data awal di provider
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
