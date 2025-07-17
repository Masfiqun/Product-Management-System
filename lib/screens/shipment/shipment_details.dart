import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:record/models/product.dart';
import 'package:record/models/shipment.dart';
import 'package:record/services/firestore_service.dart';

class ShipmentDetailsScreen extends StatefulWidget {
  final Shipment shipment;

  const ShipmentDetailsScreen({super.key, required this.shipment});

  @override
  State<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<ShipmentDetailsScreen> {
  final _firestoreService = FirestoreService();
  final Set<String> _loadingProductIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkInProduct(Product product, Shipment shipment) async {
    if (shipment.checkedInProductIds.contains(product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product has already been checked in.')),
      );
      return;
    }

    setState(() => _loadingProductIds.add(product.id));

    try {
      await _firestoreService.checkInProduct(
        productId: product.id,
        shipmentId: shipment.id,
        totalProductCount: shipment.productIds.length,
        alreadyCheckedIn: shipment.checkedInProductIds.length,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product checked in successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking in product: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loadingProductIds.remove(product.id));
    }
  }

  void _showProductDetails(BuildContext context, Product product, bool isCheckedIn) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              _buildDetailTile('Product Name', product.name),
              _buildDetailTile('Description', product.description),
              _buildDetailTile('Quantity', product.quantity.toString()),
              _buildDetailTile(
                'Checked Out At',
                product.checkedOutAt != null
                    ? DateFormat('MMM dd, yyyy hh:mm a').format(product.checkedOutAt!)
                    : 'N/A',
              ),
              _buildDetailTile(
                'Checked In At',
                product.checkedInAt != null
                    ? DateFormat('MMM dd, yyyy hh:mm a').format(product.checkedInAt!)
                    : (isCheckedIn ? '✔ Already Checked In' : 'Not yet checked in'),
              ),
              _buildDetailTile(
                'Status',
                isCheckedIn ? 'Checked In' : 'Pending Check-in',
                valueColor: isCheckedIn ? Colors.green : Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(String title, String value, {Color? valueColor}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        value,
        style: TextStyle(color: valueColor),
      ),
    );
  }

  Widget _statusChip(bool isCheckedIn) {
    return Chip(
      label: Text(isCheckedIn ? 'Checked In' : 'Pending'),
      backgroundColor: isCheckedIn ? Colors.green[100] : Colors.orange[100],
      labelStyle: TextStyle(
        color: isCheckedIn ? Colors.green[800] : Colors.orange[800],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shipment.name, style: TextStyle(color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<Shipment>(
          stream: _firestoreService.streamShipment(widget.shipment.id),
          builder: (context, shipmentSnapshot) {
            if (!shipmentSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final updatedShipment = shipmentSnapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shipment Info',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('Created: ${DateFormat('MMM dd, yyyy').format(updatedShipment.createdAt)}'),
                        Text('Status: ${updatedShipment.isCompleted ? "Completed" : "Pending"}'),
                        Text('Checked In: ${updatedShipment.checkedInProductIds.length}/${updatedShipment.productIds.length}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),

                const SizedBox(height: 24),
                Text('Products', style: Theme.of(context).textTheme.titleLarge),

                const SizedBox(height: 12),

                StreamBuilder<List<Product>>(
                  stream: _firestoreService.streamProducts(),
                  builder: (context, productSnapshot) {
                    if (!productSnapshot.hasData) return const CircularProgressIndicator();

                    final allProducts = productSnapshot.data!;
                    final shipmentProducts = allProducts
                        .where((p) => updatedShipment.productIds.contains(p.id))
                        .where((p) => p.name.toLowerCase().contains(_searchQuery))
                        .toList()
                      ..sort((a, b) {
                        final aChecked = updatedShipment.checkedInProductIds.contains(a.id);
                        final bChecked = updatedShipment.checkedInProductIds.contains(b.id);
                        return aChecked == bChecked ? 0 : (aChecked ? 1 : -1);
                      });

                    if (shipmentProducts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No matching products found')),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: shipmentProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = shipmentProducts[index];
                        final isCheckedIn = updatedShipment.checkedInProductIds.contains(product.id);
                        final isLoading = _loadingProductIds.contains(product.id);

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            onTap: () => _showProductDetails(context, product, isCheckedIn),
                            leading: Icon(
                              isCheckedIn ? Icons.check_circle : Icons.pending,
                              color: isCheckedIn ? Colors.green : Colors.orange,
                              size: 32,
                            ),
                            title: Text(product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.description),
                                Text('Qty: ${product.quantity}'),
                                Text(
                                  'Checked Out: ${product.checkedOutAt != null ? DateFormat('MMM dd, yyyy').format(product.checkedOutAt!) : 'N/A'}',
                                ),
                              ],
                            ),
                            trailing: isCheckedIn
                                ? _statusChip(true)
                                : isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : IconButton(
                                        tooltip: 'Check In',
                                        icon: const Icon(Icons.login),
                                        onPressed: () => _checkInProduct(product, updatedShipment),
                                      ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
