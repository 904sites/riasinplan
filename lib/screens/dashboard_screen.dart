import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../models/booking_model.dart';

import 'upgrade_screen.dart';
import 'service_list_screen.dart';
import 'booking_detail_screen.dart';
import 'booking_list_screen.dart';
import 'invoice_list_screen.dart';
import 'payment_screen.dart';
import 'finance_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceVisible = true;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final serviceProvider =
          Provider.of<ServiceProvider>(context, listen: false);

      if (auth.currentUser != null) {
        final email = auth.currentUser!.email;
        bookingProvider.setUserId(email);
        serviceProvider.setUserId(email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(context),
      const BookingListScreen(),
      const FinanceScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_bottomNavIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        selectedItemColor: AppColors.ruby, // Tema Cherry
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: "Booking"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: "Keuangan"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // --- WARNA TEMA CHERRY ---
    const Color pinkAccent = AppColors.poppyPink;
    const Color pinkBg = AppColors.ruby;
    const Color brownAccent = AppColors.forest;

    return Scaffold(
      backgroundColor: AppColors.dustyWhite,
      appBar: AppBar(
        backgroundColor: AppColors.dustyWhite,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_getGreeting()}, ${user?.name ?? 'MUA'}",
              style: const TextStyle(
                  color: AppColors.forest,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              user?.businessName ?? "Riasin MUA",
              style: const TextStyle(
                  color: AppColors.ruby,
                  fontSize: 22,
                  fontFamily: 'Serif',
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UpgradeScreen())),
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        provider.isPremiumUser ? "VIP" : "UPGRADE",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!provider.isPremiumUser) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.white, size: 12)
                    ]
                  ],
                ),
                backgroundColor:
                    provider.isPremiumUser ? AppColors.forest : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialCard(provider, pinkAccent, brownAccent),
              const SizedBox(height: 24),
              _buildTodayBooking(context, provider, pinkAccent),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: pinkBg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daftar Menu",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.75,
                      children: [
                        _buildMenuIcon(
                            "Layanan",
                            Icons.brush,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ServiceListScreen()))),
                        _buildMenuIcon("Booking", Icons.calendar_month,
                            () => setState(() => _bottomNavIndex = 1)),
                        _buildMenuIcon("Payment", Icons.payments_outlined, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PaymentScreen()));
                        }),
                        _buildMenuIcon(
                            "Keuangan", Icons.account_balance_wallet_outlined,
                            () {
                          setState(() => _bottomNavIndex = 2);
                        }),
                        _buildMenuIcon("Invoice", Icons.receipt_long, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const InvoiceListScreen()));
                        }),
                        _buildMenuIcon("Laporan", Icons.analytics_outlined, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReportScreen()));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
      BookingProvider provider, Color color1, Color color2) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    double incomeTotal = provider.totalCashReceived;
    double incomeToday = provider.countToday > 0 ? provider.incomeDaily : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ringkasan Keuangan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(
                    _isBalanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                    size: 20),
                onPressed: () =>
                    setState(() => _isBalanceVisible = !_isBalanceVisible),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildMoneyBox(
                      "Hari Ini", incomeToday, color1, formatter)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMoneyBox(
                      "Total Masuk", incomeTotal, color2, formatter)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMoneyBox(
      String label, double value, Color color, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wallet, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
                _isBalanceVisible ? formatter.format(value) : "Rp *****",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBooking(
      BuildContext context, BookingProvider provider, Color accentColor) {
    final now = DateTime.now();
    var bookingsToday = provider.bookings
        .where((b) =>
            b.date.year == now.year &&
            b.date.month == now.month &&
            b.date.day == now.day &&
            b.status != BookingStatus.canceled)
        .toList();
    bookingsToday.sort((a, b) => a.date.compareTo(b.date));

    if (bookingsToday.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          children: [
            Icon(Icons.event_available, color: Colors.grey[300], size: 40),
            const SizedBox(height: 8),
            Text("Tidak ada jadwal hari ini",
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    final booking = bookingsToday.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text("Booking hari ini",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(bookingId: booking.id))),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                            "${booking.serviceName} - ${booking.clientName}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))),
                    if (booking.isVip)
                      const Icon(Icons.star,
                          color: AppColors.sunshine, size: 16)
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat('HH:mm').format(booking.date),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                if (booking.status == BookingStatus.scheduled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.updateBookingStatus(
                            booking.id, BookingStatus.completed);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Jadwal Ditandai Selesai!")));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("Tandai Selesai"),
                    ),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuIcon(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.ruby, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }
}
