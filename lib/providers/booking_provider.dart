import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  List<BookingModel> _bookings = [];
  bool _isPremiumUser = false;
  String? _vipPaymentMethod;
  DateTime? _filterDate;
  String _searchQuery = '';
  String _currentUserId = "";

  List<BookingModel> get bookings => _bookings;
  bool get isPremiumUser => _isPremiumUser;
  String? get vipPaymentMethod => _vipPaymentMethod;
  DateTime? get filterDate => _filterDate;

  // --- USER LOGIC ---
  Future<void> setUserId(String userId) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _bookings = [];
      notifyListeners();
      await loadBookings();
    }
  }

  // --- LOGIC KEUANGAN ---
  double _calculateRealIncome(List<BookingModel> list) {
    return list.fold(0.0, (sum, item) {
      if (item.status == BookingStatus.canceled) {
        return sum + 50000; // Untung 50k jika batal
      }
      double income = item.depositAmount;
      if (item.paymentStatus == PaymentStatus.paid) {
        income += item.remainingBalance;
      }
      return sum + income;
    });
  }

  List<BookingModel> get filteredBookings {
    return _bookings.where((b) {
      if (_filterDate != null) {
        final isSameDay = b.date.year == _filterDate!.year &&
            b.date.month == _filterDate!.month &&
            b.date.day == _filterDate!.day;
        if (!isSameDay) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return b.clientName.toLowerCase().contains(query) ||
            b.serviceName.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  bool get isLimitReached => !_isPremiumUser && _bookings.length >= 10;

  int get countMonth => _bookings
      .where((b) =>
          b.date.month == DateTime.now().month &&
          b.status != BookingStatus.canceled)
      .length;
  int get countUpcoming =>
      _bookings.where((b) => b.status == BookingStatus.scheduled).length;
  int get countPending => _bookings
      .where((b) =>
          b.paymentStatus != PaymentStatus.paid &&
          b.status != BookingStatus.canceled)
      .length;

  // --- INCOME & TRANSACTION GETTERS ---

  // 1. HARIAN (Fitur Baru)
  List<BookingModel> get dailyTransactions {
    final now = DateTime.now();
    return _bookings.where((b) {
      return b.date.year == now.year &&
          b.date.month == now.month &&
          b.date.day == now.day &&
          b.status != BookingStatus.canceled;
    }).toList();
  }

  double get incomeDaily => _calculateRealIncome(dailyTransactions);

  int get countToday => dailyTransactions.length;

  // 2. MINGGUAN
  List<BookingModel> get weeklyTransactions {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _bookings.where((b) {
      return b.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          b.date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  double get incomeWeekly => _calculateRealIncome(weeklyTransactions);

  // 3. BULANAN
  List<BookingModel> get monthlyTransactions => _bookings
      .where((b) =>
          b.date.month == DateTime.now().month &&
          b.date.year == DateTime.now().year)
      .toList();
  double get incomeMonthly => _calculateRealIncome(monthlyTransactions);

  // 4. TAHUNAN
  List<BookingModel> get yearlyTransactions =>
      _bookings.where((b) => b.date.year == DateTime.now().year).toList();
  double get incomeYearly => _calculateRealIncome(yearlyTransactions);

  // 5. TOTAL
  double get totalCashReceived => _calculateRealIncome(_bookings);

  // --- PAYMENT SCREEN ---
  List<BookingModel> get paidBookings =>
      _bookings.where((b) => b.paymentStatus == PaymentStatus.paid).toList();
  int get countTransactionDP =>
      _bookings.where((b) => b.depositAmount > 0).length;
  int get countTransactionPaid => paidBookings.length;
  double get totalMoneyDP =>
      _bookings.fold(0, (sum, b) => sum + b.depositAmount);
  double get totalMoneyPaid => _bookings
      .where((b) => b.paymentStatus == PaymentStatus.paid)
      .fold(0, (sum, b) => sum + b.totalPrice);

  // --- CRUD ---
  Future<void> addBooking(BookingModel booking) async {
    _bookings.add(booking);
    notifyListeners();
    _saveBookings();
  }

  Future<void> editBooking(BookingModel updatedBooking) async {
    final index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
    if (index != -1) {
      _bookings[index] = updatedBooking;
      notifyListeners();
      _saveBookings();
    }
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      var old = _bookings[index];
      _bookings[index] = BookingModel(
          id: old.id,
          clientName: old.clientName,
          clientPhone: old.clientPhone,
          isVip: old.isVip,
          serviceName: old.serviceName,
          totalPrice: old.totalPrice,
          depositAmount: old.depositAmount,
          paymentMethod: old.paymentMethod,
          date: old.date,
          notes: old.notes,
          status: status);
      notifyListeners();
      _saveBookings();
    }
  }

  Future<void> updatePayment(String id, double paidAmount) async {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      var old = _bookings[index];
      _bookings[index] = BookingModel(
          id: old.id,
          clientName: old.clientName,
          clientPhone: old.clientPhone,
          isVip: old.isVip,
          serviceName: old.serviceName,
          totalPrice: old.totalPrice,
          depositAmount: paidAmount,
          paymentMethod: old.paymentMethod,
          date: old.date,
          notes: old.notes,
          status: old.status);
      notifyListeners();
      _saveBookings();
    }
  }

  Future<void> deleteBooking(String id) async {
    _bookings.removeWhere((b) => b.id == id);
    notifyListeners();
    _saveBookings();
  }

  // --- HELPERS ---
  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool isSlotAvailable(DateTime date) {
    for (var b in _bookings) {
      if (b.status == BookingStatus.canceled) continue;
      if (b.date.difference(date).inHours.abs() < 2) return false;
    }
    return true;
  }

  // --- CHART DATA GENERATOR (Update: Tambah Harian) ---
  Map<String, double> getChartData(String filterType) {
    Map<String, double> data = {};
    final now = DateTime.now();

    if (filterType == "Harian") {
      // Grafik Harian: Breakdown Waktu
      data["Pagi"] = 0; // < 11
      data["Siang"] = 0; // < 15
      data["Sore"] = 0; // < 18
      data["Malam"] = 0; // > 18

      for (var b in dailyTransactions) {
        double money = b.depositAmount;
        if (b.paymentStatus == PaymentStatus.paid) money += b.remainingBalance;

        int hour = b.date.hour;
        if (hour < 11)
          data["Pagi"] = (data["Pagi"] ?? 0) + money;
        else if (hour < 15)
          data["Siang"] = (data["Siang"] ?? 0) + money;
        else if (hour < 18)
          data["Sore"] = (data["Sore"] ?? 0) + money;
        else
          data["Malam"] = (data["Malam"] ?? 0) + money;
      }
    } else if (filterType == "Mingguan") {
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        String label = DateFormat('E', 'id_ID').format(day);
        data[label] = _calculateRealIncome(_bookings
            .where((b) =>
                b.date.year == day.year &&
                b.date.month == day.month &&
                b.date.day == day.day)
            .toList());
      }
    } else if (filterType == "Bulanan") {
      for (int i = 1; i <= 4; i++) data["Minggu $i"] = 0;
    } else {
      for (int i = 1; i <= 12; i++) {
        String label = DateFormat('MMM', 'id_ID').format(DateTime(now.year, i));
        data[label] = _calculateRealIncome(_bookings
            .where((b) => b.date.year == now.year && b.date.month == i)
            .toList());
      }
    }
    return data;
  }

  // --- VIP & SAVE LOAD ---
  void subscribeToVip(String p) {
    _isPremiumUser = true;
    _vipPaymentMethod = p;
    notifyListeners();
    _saveSubscription();
  }

  void cancelSubscription() {
    _isPremiumUser = false;
    _vipPaymentMethod = null;
    notifyListeners();
    _saveSubscription();
  }

  Future<void> loadBookings() async {
    if (_currentUserId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('bookings_$_currentUserId');
    if (data != null) {
      _bookings = (json.decode(data) as List)
          .map((e) => BookingModel.fromMap(e))
          .toList();
    } else {
      _bookings = [];
    }
    _isPremiumUser = prefs.getBool('vip_$_currentUserId') ?? false;
    _vipPaymentMethod = prefs.getString('vip_${_currentUserId}_method');
    notifyListeners();
  }

  Future<void> _saveBookings() async {
    if (_currentUserId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookings_$_currentUserId',
        json.encode(_bookings.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveSubscription() async {
    if (_currentUserId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vip_$_currentUserId', _isPremiumUser);
    if (_vipPaymentMethod != null)
      await prefs.setString('vip_${_currentUserId}_method', _vipPaymentMethod!);
  }
}
