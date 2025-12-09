import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/service_model.dart';
import '../providers/service_provider.dart';

class AddServiceScreen extends StatefulWidget {
  final ServiceModel? serviceToEdit;

  const AddServiceScreen({super.key, this.serviceToEdit});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(text: "60");
  final _formKey = GlobalKey<FormState>();

  List<ServiceExtra> _tempAddOns = [];
  List<ServiceExtra> _tempAttires = [];

  @override
  void initState() {
    super.initState();
    if (widget.serviceToEdit != null) {
      _nameController.text = widget.serviceToEdit!.name;
      _priceController.text = widget.serviceToEdit!.price.toStringAsFixed(0);
      _durationController.text = widget.serviceToEdit!.duration.toString();
      _tempAddOns = List.from(widget.serviceToEdit!.addOns);
      _tempAttires = List.from(widget.serviceToEdit!.attires);
    }
  }

  void _showAddItemDialog({required bool isAttire}) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAttire ? "Tambah Attire (Busana)" : "Tambah Add-on"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Nama Item",
                hintText: isAttire ? "Cth: Kebaya" : "Cth: Bulu Mata",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Harga Tambahan (Rp)",
                hintText: "Cth: 15000",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dustyOrchid),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final newItem = ServiceExtra(
                  name: nameCtrl.text,
                  price: double.tryParse(priceCtrl.text) ?? 0,
                );
                setState(() {
                  if (isAttire) {
                    _tempAttires.add(newItem);
                  } else {
                    _tempAddOns.add(newItem);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Tambah", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _saveService() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ServiceProvider>(context, listen: false);

      final String name = _nameController.text;
      final double price =
          double.parse(_priceController.text.replaceAll('.', ''));
      final int duration = int.parse(_durationController.text);

      if (widget.serviceToEdit != null) {
        final updatedService = ServiceModel(
          id: widget.serviceToEdit!.id,
          name: name,
          price: price,
          duration: duration,
          addOns: _tempAddOns,
          attires: _tempAttires,
        );
        provider.updateService(updatedService);
      } else {
        final newService = ServiceModel(
          id: const Uuid().v4(),
          name: name,
          price: price,
          duration: duration,
          addOns: _tempAddOns,
          attires: _tempAttires,
        );
        provider.addService(newService);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.serviceToEdit != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEdit ? "Edit Layanan" : "Tambah Layanan",
            style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecor("Nama Layanan", Icons.brush),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecor("Harga (Rp)", Icons.attach_money),
                      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecor("Durasi (Menit)", Icons.timer),
                      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),

              // --- ADD-ON ---
              _buildSectionHeader(
                  "Add-on",
                  "Item tambahan (bulu mata, hairdo, dll)",
                  () => _showAddItemDialog(isAttire: false)),
              _buildItemList(_tempAddOns, false),

              const SizedBox(height: 20),

              // --- ATTIRE ---
              _buildSectionHeader("Attire", "Sewa busana (kebaya, jarik, dll)",
                  () => _showAddItemDialog(isAttire: true)),
              _buildItemList(_tempAttires, true),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dustyOrchid,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveService,
                  child: const Text("SIMPAN LAYANAN"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, String subtitle, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: const Text("Tambah"),
          style: TextButton.styleFrom(foregroundColor: AppColors.dustyOrchid),
        )
      ],
    );
  }

  Widget _buildItemList(List<ServiceExtra> list, bool isAttire) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200)),
        child: const Text("- Tidak ada item -",
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center),
      );
    }
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Column(
      children: list.asMap().entries.map((entry) {
        int idx = entry.key;
        ServiceExtra item = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("+ ${formatter.format(item.price)}",
                      style:
                          const TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  setState(() {
                    if (isAttire) {
                      _tempAttires.removeAt(idx);
                    } else {
                      _tempAddOns.removeAt(idx);
                    }
                  });
                },
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
