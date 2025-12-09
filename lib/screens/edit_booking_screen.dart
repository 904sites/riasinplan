import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart'; // Import Model Layanan
import '../providers/booking_provider.dart';
import '../providers/service_provider.dart'; // Import Provider Layanan

class EditBookingScreen extends StatefulWidget {
  final BookingModel booking; // Data lama yang mau diedit

  const EditBookingScreen({super.key, required this.booking});

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _priceController;
  late TextEditingController _dpController;
  late TextEditingController _noteController;

  late DateTime _selectedDate;
  String? _selectedServiceName; // Bisa null jika layanan lama sudah dihapus
  late PaymentMethod _selectedPaymentMethod;
  late bool _isVip;

  @override
  void initState() {
    super.initState();
    // Isi form dengan data lama (Pre-filled)
    _nameController = TextEditingController(text: widget.booking.clientName);
    _phoneController = TextEditingController(text: widget.booking.clientPhone);
    _priceController = TextEditingController(
        text: widget.booking.totalPrice.toStringAsFixed(0));
    _dpController = TextEditingController(
        text: widget.booking.depositAmount.toStringAsFixed(0));
    _noteController = TextEditingController(text: widget.booking.notes ?? '');

    _selectedDate = widget.booking.date;
    _selectedServiceName = widget.booking.serviceName;
    _selectedPaymentMethod = widget.booking.paymentMethod;
    _isVip = widget.booking.isVip;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate));
      if (time != null) {
        setState(() {
          _selectedDate =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate() && _selectedServiceName != null) {
      final provider = Provider.of<BookingProvider>(context, listen: false);

      // Buat object baru dengan ID yang SAMA (Penting!)
      final updatedBooking = BookingModel(
        id: widget.booking.id, // ID tidak boleh berubah
        clientName: _nameController.text,
        clientPhone: _phoneController.text,
        isVip: _isVip,
        serviceName: _selectedServiceName!,
        totalPrice: double.parse(_priceController.text),
        depositAmount: double.parse(_dpController.text),
        paymentMethod: _selectedPaymentMethod,
        date: _selectedDate,
        notes: _noteController.text,
        status: widget.booking.status, // Status tetap sama
      );

      provider.editBooking(updatedBooking);
      Navigator.pop(context); // Tutup layar edit
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data berhasil diperbarui!")));
    } else if (_selectedServiceName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih Layanan terlebih dahulu!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. AMBIL DATA LAYANAN DARI PROVIDER
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final List<ServiceModel> services = serviceProvider.services;
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Validasi: Cek apakah layanan yang lama masih ada di database?
    // Jika tidak ada, kita harus membiarkan user memilih ulang atau menampilkan nama lama sementara
    bool isServiceExist = services.any((s) => s.name == _selectedServiceName);

    // Jika layanan lama tidak ada di list (mungkin sudah dihapus), kita reset null agar user pilih ulang
    // Atau bisa juga kita biarkan string lama, tapi dropdown akan error jika value tidak ada di items.
    // Solusi: Jika tidak ada, paksa user pilih lagi.
    if (!isServiceExist && services.isNotEmpty) {
      // Opsional: _selectedServiceName = null;
      // Tapi agar tidak error rendering dropdown, kita pastikan value dropdown sesuai.
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Informasi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Status VIP"),
                value: _isVip,
                activeThumbColor: Colors.amber,
                onChanged: (val) => setState(() => _isVip = val),
              ),
              const Divider(),
              TextFormField(
                  controller: _nameController,
                  decoration: _deco("Nama Klien", Icons.person)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _phoneController,
                  decoration: _deco("WhatsApp", Icons.phone),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),

              // --- DROPDOWN LAYANAN (UPDATED) ---
              DropdownButtonFormField<String>(
                // Jika layanan lama masih ada di list, pakai itu. Jika tidak, kosongkan (null)
                value: isServiceExist ? _selectedServiceName : null,
                isExpanded: true,
                decoration: _deco("Layanan", Icons.brush),
                hint: const Text("Pilih layanan..."),
                items: services
                    .map((s) => DropdownMenuItem(
                          value: s.name,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  s.name.length > 20
                                      ? "${s.name.substring(0, 20)}..."
                                      : s.name,
                                  style: const TextStyle(fontSize: 14)),
                              Text(currencyFormatter.format(s.price),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedServiceName = val!;
                    // --- AUTO UPDATE HARGA ---
                    // Saat ganti layanan di mode edit, harga otomatis berubah sesuai layanan baru
                    final selectedService =
                        services.firstWhere((s) => s.name == val);
                    _priceController.text =
                        selectedService.price.toStringAsFixed(0);
                  });
                },
              ),

              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: _deco("Jadwal", Icons.calendar_today),
                  child: Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _deco("Harga Total", Icons.monetization_on),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _dpController,
                      keyboardType: TextInputType.number,
                      decoration: _deco("Sudah Bayar (DP)", Icons.wallet),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: _deco("Catatan (Opsional)", Icons.note),
                maxLines: 2,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dustyOrchid,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveChanges,
                  child: const Text("SIMPAN PERUBAHAN"),
                ),
              )
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
