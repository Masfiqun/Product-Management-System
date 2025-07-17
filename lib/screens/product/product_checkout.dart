import 'package:flutter/material.dart';
import 'package:record/models/product.dart';
import 'package:record/models/product_input_controller.dart';
import 'package:record/models/shipment.dart';
import 'package:record/services/firestore_service.dart';

class ProductCheckoutScreen extends StatefulWidget {
  const ProductCheckoutScreen({super.key});

  @override
  State<ProductCheckoutScreen> createState() => _ProductCheckoutScreenState();
}

class _ProductCheckoutScreenState extends State<ProductCheckoutScreen> {
  final _firestoreService = FirestoreService();
  final _shipmentNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<ProductInputControllers> _products = [];

  @override
  void dispose() {
    _shipmentNameController.dispose();
    for (var product in _products) {
      product.dispose();
    }
    super.dispose();
  }

  void _addNewProduct() {
    setState(() => _products.add(ProductInputControllers()));
  }

  void _removeProduct(int index) {
    setState(() {
      _products[index].dispose();
      _products.removeAt(index);
    });
  }

  Future<void> _createShipment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final List<String> productIds = [];

      for (var controllers in _products) {
        final product = Product(
          id: '',
          name: controllers.nameController.text.trim(),
          description: controllers.descriptionController.text.trim(),
          quantity: int.parse(controllers.quantityController.text.trim()),
          checkedOutAt: now,
        );
        final productId = await _firestoreService.addProduct(product);
        productIds.add(productId);
      }

      final shipment = Shipment(
        id: '',
        name: _shipmentNameController.text.trim(),
        createdAt: now,
        productIds: productIds,
        checkedInProductIds: [],
      );

      await _firestoreService.createShipment(shipment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipment created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating shipment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Check-Out', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextFormField(
                            controller: _shipmentNameController,
                            decoration: const InputDecoration(
                              labelText: 'Shipment Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_shipping_outlined),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'Please enter a shipment name' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Products',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.indigo.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addNewProduct,
                            icon: const Icon(Icons.add, color: Colors.white,),
                            label: const Text('Add Product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _products.isEmpty
                            ? const Center(child: Text('No products added yet'))
                            : ListView.separated(
                                itemCount: _products.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final product = _products[index];
                                  return Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Product ${index + 1}',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline),
                                                onPressed: () => _removeProduct(index),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: product.nameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Product Name',
                                              prefixIcon: Icon(Icons.label_outline),
                                            ),
                                            validator: (value) =>
                                                (value == null || value.trim().isEmpty) ? 'Enter product name' : null,
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: product.descriptionController,
                                            decoration: const InputDecoration(
                                              labelText: 'Description',
                                              prefixIcon: Icon(Icons.description_outlined),
                                            ),
                                            validator: (value) => (value == null || value.trim().isEmpty)
                                                ? 'Enter description'
                                                : null,
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: product.quantityController,
                                            decoration: const InputDecoration(
                                              labelText: 'Quantity',
                                              prefixIcon: Icon(Icons.confirmation_number_outlined),
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'Enter quantity';
                                              }
                                              final number = int.tryParse(value.trim());
                                              if (number == null || number <= 0) {
                                                return 'Enter valid quantity';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading || _products.isEmpty ? null : _createShipment,
                          icon: const Icon(Icons.local_shipping),
                          label: const Text('Create Shipment', style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
