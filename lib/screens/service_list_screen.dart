import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/service_model.dart';
import '../providers/service_provider.dart';
import 'add_service_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    if (mounted) {
      try {
        Provider.of<ServiceProvider>(context, listen: false).setSearchQuery('');
      } catch (e) {
        // Abaikan
      }
    }
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, ServiceModel service) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Hapus Layanan?"),
              content: Text("Layanan '${service.name}' akan dihapus permanen."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Batal")),
                TextButton(
                  onPressed: () {
                    Provider.of<ServiceProvider>(context, listen: false)
                        .deleteService(service.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Layanan berhasil dihapus")));
                  },
                  child:
                      const Text("Hapus", style: TextStyle(color: Colors.red)),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dustyWhite,
      appBar: AppBar(
        title: const Text("Layanan",
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        backgroundColor: AppColors.dustyWhite,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, provider, child) {
          final services = provider.filteredServices;

          return Column(
            children: [
              // SEARCH BAR (STYLE BARU - MIRIP PAYMENT)
              Padding(
                padding: const EdgeInsets.all(16), // Padding disamakan 16
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => provider.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: "Cari layanan...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 20, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            })
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    // Border Style: Radius 12 (Sama kayak Payment & Invoice)
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.ruby)),
                  ),
                ),
              ),

              // LIST DATA
              Expanded(
                child: services.isEmpty
                    ? Center(
                        child: Text("Belum ada layanan",
                            style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        itemCount: services.length,
                        itemBuilder: (ctx, i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ServiceCard(
                                service: services[i],
                                onDelete: () =>
                                    _confirmDelete(context, services[i]),
                                onEdit: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => AddServiceScreen(
                                              serviceToEdit: services[i])));
                                }),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.ruby,
        elevation: 6,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddServiceScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// --- WIDGET CARD LAYANAN ---
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ServiceCard(
      {required this.service, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Serif')),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text("${service.duration} menit",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(formatter.format(service.price),
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            if (service.addOns.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Add-on",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: service.addOns
                    .map((item) => _buildPill(item.name, item.price))
                    .toList(),
              )
            ],
            if (service.attires.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Attire",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: service.attires
                    .map((item) => _buildPill(item.name, item.price))
                    .toList(),
              )
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC5A866),
                    side: const BorderSide(color: Color(0xFFC5A866), width: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text("Edit", style: TextStyle(fontSize: 12)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String name, double price) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sunshine.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sunshine),
      ),
      child: RichText(
          text: TextSpan(
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.forest,
                  fontWeight: FontWeight.bold),
              children: [
            TextSpan(text: "$name "),
            TextSpan(
                text: "+ ${formatter.format(price)}",
                style: const TextStyle(color: AppColors.ruby, fontSize: 10)),
          ])),
    );
  }
}
