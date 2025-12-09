import 'dart:convert';

enum PaymentMethod { transfer, cash, qris }

enum PaymentStatus { unpaid, downPayment, paid }

enum BookingStatus { scheduled, completed, canceled } // Status Pengerjaan

class BookingModel {
  final String id;
  final String clientName;
  final String clientPhone;
  final bool isVip;
  final String serviceName;
  final double totalPrice;
  final double depositAmount;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String? notes;
  final BookingStatus status;

  BookingModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    this.isVip = false,
    required this.serviceName,
    required this.totalPrice,
    this.depositAmount = 0,
    required this.paymentMethod,
    required this.date,
    this.notes,
    this.status = BookingStatus.scheduled,
  });

  double get remainingBalance => totalPrice - depositAmount;

  PaymentStatus get paymentStatus {
    if (depositAmount >= totalPrice) return PaymentStatus.paid;
    if (depositAmount > 0) return PaymentStatus.downPayment;
    return PaymentStatus.unpaid;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'isVip': isVip,
      'serviceName': serviceName,
      'totalPrice': totalPrice,
      'depositAmount': depositAmount,
      'paymentMethod': paymentMethod.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'status': status.name,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      clientName: map['clientName'],
      clientPhone: map['clientPhone'],
      isVip: map['isVip'] ?? false,
      serviceName: map['serviceName'],
      totalPrice: map['totalPrice'],
      depositAmount: map['depositAmount'],
      paymentMethod: PaymentMethod.values.byName(map['paymentMethod']),
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      status: map['status'] != null
          ? BookingStatus.values.byName(map['status'])
          : BookingStatus.scheduled,
    );
  }

  String toJson() => json.encode(toMap());
  factory BookingModel.fromJson(String source) =>
      BookingModel.fromMap(json.decode(source));
}
