import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart'; // Import Model Layanan
import '../providers/booking_provider.dart';
import '../providers/service_provider.dart'; // Import Provider Layanan

class AddBookingScreen extends StatefulWidget {
  const AddBookingScreen({super.key});

  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController(); // Harga Otomatis
  final _dpController = TextEditingController(text: '0'); // DP Manual

  DateTime? _selectedDate;
  String? _selectedServiceName; // Menggunakan String agar sesuai model lama
  final PaymentMethod _selectedPaymentMethod = PaymentMethod.transfer;
  final bool _isVip = false;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedServiceName != null) {
      final provider = Provider.of<BookingProvider>(context, listen: false);

      // Cek Bentrok
      if (!provider.isSlotAvailable(_selectedDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jadwal bentrok! Pilih jam lain."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newBooking = BookingModel(
        id: const Uuid().v4(),
        clientName: _nameController.text,
        clientPhone: _phoneController.text,
        isVip: _isVip,
        serviceName: _selectedServiceName!, // Nama layanan dari dropdown
        totalPrice: double.parse(
            _priceController.text), // Harga dari controller (bisa diedit)
        depositAmount: double.parse(_dpController.text),
        paymentMethod: _selectedPaymentMethod,
        date: _selectedDate!,
      );

      provider.addBooking(newBooking);
      Navigator.pop(context);
    } else if (_selectedServiceName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Layanan terlebih dahulu!")),
      );
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tentukan Tanggal & Jam!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. AMBIL DATA LAYANAN DARI PROVIDER
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final List<ServiceModel> services = serviceProvider.services;

    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nama Klien
              TextFormField(
                controller: _nameController,
                decoration: _deco("Nama Klien", Icons.person),
                validator: (v) => v!.isEmpty ? "Wajib" : null,
              ),
              const SizedBox(height: 12),

              // WhatsApp
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _deco("WhatsApp", Icons.phone),
                validator: (v) => v!.isEmpty ? "Wajib" : null,
              ),
              const SizedBox(height: 12),

              // --- DROPDOWN LAYANAN YANG TERHUBUNG ---
              DropdownButtonFormField<String>(
                value: _selectedServiceName,
                isExpanded: true,
                decoration: _deco("Pilih Layanan", Icons.brush),
                hint: const Text("Pilih paket makeup..."),
                items: services.map((service) {
                  return DropdownMenuItem<String>(
                    value: service.name,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.name.length > 20
                              ? "${service.name.substring(0, 20)}..."
                              : service.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          currencyFormatter.format(service.price),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedServiceName = val;
                    // --- LOGIKA OTOMATIS HARGA ---
                    // Cari layanan yang dipilih
                    final selectedService =
                        services.firstWhere((s) => s.name == val);
                    // Update controller harga secara otomatis
                    _priceController.text =
                        selectedService.price.toStringAsFixed(0);
                  });
                },
                validator: (val) => val == null ? "Wajib pilih layanan" : null,
              ),

              const SizedBox(height: 12),

              // Tanggal & Jam
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: _deco("Tanggal & Jam", Icons.calendar_today),
                  child: Text(
                    _selectedDate == null
                        ? "Pilih Waktu..."
                        : DateFormat('dd MMM yyyy, HH:mm')
                            .format(_selectedDate!),
                    style: TextStyle(
                        color: _selectedDate == null
                            ? Colors.grey[600]
                            : Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Harga Total & DP
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      // Harga otomatis terisi, tapi user MASIH BISA edit manual jika mau diskon/charge
                      decoration: _deco("Harga Total", Icons.monetization_on),
                      validator: (v) => v!.isEmpty ? "Wajib" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _dpController,
                      keyboardType: TextInputType.number,
                      decoration: _deco("Nominal DP", Icons.wallet),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dustyOrchid,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submit,
                  child: const Text("SIMPAN BOOKING"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.dustyOrchid),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
